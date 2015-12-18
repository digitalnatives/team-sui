defmodule SuiServer.Game do
  alias SuiServer.RedisPool

  defstruct id: nil, status: nil, players: []

  def create(username) do
    id = SecureRandom.urlsafe_base64(4)
    status = "awaiting"
    {:ok, ~w(OK OK)} = RedisPool.pipeline([
      ~w(HMSET game_status #{id} #{status}),
      ~w(HMSET game:#{id} player1 #{username})
    ])

    %{id: id, status: status, players: [username]}
  end

  def find(id) do
    {:ok, [[status], players]} = RedisPool.pipeline([
      ~w(HMGET game_status #{id}),
      ~w(HMGET game:#{id} player1 player2)
    ])

    %{id: id, status: status, players: players}
  end

  def allow?(game, username) do
    game.status == "awaiting" || Enum.member?(game.players, username)
  end

  def player_id(game, username) do
    Enum.find_index(game.players, &(&1 == username))
  end

  def join(game, username) do
    if player_id(game, username) == nil do
      {:ok, ~w(OK OK)} = RedisPool.pipeline([
        ~w(HMSET game_status #{game.id} ready),
        ~w(HMSET game:#{game.id} player2 #{username})
      ])
      find(game.id)
    else
      game
    end
  end
end
