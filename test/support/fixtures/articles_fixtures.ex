defmodule Dustoff.ArticlesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dustoff.Articles` context.
  """

  @doc """
  Generate a article.
  """
  def article_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        body: "some body",
        published_at: ~U[2025-05-26 18:25:00.000000Z],
        title: "some title"
      })

    {:ok, article} = Dustoff.Articles.create_article(scope, attrs)
    article
  end
end
