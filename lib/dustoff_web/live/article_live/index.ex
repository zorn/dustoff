defmodule DustoffWeb.ArticleLive.Index do
  use DustoffWeb, :live_view

  alias Dustoff.Articles

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Articles
        <:actions>
          <.button variant="primary" navigate={~p"/articles/new"}>
            <.icon name="hero-plus" /> New Article
          </.button>
        </:actions>
      </.header>

      <.table id="articles" rows={@streams.articles}>
        <:col :let={{_id, article}} label="Title">{article.title}</:col>
        <:col :let={{_id, article}} label="Published at">
          <%= if article.published_at do %>
            <.local_datetime datetime={article.published_at} />
          <% else %>
            Not Published
          <% end %>
        </:col>
        <:action :let={{_id, article}}>
          <.link navigate={~p"/articles/#{article}"}>Show</.link>
          <.link navigate={~p"/articles/#{article}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, article}}>
          <.link
            phx-click={JS.push("delete", value: %{id: article.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Articles.subscribe_articles(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Articles")
     |> stream(:articles, Articles.list_articles(socket.assigns.current_scope))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    article = Articles.get_article!(socket.assigns.current_scope, id)
    {:ok, _} = Articles.delete_article(socket.assigns.current_scope, article)

    {:noreply, stream_delete(socket, :articles, article)}
  end

  @impl Phoenix.LiveView
  def handle_info({type, %Dustoff.Articles.Article{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :articles, Articles.list_articles(socket.assigns.current_scope), reset: true)}
  end
end
