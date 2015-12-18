defmodule SuiServer.GameChannel do
  use Phoenix.Channel
  require Logger

  def join("game:lobby", _message, socket) do
    Process.flag(:trap_exit, true)
    send(self, :new_player)

    {:ok, socket}
  end

  def join("game:" <> game_id, _message, socket) do
    Process.flag(:trap_exit, true)
    send(self, {:game_connect, %{game_id: game_id}})

    {:ok, socket}
  end

  def handle_info(:new_player, socket) do
    broadcast! socket, "player:entered", %{name: socket.assigns.username}
    {:noreply, socket}
  end

  def handle_info({:game_connect, msg}, socket) do
    {:noreply, socket}
  end

  def handle_in("new:game", msg, socket) do
    game_id = SecureRandom.urlsafe_base64(4)
    push socket, "game:await", %{game_id: game_id }
    {:reply, :ok, assign(socket, :game_id, game_id)}
  end
end
