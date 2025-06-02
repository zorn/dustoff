defmodule Dustoff.Articles do
  @moduledoc """
  The Articles context.
  """

  import Ecto.Query

  alias Dustoff.Accounts.Scope
  alias Dustoff.Articles.Article
  alias Dustoff.Repo

  @doc """
  Subscribes to scoped notifications about any article changes.

  The broadcasted messages match the pattern:

    * {:created, %Article{}}
    * {:updated, %Article{}}
    * {:deleted, %Article{}}

  """
  @spec subscribe_articles(scope :: Scope.t()) :: :ok
  def subscribe_articles(%Scope{} = scope) do
    key = scope.user.id

    :ok = Phoenix.PubSub.subscribe(Dustoff.PubSub, "user:#{key}:articles")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Dustoff.PubSub, "user:#{key}:articles", message)
  end

  @doc """
  Returns the list of articles.

  ## Examples

      iex> list_articles(scope)
      [%Article{}, ...]

  """
  @spec list_articles(scope :: Scope.t()) :: [Article.t()]
  def list_articles(%Scope{} = scope) do
    Repo.all(from article in Article, where: article.user_id == ^scope.user.id)
  end

  @doc """
  Gets a single article.

  Raises `Ecto.NoResultsError` if the Article does not exist.

  ## Examples

      iex> get_article!(123)
      %Article{}

      iex> get_article!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_article!(scope :: Scope.t(), Article.id()) :: Article.t()
  def get_article!(%Scope{} = scope, id) do
    Repo.get_by!(Article, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a article.

  ## Examples

      iex> create_article(%{field: value})
      {:ok, %Article{}}

      iex> create_article(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_article(scope :: Scope.t(), attrs :: map()) ::
          {:ok, Article.t()} | {:error, Ecto.Changeset.t()}
  def create_article(%Scope{} = scope, attrs) do
    with {:ok, article = %Article{}} <-
           %Article{}
           |> Article.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, article})
      {:ok, article}
    end
  end

  @doc """
  Updates a article.

  ## Examples

      iex> update_article(article, %{field: new_value})
      {:ok, %Article{}}

      iex> update_article(article, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_article(
          scope :: Scope.t(),
          article :: Article.t(),
          attrs :: map()
        ) :: {:ok, Article.t()} | {:error, Article.changeset()}
  def update_article(%Scope{} = scope, %Article{} = article, attrs) do
    # TODO: I don't think `MatchError` is the right runtime experience here.
    true = article.user_id == scope.user.id

    with {:ok, article = %Article{}} <-
           article
           |> Article.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, article})
      {:ok, article}
    end
  end

  @doc """
  Publishes an article.

  Call sites can pass in the wanted `published_at` value or the function will
  use `DateTime.utc_now()`.
  """
  @spec publish_article(
          scope :: Scope.t(),
          article :: Article.t(),
          published_at :: DateTime.t() | nil
        ) ::
          {:ok, Article.t()} | {:error, Article.changeset()}
  def publish_article(
        %Scope{} = scope,
        %Article{} = article,
        published_at \\ nil
      ) do
    true = article.user_id == scope.user.id

    published_at = published_at || DateTime.utc_now()

    changeset = Ecto.Changeset.cast(article, %{published_at: published_at}, [:published_at])

    with {:ok, article = %Article{}} <- Repo.update(changeset) do
      broadcast(scope, {:updated, article})
      {:ok, article}
    end
  end

  @doc """
  Deletes a article.

  ## Examples

      iex> delete_article(article)
      {:ok, %Article{}}

      iex> delete_article(article)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_article(
          scope :: Scope.t(),
          article :: Article.t()
        ) :: {:ok, Article.t()} | {:error, Article.changeset()}
  def delete_article(%Scope{} = scope, %Article{} = article) do
    true = article.user_id == scope.user.id

    with {:ok, article = %Article{}} <-
           Repo.delete(article) do
      broadcast(scope, {:deleted, article})
      {:ok, article}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking article changes.

  ## Examples

      iex> change_article(article)
      %Ecto.Changeset{data: %Article{}}

  """
  @spec change_article(
          scope :: Scope.t(),
          article :: Article.t() | Article.struct_t(),
          attrs :: map()
        ) :: Article.changeset()
  def change_article(%Scope{} = scope, %Article{} = article, attrs \\ %{}) do
    true = article.user_id == scope.user.id

    Article.changeset(article, attrs, scope)
  end
end
