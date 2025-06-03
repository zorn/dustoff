defmodule Dustoff.ArticlesTest do
  use Dustoff.DataCase, async: true

  import Dustoff.AccountsFixtures, only: [user_scope_fixture: 0]
  import Dustoff.ArticlesFixtures

  alias Dustoff.Articles
  alias Dustoff.Articles.Article

  describe "articles" do
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
        body: "some body"
      }

      scope = user_scope_fixture()

      assert {:ok, %Article{} = article} = Articles.create_article(scope, valid_attrs)
      assert article.title == "some title"
      assert article.body == "some body"
      assert article.author_id == scope.user.id
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
        body: "some updated body"
      }

      assert {:ok, %Article{} = article} = Articles.update_article(scope, article, update_attrs)
      assert article.title == "some updated title"
      assert article.body == "some updated body"
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

  describe "publish_article/3" do
    test "marks an article as published with a given `published_at` value" do
      published_at = DateTime.utc_now()
      scope = user_scope_fixture()
      article = article_fixture(scope, published_at: nil)
      assert {:ok, %Article{} = article} = Articles.publish_article(scope, article, published_at)
      assert article.published_at == published_at
    end

    test "marks an article as published with the current time if no `published_at` value is provided" do
      now = DateTime.utc_now()
      scope = user_scope_fixture()
      article = article_fixture(scope, published_at: nil)
      assert {:ok, %Article{} = article} = Articles.publish_article(scope, article)
      assert article.published_at != nil
      assert DateTime.before?(now, article.published_at)
    end

    test "raises if the article is not owned by the scope" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      article = article_fixture(other_scope)
      assert_raise MatchError, fn -> Articles.publish_article(scope, article) end
    end
  end

  describe "unpublish_article/2" do
    test "marks an article as unpublished" do
      scope = user_scope_fixture()
      published_article = article_fixture(scope, published_at: DateTime.utc_now())
      assert {:ok, %Article{} = article} = Articles.unpublish_article(scope, published_article)
      assert article.published_at == nil
    end

    test "raises if the article is not owned by the scope" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      published_article = article_fixture(other_scope, published_at: DateTime.utc_now())
      assert_raise MatchError, fn -> Articles.unpublish_article(scope, published_article) end
    end

    test "raises if the article is not published" do
      scope = user_scope_fixture()
      article = article_fixture(scope, published_at: nil)
      assert_raise FunctionClauseError, fn -> Articles.unpublish_article(scope, article) end
    end
  end
end
