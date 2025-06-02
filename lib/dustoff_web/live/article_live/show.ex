defmodule DustoffWeb.ArticleLive.Show do
  use DustoffWeb, :live_view

  alias Dustoff.Articles

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Article {@article.id}
        <:subtitle>This is a article record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/articles"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/articles/#{@article}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit article
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Title">{@article.title}</:item>
        <:item title="Body">{@article.body}</:item>
        <:item title="Published at">
          <%= if @article.published_at do %>
            <.local_datetime datetime={@article.published_at} />
          <% else %>
            Not Published
          <% end %>
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Articles.subscribe_articles(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Article")
     |> assign(:article, Articles.get_article!(socket.assigns.current_scope, id))}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:updated, %Dustoff.Articles.Article{id: id} = article},
        %{assigns: %{article: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :article, article)}
  end

  def handle_info(
        {:deleted, %Dustoff.Articles.Article{id: id}},
        %{assigns: %{article: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current article was deleted.")
     |> push_navigate(to: ~p"/articles")}
  end

  def handle_info({type, %Dustoff.Articles.Article{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
