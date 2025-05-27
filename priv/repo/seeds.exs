# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Dustoff.Repo.insert!(%Dustoff.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Dustoff.Accounts

# Create a user for local development
{:ok, user} =
  Accounts.register_user(%{
    email: "mike@mikezornek.com",
    password: "Password1234",
    password_confirmation: "Password1234"
  })

IO.puts("Created user: #{user.email}")
