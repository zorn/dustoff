defmodule Dustoff.Accounts.User do
  @moduledoc """
  An entity representing a registered user account.

  ## Fields

  * `:id` - The identity of this entity, a UUID value.
  * `:email` - The current email address the user wants to be recognized by.
  * `:hashed_password` - The hashed password of the user account.
  * `:confirmed_at` - The date and time the email address was confirmed.
    Currently we do not force users to confirm their email address, but this
    field remains in place as we are likely to add this feature in the future.
  * `:authenticated_at` - The date and time the user account was last
    authenticated. This value is `virtual` and the source of truth is the
    `Dustoff.Accounts.UserToken` entity. The value is attached to the user
    struct value to make some code flows more performant.
  * `:inserted_at` - The date and time the user entity was created.
  * `:updated_at` - The date and time the user entity was last updated.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @typedoc """
  A repo-sourced `Dustoff.Accounts.User` entity.
  """
  @type t() :: %__MODULE__{
          id: id(),
          email: String.t(),
          hashed_password: String.t(),
          confirmed_at: DateTime.t() | nil,
          authenticated_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @typedoc """
  An `Ecto.Changeset` for a repo-sourced `Dustoff.Accounts.User` entity.
  """
  @type changeset() :: Ecto.Changeset.t(t())

  @typedoc """
  The identity value type of a `Dustoff.Accounts.User` entity.
  """
  @type id() :: Ecto.UUID.t()

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  A user changeset for registering a new account using the provided email and password.

  ## Options

    * `:validate_email` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
      * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec registration_changeset(attrs :: map(), opts :: Keyword.t()) :: changeset()
  def registration_changeset(attrs, opts \\ []) do
    %__MODULE__{}
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_email(opts)
    # Q: Why not do the confirmation in the `validate_password` function?
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  A user changeset changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_email` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  @spec email_changeset(user :: t(), attrs :: map(), opts :: Keyword.t()) :: changeset()
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Dustoff.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec password_changeset(user :: t(), attrs :: map(), opts :: Keyword.t()) :: changeset()
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  @spec confirm_changeset(user :: t()) :: changeset()
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  @spec valid_password?(user :: t(), password :: String.t()) :: boolean()
  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end
end
