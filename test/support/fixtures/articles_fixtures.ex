defmodule Dustoff.ArticlesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dustoff.Articles` context.
  """

  @doc """
  Generate a article.

  If the `published_at` attribute is provided, the article will be published.
  Otherwise, the article will be unpublished.
  """
  @spec article_fixture(Dustoff.Accounts.Scope.t(), attrs :: map()) ::
          Dustoff.Articles.Article.t()
  def article_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        body: "some body",
        title: "some title"
      })

    {:ok, unpublished_article} = Dustoff.Articles.create_article(scope, attrs)

    if attrs[:published_at] do
      {:ok, published_article} =
        Dustoff.Articles.publish_article(
          scope,
          unpublished_article,
          attrs[:published_at]
        )

      published_article
    else
      unpublished_article
    end
  end
end
