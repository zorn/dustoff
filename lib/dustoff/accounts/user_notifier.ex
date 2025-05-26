defmodule Dustoff.Accounts.UserNotifier do
  @moduledoc """
  Provides functions for delivering emails to users.
  """

  import Swoosh.Email

  alias Dustoff.Accounts.User
  alias Dustoff.Mailer

  # Delivers the email using the application mailer.
  @spec deliver(
          recipient :: String.t(),
          subject :: String.t(),
          body :: String.t()
        ) :: {:ok, Swoosh.Email.t()} | {:error, any()}
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Dustoff Admin Mike Zornek", "mike@mikezornek.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  @spec deliver_update_email_instructions(
          user :: User.t(),
          url :: String.t()
        ) :: {:ok, Swoosh.Email.t()} | {:error, any()}
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  # I think I want this eventually. I need to add an explicit `verify` button in settings.
  # defp deliver_confirmation_instructions(user, url) do
  #   deliver(user.email, "Confirmation instructions", """

  #   ==============================

  #   Hi #{user.email},

  #   You can confirm your account by visiting the URL below:

  #   #{url}

  #   If you didn't create an account with us, please ignore this.

  #   ==============================
  #   """)
  # end
end
