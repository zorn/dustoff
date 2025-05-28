defmodule Dustoff.Articles.Article do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "articles" do
    field :title, :string
    field :body, :string
    field :published_at, :utc_datetime_usec
    field :user_id, :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(article, attrs, user_scope) do
    article
    |> cast(attrs, [:title, :body, :published_at])
    |> validate_required([:title, :body])
    |> put_change(:user_id, user_scope.user.id)
  end
end
