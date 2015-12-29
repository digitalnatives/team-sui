defmodule SuiServer.NewGameTest do
  use SuiServer.ModelCase

  alias SuiServer.NewGame

  @valid_attrs %{status: :awaiting, token: "some content", player1: "player"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = NewGame.changeset(%NewGame{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = NewGame.changeset(%NewGame{}, @invalid_attrs)
    refute changeset.valid?
  end
end
