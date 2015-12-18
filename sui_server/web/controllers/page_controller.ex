defmodule SuiServer.PageController do
  use SuiServer.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
