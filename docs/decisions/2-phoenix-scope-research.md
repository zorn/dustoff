# Research Notes: Phoenix Scopes

# Problem Statement

To better understand the newest [Scope authorization patterns](https://hexdocs.pm/phoenix/1.8.0-rc.3/scopes.html) introduced by Phoenix we made a [pull request](https://github.com/zorn/dustoff/pull/14) that introduced an `Article` entity.

Below I'll capture some early thoughts.

## Results

A few early notes about my initial interactions with scopes:

### Mixed signals on `Scope` presence and inner value enforcement.

Overall, scopes feels like a very thin implementation. So thin in fact I'm not sure I would build on top of it but rather use it as a reference for my own designs.

A default scope from the `phx.gen.auth` will look something like:

```elixir
defmodule MyApp.Accounts.Scope do
  alias MyApp.Accounts.User

  defstruct user: nil

  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil
end
```

Later a `Scope` struct value will be attached to the connection:

```elixir
# route.ex
...
pipeline :browser do
  ...
  plug :fetch_current_scope_for_user
end
```

```elixir
# user_auth.ex
def fetch_current_scope_for_user(conn, _opts) do
  {user_token, conn} = ensure_user_token(conn)
  user = user_token && Accounts.get_user_by_session_token(user_token)
  assign(conn, :current_scope, Scope.for_user(user))
end
```

(There are `on_mount` versions of this as well, but these code snippets demonstrate the upcoming point enough.)

I dislike the pattern that we only end up with a `Scope` struct value in the connection if we have an authenticated user (note the `def for_user(nil), do: nil` above). 

I would think even for non-authenticated connections I should still have a `Scope` value in the connection. It would simplify pattern matches in context functions, allowing me to assume I always have a `Scope` struct to match. Sometimes the `Scope` might have a user and sometimes it might not -- but it is always there for the function pattern match. In time, I could see other things being in the scope beyond the `user` (such as the current tenant of a multi-tenant app).

It also introduces confusion since the logic of the plug says a `Scope` will always have a `user` but that is not [enforced](https://hexdocs.pm/elixir/Kernel.html#defstruct/1-enforcing-keys) by the struct. It can technically be `nil`.

### No proper API language to describe unauthorized commands.

When you use the generator you'll end up with a context function like this:

```elixir
  def update_article(%Scope{} = scope, %Article{} = article, attrs) do
    true = article.user_id == scope.user.id

    with {:ok, article = %Article{}} <-
           article
           |> Article.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, article})
      {:ok, article}
    end
  end
```

If an unauthorized `Scope` is passed in, there is no return value. You'll get a runtime `MatchError` exception which to the user will look like a 500 because that is what it will render for all unplanned exceptions.

I feel like exceptions should be exceptional, and if they are part of the expected outcome of the function I would expect a bang `!` to [the end of the function name](https://hexdocs.pm/elixir/naming-conventions.html#trailing-bang-foo).

When I read my tests and see me verifying an unauthorized call by looking for `MatchError` I feel like I don't have a mature API design for my context.

In a similar vain to `Ecto.NoResultsError` being [converted](https://github.com/phoenixframework/phoenix_ecto/blob/d6870457660bb20a7716d42a180bd97777ca8702/lib/phoenix_ecto/plug.ex#L4) to a `404` I would expect some application named error being converted into a 500 more explicitly.

I get the feeling that the pattern the generators are building on is that the page to display the resource is backed by a `get!` which enforces vision rules, and then it is assumed all other commands (update, delete) are assumed to be allowed by that same actor.

A missing piece for more complete setups is there is no API to ask, "can this user edit this resource?" That logic is hardcoded inside `update_noun/2`. Therefore I feel like the design principle of scopes is that if the user can see the resource they can interact with the resource. Honestly that's probably fine for a simple generator but in production apps it usually gets more complicated pretty quickly.

## Some positives.

I do want to take a moment and say I'm very happy that we are seeing generators demonstrate authorization checks in context functions. The previous lack of this was bad for security and I've seen lots of projects that would use the previous patterns and push authorization checks into the Web UI which is a bad idea for security.

While I a may not love the new pattern, having it all all to kick start the conversation is a big win.
