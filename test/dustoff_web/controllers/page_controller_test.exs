defmodule DustoffWeb.PageControllerTest do
  use DustoffWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~
             "Dustoff is a proof-of-concept sandbox space where I plan to tinker with some things related to future Phoenix LiveView projects."
  end
end
