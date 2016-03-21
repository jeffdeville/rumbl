defmodule Rumbl.UserTest do
  use Rumbl.ModelCase, async: true
  alias Rumbl.User

  @valid_attrs %{
    name: "Name",
    username: "Username",
    password: "password"
  }
  @invalid_attrs %{}

  test "validate changeset w/ valid attrs" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "validate changeset w/ invalid attrs" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "registration_changeset password must be at least 6 chars long" do
    attrs = Map.put(@valid_attrs, :password, "hi")
    changeset = User.registration_changeset(%User{}, attrs)
    assert {:password, { "should be at least %{count} character(s)", [count: 6]} } in changeset.errors
  end

  test "registration_changeset hashes the password if valid" do
    changeset = User.registration_changeset(%User{}, @valid_attrs)
    assert changeset.valid?
    %{password: pass, password_hash: pass_hash} = changeset.changes
    assert pass_hash
    assert Comeonin.Bcrypt.checkpw(pass, pass_hash)
  end
end
