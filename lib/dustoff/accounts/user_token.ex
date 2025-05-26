defmodule Dustoff.Accounts.UserToken do
  @moduledoc """
  A entity that stores a token identity related to an account action to be acted
  upon later, usually via an emailed link.
  """

  use Ecto.Schema

  import Ecto.Query

  alias Dustoff.Accounts.User
  alias Dustoff.Accounts.UserToken

  @typedoc """
  A type describing a repo-sourced `Dustoff.Accounts.UserToken` entity.
  """
  @type t() :: %__MODULE__{
          token: String.t(),
          context: String.t(),
          sent_to: String.t() | nil,
          authenticated_at: DateTime.t() | nil,
          user_id: Dustoff.Accounts.User.id(),
          inserted_at: DateTime.t()
        }

  @typedoc """
  A type describing a simple struct value of `Dustoff.Accounts.UserToken`.

  This type is sometimes needed when want to compose a function typespec that
  will return a non-repo sourced struct value.
  """
  @type struct_t() :: %__MODULE__{}

  @type id() :: Ecto.UUID.t()

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the magic link token expiry short,
  # since someone with access to the email may take over the account.
  @magic_link_validity_in_minutes 15
  @change_email_validity_in_days 7
  @session_validity_in_days 14

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    field :authenticated_at, :utc_datetime
    belongs_to :user, Dustoff.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual user
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  # Because we are mearly creating the struct value, the return type here is not a `t()` but instead a struct.
  @spec build_session_token(user :: User.t()) :: {token :: String.t(), user_token :: struct_t()}
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    dt = user.authenticated_at || DateTime.utc_now(:second)
    {token, %UserToken{token: token, context: "session", user_id: user.id, authenticated_at: dt}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any, along with the token's
  creation time.

  The token is valid if it matches the value in the database and it has not
  expired (after @session_validity_in_days).
  """
  @spec verify_session_token_query(token :: String.t()) :: {:ok, Ecto.Query.t()}
  def verify_session_token_query(token) do
    query =
      from token in by_token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: {%{user | authenticated_at: token.authenticated_at}, token.inserted_at}

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be delivered to the user's email.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  Users can easily adapt the existing code to provide other types of delivery methods,
  for example, by phone numbers.
  """
  @spec build_email_token(user :: User.t(), context :: String.t()) ::
          {token :: String.t(), user_token :: struct_t()}
  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
  end

  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %UserToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  If found, the query returns a tuple of the form `{user, token}`.

  The given token is valid if it matches its hashed counterpart in the
  database. This function also checks if the token is being used within
  15 minutes. The context of a magic link token is always "login".
  """
  @spec verify_magic_link_token_query(token :: String.t()) :: {:ok, Ecto.Query.t()}
  def verify_magic_link_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in by_token_and_context_query(hashed_token, "login"),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^@magic_link_validity_in_minutes, "minute"),
            where: token.sent_to == user.email,
            select: {user, token}

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user_token found by the token, if any.

  This is used to validate requests to change the user
  email.
  The given token is valid if it matches its hashed counterpart in the
  database and if it has not expired (after @change_email_validity_in_days).
  The context must always start with "change:".
  """
  @spec verify_change_email_token_query(token :: String.t(), context :: String.t()) ::
          {:ok, Ecto.Query.t()} | :error
  def verify_change_email_token_query(token, "change:" <> _ = context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in by_token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity_in_days, "day")

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  @spec by_token_and_context_query(token :: String.t(), context :: String.t()) :: Ecto.Query.t()
  def by_token_and_context_query(token, context) do
    from UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  @spec by_user_and_contexts_query(user :: User.t(), :all | [String.t()]) :: Ecto.Query.t()
  def by_user_and_contexts_query(user, :all) do
    from t in UserToken, where: t.user_id == ^user.id
  end

  @spec by_user_and_contexts_query(user :: User.t(), [String.t()]) :: Ecto.Query.t()
  def by_user_and_contexts_query(user, [_ | _] = contexts) do
    from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
  end

  @doc """
  Deletes a list of tokens.
  """
  @spec delete_all_query([UserToken.t()]) :: Ecto.Query.t()
  def delete_all_query(tokens) do
    from t in UserToken, where: t.id in ^Enum.map(tokens, & &1.id)
  end
end
