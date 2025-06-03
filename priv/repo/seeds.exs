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
alias Dustoff.Articles
alias Dustoff.Accounts.Scope

# Create users
{:ok, user1} =
  Accounts.register_user(%{
    email: "mike@mikezornek.com",
    password: "Password1234",
    password_confirmation: "Password1234"
  })

{:ok, user2} =
  Accounts.register_user(%{
    email: "amy@example.com",
    password: "Password1234",
    password_confirmation: "Password1234"
  })

{:ok, user3} =
  Accounts.register_user(%{
    email: "billy@example.com",
    password: "Password1234",
    password_confirmation: "Password1234"
  })

IO.puts("Created users:")
IO.puts(user1.email)
IO.puts(user2.email)
IO.puts(user3.email)

# Create breakfast articles
breakfast_articles = [
  %{
    title: "The Perfect Avocado Toast",
    body:
      "Start your day right with this simple yet delicious avocado toast recipe. Mash ripe avocado with a pinch of salt, spread on toasted sourdough, and top with red pepper flakes and a poached egg.",
    published_at: ~U[2025-05-27 08:00:00.000000Z]
  },
  %{
    title: "Fluffy Pancakes with Maple Syrup",
    body:
      "These light and fluffy pancakes are a breakfast classic. Serve with real maple syrup and fresh berries for a sweet start to your day.",
    published_at: ~U[2025-05-27 08:30:00.000000Z]
  },
  %{
    title: "Breakfast Burrito Bowl",
    body:
      "A healthy and filling breakfast bowl with scrambled eggs, black beans, avocado, and salsa. Perfect for busy mornings!",
    published_at: ~U[2025-05-27 09:00:00.000000Z]
  },
  %{
    title: "Overnight Oats with Berries",
    body:
      "Prepare these oats the night before for a quick, nutritious breakfast. Mix oats with milk, yogurt, and honey, then top with fresh berries in the morning.",
    published_at: ~U[2025-05-27 09:30:00.000000Z]
  },
  %{
    title: "Classic Eggs Benedict",
    body:
      "A brunch favorite featuring poached eggs on English muffins with Canadian bacon and hollandaise sauce. A true breakfast indulgence!",
    published_at: ~U[2025-05-27 10:00:00.000000Z]
  }
]

# Create articles for each user
Enum.each([user1, user2, user3], fn user ->
  scope = Scope.for_user(user)

  Enum.each(breakfast_articles, fn article_attrs ->
    {:ok, article} = Articles.create_article(scope, article_attrs)
    IO.puts("Created article '#{article.title}' for #{user.email}")
  end)
end)
