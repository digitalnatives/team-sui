defmodule SuiServer.GamePlayChannel do
  use Phoenix.Channel
  alias SuiServer.Game

  def join("play:" <> game_id, _message, socket) do
    username = socket.assigns.username
    game = Game.find(game_id)

    if Game.allow?(game, username) do
      Process.flag(:trap_exit, true)
      send(self, {:game_connect, %{game: game, username: username}})
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:game_connect, %{game: game, username: username}}, socket) do
    Game.join(game, username)
    broadcast! socket, "player:connected", %{username: username}
    {:noreply, socket}
  end
end
