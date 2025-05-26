defmodule Dustoff.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dustoff.Accounts` context.
  """

  import Ecto.Query

  alias Dustoff.Accounts
  alias Dustoff.Accounts.Scope
  alias Dustoff.Accounts.User

  @spec unique_user_email() :: String.t()
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @spec valid_user_password() :: String.t()
  def valid_user_password, do: "hello world!"

  @spec valid_user_attributes(map()) :: map()
  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: "some-good-test-password",
      password_confirmation: "some-good-test-password"
    })
  end

  @spec unconfirmed_user_fixture(map()) :: User.t()
  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  @spec user_fixture(map()) :: User.t()
  def user_fixture(attrs \\ %{}) do
    unconfirmed_user_fixture(attrs)
  end

  @spec user_scope_fixture() :: Scope.t()
  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  @spec user_scope_fixture(User.t()) :: Scope.t()
  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  # This seems like it can be deleted, if we have a `user_fixture/1` that has a password.
  @spec set_password(User.t()) :: User.t()
  def set_password(user) do
    {:ok, user, _expired_tokens} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  @spec extract_user_token(fun :: function()) :: String.t()
  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @spec override_token_authenticated_at(
          token :: String.t(),
          authenticated_at :: DateTime.t()
        ) :: :ok
  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    Dustoff.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  @spec generate_user_magic_link_token(User.t()) ::
          {encoded_token :: String.t(), token :: String.t()}
  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    Dustoff.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  @spec offset_user_token(
          token :: String.t(),
          amount_to_add :: integer(),
          unit :: :second | :minute | :hour | :day | :week | :month | :year
        ) :: :ok
  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Dustoff.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end
