defmodule SuiServer.GameChannel do
  use Phoenix.Channel
  alias SuiServer.NewGame, as: Game

  def join("game:lobby", _message, socket) do
    Process.flag(:trap_exit, true)
    send(self, {:new_player, username: socket.assigns.username })

    {:ok, socket}
  end

  def join("game:" <> _game_id, _message, socket) do
    Process.flag(:trap_exit, true)
    {:ok, socket}
  end

  def handle_info({:new_player, username: username }, socket) do
    broadcast! socket, "player:entered", %{name: username}
    {:noreply, socket}
  end

  def handle_info({"game:" <> event, game}, socket) do
    broadcast! socket, "game:#{event}", game
    {:noreply, socket}
  end

  def handle_in("new:game", _msg, socket) do
    username = socket.assigns.username
    {:ok, game} = Game.create(%{player1: username})
    broadcast! socket, "new:game", %{game_id: game.token, username: username}
    push socket, "game:await", %{game_id: game.token }
    {:reply, :ok, assign(socket, :game_id, game.token)}
  end
end
