# Dustoff

Dustoff is a proof-of-concept sandbox space where I plan to tinker with some things related to future Phoenix LiveView projects.

## Project Goals

- [ ] Setup some project tooling (credo, dialyzer, ci, etc.)
- [ ] Add authentication. Users will log into the platform and then will have access to Organizations.
- [ ] Create a multi-tenant architecture to support keeping each Organization separate.
- [ ] To help express the multi-tenant tools create a entity type to support simple knowledge base articles (simple title and Markdown-enabled body).
- [ ] Learn and utilize newer [Phoenix Scope](https://hexdocs.pm/phoenix/1.8.0-rc.3/scopes.html) patterns
- [ ] Add [TimescaleDB](https://www.timescale.com/) to experiment with some analytic ideas.
- [ ] Add [live_svelte](https://github.com/woutdp/live_svelte) to experiment with using Svelte for some more complex frontend needs that would be awkward with pure LiveView.

## About the `Dustoff` Name

This is a project coming after I left a full time job and is a moment in time for fresh starts. The song [Pick Yourself Up](https://www.youtube.com/watch?v=20ViFpURIDk) by Nat King Cole and George Shearing has been a meaningful track playing during this time. `Dustoff` is a nod to that song.

## Standard Phoenix Readme Things

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
