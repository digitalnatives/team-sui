defmodule SuiServer.NewGame do
  use SuiServer.Web, :model

  alias SuiServer.Repo

  import Ecto.Query, only: [from: 2]
  import EctoEnum
  defenum StatusEnum, awaiting: 0, ready: 1, playing: 2, finished: 3

  schema "games" do
    field :token, :string
    field :status, StatusEnum
    field :player1, :string
    field :player2, :string

    timestamps
  end

  @required_fields ~w(token status player1)
  @optional_fields ~w(player2)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:token)
  end

  def all do
    import Ecto.Query, only: [from: 2]
    Repo.all(from g in SuiServer.NewGame, select: g)
  end

  def create(params) do
    changeset(%SuiServer.NewGame{token: SecureRandom.urlsafe_base64(4), status: :awaiting}, params)
    |> Repo.insert
  end

  def find(query) do
    Repo.one(query)
  end

  def find_by_token(token) do
    find(from g in SuiServer.NewGame, where: g.token == ^token)
  end

  def map do
    e = 0 # empty
    a = 1 # player A
    b = 2 # player B
    s = 3 # stone

    [
      e, e, e, e, e, e, e, b,
      e, e, e, e, e, e, e, e,
      e, e, e, e, e, e, e, e,
      e, e, e, s, s, e, e, e,
      e, e, e, s, s, e, e, e,
      e, e, e, e, e, e, e, e,
      e, e, e, e, e, e, e, e,
      a, e, e, e, e, e, e, e
    ]
  end

  def allow?(game, player) do
    game.status == :awaiting || Enum.member?([game.player1, game.player2], player)
  end

  def player_id(game, username) do
    case Enum.find_index([game.player1, game.player2], &(&1 == username)) do
       nil -> nil
       n -> n + 1
    end
  end

  def join(game, username) do
    if player_id(game, username) == nil do
      {:ok, game} = update_attributes(game, %{status: :ready, player2: username})
    end
    game
  end

  def new_status(game, status) do
    {:ok, game} = update_attributes(game, %{status: status})
    game
  end

  def update_attributes(game, attributes) do
    changeset(game, attributes) |> Repo.update
  end

  def new_move(game, _player, _move) do
    game
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
