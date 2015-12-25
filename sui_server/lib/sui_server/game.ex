defmodule SuiServer.Game do
  alias SuiServer.RedisPool

  defstruct id: nil, status: nil, players: []

  def create(username) do
    id = SecureRandom.urlsafe_base64(4)
    status = "awaiting"
    {:ok, ~w(OK OK)} = RedisPool.pipeline([
      ~w(HMSET game_status #{id} #{status}),
      ~w(HMSET game:#{id} player1 #{username} board #{encode_board(map)} turn1 0 turn2 0),
    ])

    %{id: id, status: status, players: [username]}
  end

  def find(id) do
    {:ok, [[status], [player1, player2, board, turn1, turn2]]} = RedisPool.pipeline([
      ~w(HMGET game_status #{id}),
      ~w(HMGET game:#{id} player1 player2 board turn1 turn2),
    ])

    %{id: id, status: status, players: [player1, player2], board: decode_board(board), turns: [turn1, turn2]}
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
    case Enum.find_index(game.players, &(&1 == username)) do
       nil -> nil
       n -> n + 1
    end
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
    board = make_turn(game, username, move)
    {:ok, "OK"} = RedisPool.command(~w(HMSET game:#{game.id} board #{encode_board(board)}))
    find(game.id)
  end

  defp make_turn(game, username, move) do
    player = player_id(game, username)
    case step_outcome(game, move, player) do
      :forbidden -> game.board
      {:move, index, new_index } -> Enum.with_index(game.board)
      |> Enum.map fn {cell, cell_index} ->
        case cell_index do
          ^new_index -> player
          ^index -> 0
          _ -> cell
        end
      end
    end
  end

  defp step_outcome(game, move, player) do
    index = Enum.find_index(game.board, &(&1 == player))
    x = div(index, 8) + List.last(move)
    y = rem(index, 8) + List.first(move)
    new_index = 8 * x + y
    cell = Enum.at(game.board, new_index)
    cond do
      x < 0 || x > 7 -> :forbidden
      y < 0 || y > 7 -> :forbidden
      cell == 0 || cell == player -> {:move, index, new_index }
      true -> :forbidden
    end
  end

  defp encode_board(board) do
    Poison.encode!(board)
  end

  defp decode_board(board) do
    Poison.decode!(board)
  end
end
