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
    game = Game.join(game, username)
    broadcast! socket, "player:connected", %{username: username}
    if game.status == "ready" || game.status == "playing" do
      send(self, {:game_start, %{game: game}})
    end
    {:noreply, socket}
  end

  def handle_info({:game_start, %{game: game}}, socket) do
    game = Game.new_status(game, "playing")
    broadcast! socket, "game:start", game
    {:noreply, socket}
  end

  def handle_in("new:move", %{"move" => move}, socket) do
    "play:" <> game_id = socket.topic
    game = Game.find(game_id)
            |> Game.new_move(socket.assigns.username, move)
    push socket, "game:state", game
    {:reply, :ok, socket}
  end
end
