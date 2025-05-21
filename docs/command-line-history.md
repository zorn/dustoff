# Command Line History

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
