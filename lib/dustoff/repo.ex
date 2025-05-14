defmodule Dustoff.Repo do
  use Ecto.Repo,
    otp_app: :dustoff,
    adapter: Ecto.Adapters.Postgres
end
