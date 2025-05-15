defmodule DustoffWeb.Router do
  use DustoffWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DustoffWeb.Layouts, :root}
    plug :protect_from_forgery

    # Tailwind uses SVG data URLs for icons,
    # so we need to allow them with `img-src`.
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
    plug :put_secure_browser_headers, %{
      "content-security-policy" => "default-src 'self'; img-src 'self' data:"
    }
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DustoffWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", DustoffWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:dustoff, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DustoffWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
