defmodule Rumbl.AuthTest do
  use Rumbl.ConnCase
  alias Rumbl.Auth
  alias Rumbl.Repo

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Rumbl.Router, :browser)
      |> get("/")
    {:ok, %{conn: conn}  }
  end

  test "authenticate_user halts if no current_user", %{conn: conn} do
    conn = Auth.authenticate_user(conn, [])
    assert conn.halted
  end

  test "authenticate_user continues if current_user exists", %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, %Rumbl.User{})
      |> Auth.authenticate_user([])
    refute conn.halted
  end

  test "login", %{conn: conn} do
    login_conn = conn
      |> Auth.login(%Rumbl.User{id: 123})
      |> send_resp(:ok, "")
    next_conn = get(login_conn, "/")
    assert get_session(next_conn, :user_id) == 123
  end

  test "logout", %{conn: conn} do
    logout_conn =
      conn
      |> put_session(:user_id, 123)
      |> Auth.logout()
      |> send_resp(:ok, "")

    next_conn = get(logout_conn, "/")
    refute get_session(next_conn, :user_id)
  end

  test "call with user in session puts user in current_user", %{conn: conn} do
    user = insert_user()
    conn =
      conn
      |> put_session(:user_id, user.id)
      |> Auth.call(Repo)
    assert conn.assigns.current_user.id == user.id
  end

  test "call w/no user in session sets current_user to nil", %{conn: conn} do
    conn = Auth.call(conn, Repo)
    assert conn.assigns.current_user == nil
  end

  test "login w/ email and pass", %{conn: conn} do
    user = insert_user(username: "me", password: "password")
    {:ok, conn} = Auth.login_by_username_and_pass(conn, "me", "password", repo: Repo)
    assert conn.assigns.current_user.id == user.id
  end

  test "login w/ a not found user", %{conn: conn} do
    assert {:error, :not_found, _} = Auth.login_by_username_and_pass(conn, "missing", "missing", repo: Repo)
  end

  test "login w/ an invalid password", %{conn: conn} do
    insert_user(username: "me", password: "password")
    assert {:error, :unauthorized, _} = Auth.login_by_username_and_pass(conn, "me", "missing", repo: Repo)
  end
end
