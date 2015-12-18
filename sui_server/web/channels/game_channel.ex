defmodule SuiServer.GameChannel do
  use Phoenix.Channel
  alias SuiServer.Game

  def join("game:lobby", _message, socket) do
    Process.flag(:trap_exit, true)
    send(self, {:new_player, username: socket.assigns.username })

    {:ok, socket}
  end

  def handle_info({:new_player, username: username }, socket) do
    broadcast! socket, "player:entered", %{name: username}
    {:noreply, socket}
  end

  def handle_in("new:game", msg, socket) do
    username = socket.assigns.username
    game = Game.create(username)
    broadcast! socket, "new:game", %{game_id: game.id, username: username}
    push socket, "game:await", %{game_id: game.id }
    {:reply, :ok, assign(socket, :game_id, game.id)}
  end
end
