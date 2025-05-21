defmodule Dustoff.Accounts do
  @moduledoc """
  Provides functions for managing user accounts, authentication and sessions.
  """

  alias Dustoff.Accounts.User
  alias Dustoff.Accounts.UserNotifier
  alias Dustoff.Accounts.UserToken
  alias Dustoff.Repo

  @doc """
  Gets a `Dustoff.Accounts.User` entity by email.
  """
  @spec get_user_by_email(email :: String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a `Dustoff.Accounts.User` entity by email and password.
  """
  @spec get_user_by_email_and_password(
          email :: String.t(),
          password :: String.t()
        ) :: User.t() | nil
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single `Dustoff.Accounts.User` entity.

  Raises `Ecto.NoResultsError` if the User does not exist.
  """
  @spec get_user!(User.id()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.
  """
  @spec register_user(attrs :: map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register_user(attrs) do
    attrs
    |> User.registration_changeset()
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Returns `true` when the user is considered recently authenticated.

  Recently is defined by default as the last authentication was done no further
  than 20 minutes ago.

  The time limit in minutes can be given as second argument in minutes.
  """
  @spec recently_authenticated?(User.t(), minutes :: integer()) :: boolean()
  def recently_authenticated?(user, minutes \\ -20)

  def recently_authenticated?(%User{authenticated_at: authenticated_at}, minutes)
      when is_struct(authenticated_at, DateTime) do
    minutes_from_now = DateTime.utc_now() |> DateTime.add(minutes, :minute)
    DateTime.after?(authenticated_at, minutes_from_now)
  end

  def recently_authenticated?(_user, _minutes) do
    # If the previous pattern match failed, it was likely due to the user not
    # having an `authenticated_at` field value, as in they have never authenticated.
    false
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for registering a new account.

  See `Dustoff.Accounts.User.registration_changeset/2` for a list of supported options.
  """
  @spec registration_changeset(attrs :: map(), opts :: keyword()) :: Ecto.Changeset.t()
  def registration_changeset(attrs \\ %{}, opts \\ []) when is_map(attrs) and is_list(opts) do
    User.registration_changeset(attrs, opts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Dustoff.Accounts.User.email_changeset/3` for a list of supported options.
  """
  @spec change_user_email(
          user :: User.t(),
          attrs :: map(),
          opts :: keyword()
        ) :: User.changeset()
  def change_user_email(user, attrs \\ %{}, opts \\ [])
      when is_struct(user, User) and is_map(attrs) and is_list(opts) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  @spec update_user_email(User.t(), token :: String.t()) :: :ok | :error
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  @spec user_email_multi(
          user :: User.t(),
          email :: String.t(),
          context :: String.t()
        ) :: Ecto.Multi.t()
  defp user_email_multi(user, email, context) do
    changeset = User.email_changeset(user, %{email: email})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Dustoff.Accounts.User.password_changeset/3` for a list of supported options.
  """
  @spec change_user_password(
          user :: User.t(),
          attrs :: map(),
          opts :: keyword()
        ) :: User.changeset()
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns the updated user, as well as a list of expired tokens.
  """
  @spec update_user_password(user :: User.t(), attrs :: map()) ::
          {:ok, User.t(), [UserToken.t()]} | {:error, User.changeset()}
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
    |> case do
      {:ok, user, expired_tokens} -> {:ok, user, expired_tokens}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Generates and persists a session token.
  """
  @spec generate_user_session_token(user :: User.t()) :: token :: String.t()
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets a `Dustoff.Accounts.User` entity with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  @spec get_user_by_session_token(token :: String.t()) ::
          {User.t(), token_inserted_at :: DateTime.t()} | nil
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Delivers the update email instructions to the given user.
  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    %{data: %User{} = user} = changeset

    with {:ok, %{user: user, tokens_to_expire: expired_tokens}} <-
           Ecto.Multi.new()
           |> Ecto.Multi.update(:user, changeset)
           |> Ecto.Multi.all(:tokens_to_expire, UserToken.by_user_and_contexts_query(user, :all))
           |> Ecto.Multi.delete_all(:tokens, fn %{tokens_to_expire: tokens_to_expire} ->
             UserToken.delete_all_query(tokens_to_expire)
           end)
           |> Repo.transaction() do
      {:ok, user, expired_tokens}
    end
  end
end
