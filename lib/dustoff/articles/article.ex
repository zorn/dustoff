defmodule Dustoff.Articles.Article do
  @moduledoc """
  An entity representing an knowledge base article.

  ## Fields

  * `:id` - The identity of this entity, a UUID value.
  * `:title` - The title of the article.
  * `:body` - The body of the article.
  * `:published_at` - The date and time the article was published.
  * `:user_id` - The identity of the user who created the article.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Dustoff.Accounts.Scope

  @typedoc """
  A repo-sourced `Dustoff.Articles.Article` entity.
  """
  @type t() :: %__MODULE__{
          id: id(),
          title: String.t(),
          body: String.t(),
          published_at: DateTime.t() | nil,
          user_id: id()
        }

  @typedoc """
  A simple struct type of a `Dustoff.Accounts.UserToken` entity.

  This type is sometimes needed when want to compose a function typespec that
  will return a non-repo sourced struct value.
  """
  @type struct_t() :: %__MODULE__{}

  @typedoc """
  An `Ecto.Changeset` for a repo-sourced `Dustoff.Articles.Article` entity.
  """
  @type changeset() :: Ecto.Changeset.t(t())

  @typedoc """
  The identity value type of a `Dustoff.Articles.Article` entity.
  """
  @type id() :: Ecto.UUID.t()

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
  @spec changeset(
          article :: t() | struct_t(),
          attrs :: map(),
          user_scope :: Scope.t()
        ) :: Ecto.Changeset.t()
  def changeset(article, attrs, user_scope) do
    article
    |> cast(attrs, [:title, :body])
    # TODO: Make sure we are validating the required user_id.
    |> validate_required([:title, :body])
    |> put_change(:user_id, user_scope.user.id)
  end
end
