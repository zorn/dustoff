# Command Line History

## June 2, 2025

When installing `Tidewave` I had to install a `mcp_proxy`. I used the Rust version from:

https://github.com/tidewave-ai/mcp_proxy_rust?tab=readme-ov-file#macos

And installed it in my home folder at `/Users/zorn/tidewave/mcp-proxy`.

## May 27, 2025

To help us experiment with scopes we will create an `Article` entity and some arbitrary business rules. 

Articles will be owned by a user through the `author_id` field (currently the generator always wants to call this `user_id` but I'll rename it after generating).

When a new `Article` is created that `Article` will be authored by the current user.

Generally speaking only the author of an article can edit or delete the article.

They can not assign it to another user by changing the `author_id`.

A privileged `admin` user (TBD how we mark users as `admin`) can reassign the author and make edits.

We should remove the ability for users to be outright deleted. Instead they should become `disabled`, which should mark them as such and disallow future authentication as well as kick them out of current sessions.

It might be helpful to filter the articles for articles with disabled authors to hint at those who should be updated.

```bash
mix phx.gen.live Articles Article articles --binary-id title:string body:text published_at:utc_datetime_usec
```

## May 20, 2025

<https://hexdocs.pm/phoenix/mix_phx_gen_auth.html>

We prefer to not utilize live views for authentication, because we plan to adjust the registration page to log the user in after accepting registration.

We prefer `argon2` for our hashing.

```bash
mix phx.gen.auth Accounts User users --no-live --binary-id --hashing-lib argon2
```

## May 14, 2025

The project was created with a pre-release version of the Phoenix project template. To install that we used:

```bash
mix archive.install hex phx_new 1.8.0-rc.3
```

When creating the project we wanted UUID-based id values and utilized the `--binary-id` [option](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html#module-options).

```bash
mix phx.new --binary-id dustoff
```
