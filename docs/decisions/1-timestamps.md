# Decision: Timestamps

# Problem Statement

Out of the box, when you use the Ecto [`timestamps/1` function][1], you end up with [`NaiveDateTime`][2] values for in-memory entities. This value type lacks the level of timezone and microsecond precision we would prefer.

[1]: https://hexdocs.pm/ecto/Ecto.Schema.html#timestamps/1
[2]: https://hexdocs.pm/elixir/NaiveDateTime.html

Aside: I believe the decision to return `NaiveDateTime` stems from Ecto's priority to align with MySQL out of the box, but not 100% sure.

## Solution

Our upcoming Ecto schemas will use `timestamps(type::utc_datetime_usec)` to be explicit about UTC (and thus will use `DateTime` over `NaiveDateTime`) and use microseconds for more precision.

When creating the database columns in our migration files, we will also use `timestamps(type::utc_datetime_usec)` to align with the schema change. 

This results in the database column having a type like `timestamp without time zone NOT NULL`. Take note this Postgres column type does not have any timezone information. We assume the database will always store timestamp values in UTC (which is a community norm).

## Other Solutions Considered

### `timestamptz`

We could have used a database migration style with `timestamps(type: :timestamptz)`, which would store timezone information in the Postgres database, **but** that also encourages people to store non-UTC timestamps in the database. For clarity, we prefer the database values always be in UTC.

This is not an irreversible decision and can be adjusted if wanted.

### What are timestamps?

The `inserted_at` and `updated_at` timestamp columns of the database are metadata of the implementation and should not be viewed as domain-specific values. The logic goes: If you want to track when your domain entities are created with your specific domain perspective, you should have `created_at` and `edited_at` columns. Those database-specific `inserted_at` and `updated_at` columns may change due to storage implementation needs and not accurately represent the actual domain knowledge.

That said, for the sake of simplicity, we are **not** going to introduce `created_at` and `edited_at` and will continue to make the `inserted_at` and `updated_at` values available to the Elixir code. Should these columns deviate from the domain interpretation, we can add those other columns later.
