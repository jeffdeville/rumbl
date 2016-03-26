defmodule Rumbl.UserRepoTest do
  use Rumbl.ModelCase, async: false
  alias Rumbl.User
  alias Rumbl.Repo

  @valid_attrs %{
    name: "Name",
    username: "Username",
    password: "password"
  }

  test "verify unique_constraint on usernames" do
    user = insert_user(username: "jeff")
    attrs = Map.put(@valid_attrs, :username, "jeff")
    changeset = User.changeset(%User{}, attrs)
    assert {:error, changeset} = Repo.insert(changeset)
    assert {:username, "has already been taken"} in changeset.errors
  end
end
