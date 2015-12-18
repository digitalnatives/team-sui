defmodule SuiServer.GameChannel do
  use Phoenix.Channel
  alias SuiServer.Game
  require Logger

  def join("game:lobby", _message, socket) do
    Process.flag(:trap_exit, true)
    send(self, {:new_player, username: socket.assigns.username })

    {:ok, socket}
  end

  def join("game:" <> game_id, _message, socket) do
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

  def handle_info({:new_player, username: username }, socket) do
    broadcast! socket, "player:entered", %{name: username}
    {:noreply, socket}
  end

  def handle_info({:game_connect, %{game: game, username: username}}, socket) do
    Game.join(game, username)
    {:noreply, socket}
  end

  def handle_in("new:game", msg, socket) do
    username = socket.assigns.username
    game = Game.create(username)
    push socket, "game:await", %{game_id: game.id }
    {:reply, :ok, assign(socket, :game_id, game.id)}
  end
end
