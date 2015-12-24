defmodule SuiServer.Game do
  alias SuiServer.RedisPool

  defstruct id: nil, status: nil, players: []

  def create(username) do
    id = SecureRandom.urlsafe_base64(4)
    status = "awaiting"
    {:ok, ~w(OK OK OK)} = RedisPool.pipeline([
      ~w(HMSET game_status #{id} #{status}),
      ~w(HMSET game:#{id} player1 #{username}),
      ~w(HMSET game:#{id} board #{encode_board(map)})
    ])

    %{id: id, status: status, players: [username]}
  end

  def find(id) do
    {:ok, [[status], players, board]} = RedisPool.pipeline([
      ~w(HMGET game_status #{id}),
      ~w(HMGET game:#{id} player1 player2),
      ~w(HMGET game:#{id} board)
    ])

    %{id: id, status: status, players: players, board: decode_board(board)}
  end

  def map do
    a = 1
    b = 2
    e = 0

    [
      e, e, e, e, e, e, e, b,
      e, e, e, e, e, e, e, e,
      e, e, e, e, e, e, e, e,
      e, e, e, e, e, e, e, e,
      e, e, e, e, e, e, e, e,
      e, e, e, e, e, e, e, e,
      e, e, e, e, e, e, e, e,
      a, e, e, e, e, e, e, e
    ]
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

  def new_status(game, status) do
    {:ok, "OK"} = RedisPool.command(~w(HMSET game_status #{game.id} #{status}))
    find(game.id)
  end

  def new_move(game, username, move) do
    {:ok, "OK"} = RedisPool.command(~w(HMSET game:#{game.id} board #{encode_board(Enum.take_random(game.board, 64))}))
    find(game.id)
  end

  defp encode_board(board) do
    Poison.encode!(board)
  end

  defp decode_board(board) do
    Poison.decode!(board)
  end
end
