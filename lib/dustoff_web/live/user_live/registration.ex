defmodule DustoffWeb.UserLive.Registration do
  @moduledoc """
  LiveView presenting a form for registering a new user.
  """

  use DustoffWeb, :live_view

  alias Dustoff.Accounts
  alias Dustoff.Accounts.User

  @impl Phoenix.LiveView
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    # When we already have an authenticated user, we redirect to the signed in path.
    socket
    |> redirect(to: DustoffWeb.UserAuth.signed_in_path(socket))
    |> ok()
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket
    |> assign(form: to_form(Accounts.register_user_changeset(%User{})))
    |> ok()
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # Log them in.
        socket
        |> put_flash(:info, "Account created successfully")
        |> push_navigate(to: ~p"/users/log-in")
        |> ok()

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.register_user_changeset(%User{}, user_params)
    # TODO: Consider moving this `validate` into a function option.
    changeset = Map.put(changeset, :action, :validate)

    socket
    |> assign(form: to_form(changeset))
    |> noreply()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <.header class="text-center">
          Register for an account
          <:subtitle>
            Already registered?
            <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
              Log in
            </.link>
            to your account now.
          </:subtitle>
        </.header>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />

          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="new-password"
            required
          />
          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm password"
            autocomplete="new-password"
          />

          <.button variant="primary" phx-disable-with="Creating account..." class="w-full">
            Create an account
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
