defmodule SuiServer.Repo.Migrations.CreateNewGame do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :token, :string, null: false
      add :status, :integer, null: false
      add :player1, :string, null: false
      add :player2, :string

      timestamps
    end

    create unique_index(:games, [:token])
  end
end
