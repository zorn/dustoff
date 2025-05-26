defmodule DustoffWeb.UserRegistrationController do
  use DustoffWeb, :controller

  alias Dustoff.Accounts
  alias DustoffWeb.UserAuth

  @spec new(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def new(conn, _params) do
    changeset = Accounts.registration_changeset()
    render(conn, :new, changeset: changeset)
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user, user_params)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
