defmodule DustoffWeb.PageController do
  use DustoffWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
