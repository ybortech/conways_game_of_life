defmodule Conway.Web.PageController do
  use Conway.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
