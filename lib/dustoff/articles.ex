defmodule Dustoff.Articles do
  @moduledoc """
  The Articles context.
  """

  import Ecto.Query, warn: false
  alias Dustoff.Repo

  alias Dustoff.Articles.Article
  alias Dustoff.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any article changes.

  The broadcasted messages match the pattern:

    * {:created, %Article{}}
    * {:updated, %Article{}}
    * {:deleted, %Article{}}

  """
  def subscribe_articles(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Dustoff.PubSub, "user:#{key}:articles")
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

  @doc """
  Deletes a article.

  ## Examples

      iex> delete_article(article)
      {:ok, %Article{}}

      iex> delete_article(article)
      {:error, %Ecto.Changeset{}}

  """
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
  def change_article(%Scope{} = scope, %Article{} = article, attrs \\ %{}) do
    true = article.user_id == scope.user.id

    Article.changeset(article, attrs, scope)
  end
end
