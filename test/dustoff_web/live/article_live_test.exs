defmodule DustoffWeb.ArticleLiveTest do
  use DustoffWeb.ConnCase

  import Phoenix.LiveViewTest
  import Dustoff.ArticlesFixtures

  @create_attrs %{title: "some title", body: "some body", published_at: "2025-05-26T18:25:00.000000Z"}
  @update_attrs %{title: "some updated title", body: "some updated body", published_at: "2025-05-27T18:25:00.000000Z"}
  @invalid_attrs %{title: nil, body: nil, published_at: nil}

  setup :register_and_log_in_user

  defp create_article(%{scope: scope}) do
    article = article_fixture(scope)

    %{article: article}
  end

  describe "Index" do
    setup [:create_article]

    test "lists all articles", %{conn: conn, article: article} do
      {:ok, _index_live, html} = live(conn, ~p"/articles")

      assert html =~ "Listing Articles"
      assert html =~ article.title
    end

    test "saves new article", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/articles")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Article")
               |> render_click()
               |> follow_redirect(conn, ~p"/articles/new")

      assert render(form_live) =~ "New Article"

      assert form_live
             |> form("#article-form", article: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#article-form", article: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/articles")

      html = render(index_live)
      assert html =~ "Article created successfully"
      assert html =~ "some title"
    end

    test "updates article in listing", %{conn: conn, article: article} do
      {:ok, index_live, _html} = live(conn, ~p"/articles")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#articles-#{article.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/articles/#{article}/edit")

      assert render(form_live) =~ "Edit Article"

      assert form_live
             |> form("#article-form", article: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#article-form", article: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/articles")

      html = render(index_live)
      assert html =~ "Article updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes article in listing", %{conn: conn, article: article} do
      {:ok, index_live, _html} = live(conn, ~p"/articles")

      assert index_live |> element("#articles-#{article.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#articles-#{article.id}")
    end
  end

  describe "Show" do
    setup [:create_article]

    test "displays article", %{conn: conn, article: article} do
      {:ok, _show_live, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ "Show Article"
      assert html =~ article.title
    end

    test "updates article and returns to show", %{conn: conn, article: article} do
      {:ok, show_live, _html} = live(conn, ~p"/articles/#{article}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/articles/#{article}/edit?return_to=show")

      assert render(form_live) =~ "Edit Article"

      assert form_live
             |> form("#article-form", article: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#article-form", article: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/articles/#{article}")

      html = render(show_live)
      assert html =~ "Article updated successfully"
      assert html =~ "some updated title"
    end
  end
end
