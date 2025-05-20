defmodule DustoffWeb.UserSessionHTML do
  use DustoffWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:dustoff, Dustoff.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
