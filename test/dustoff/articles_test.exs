defmodule Dustoff.ArticlesTest do
  use Dustoff.DataCase, async: true

  alias Dustoff.Articles

  describe "articles" do
    alias Dustoff.Articles.Article

    import Dustoff.AccountsFixtures, only: [user_scope_fixture: 0]
    import Dustoff.ArticlesFixtures

    @invalid_attrs %{title: nil, body: nil, published_at: nil}

    test "list_articles/1 returns all scoped articles" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      article = article_fixture(scope)
      other_article = article_fixture(other_scope)
      assert Articles.list_articles(scope) == [article]
      assert Articles.list_articles(other_scope) == [other_article]
    end

    test "get_article!/2 returns the article with given id" do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      other_scope = user_scope_fixture()
      assert Articles.get_article!(scope, article.id) == article
      assert_raise Ecto.NoResultsError, fn -> Articles.get_article!(other_scope, article.id) end
    end

    test "create_article/2 with valid data creates a article" do
      valid_attrs = %{
        title: "some title",
        body: "some body",
        published_at: ~U[2025-05-26 18:25:00.000000Z]
      }

      scope = user_scope_fixture()

      assert {:ok, %Article{} = article} = Articles.create_article(scope, valid_attrs)
      assert article.title == "some title"
      assert article.body == "some body"
      assert article.published_at == ~U[2025-05-26 18:25:00.000000Z]
      assert article.user_id == scope.user.id
    end

    test "create_article/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Articles.create_article(scope, @invalid_attrs)
    end

    test "update_article/3 with valid data updates the article" do
      scope = user_scope_fixture()
      article = article_fixture(scope)

      update_attrs = %{
        title: "some updated title",
        body: "some updated body",
        published_at: ~U[2025-05-27 18:25:00.000000Z]
      }

      assert {:ok, %Article{} = article} = Articles.update_article(scope, article, update_attrs)
      assert article.title == "some updated title"
      assert article.body == "some updated body"
      assert article.published_at == ~U[2025-05-27 18:25:00.000000Z]
    end

    test "update_article/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      article = article_fixture(scope)

      assert_raise MatchError, fn ->
        Articles.update_article(other_scope, article, %{})
      end
    end

    test "update_article/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Articles.update_article(scope, article, @invalid_attrs)
      assert article == Articles.get_article!(scope, article.id)
    end

    test "delete_article/2 deletes the article" do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      assert {:ok, %Article{}} = Articles.delete_article(scope, article)
      assert_raise Ecto.NoResultsError, fn -> Articles.get_article!(scope, article.id) end
    end

    test "delete_article/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      article = article_fixture(scope)
      assert_raise MatchError, fn -> Articles.delete_article(other_scope, article) end
    end

    test "change_article/2 returns a article changeset" do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      assert %Ecto.Changeset{} = Articles.change_article(scope, article)
    end
  end
end
