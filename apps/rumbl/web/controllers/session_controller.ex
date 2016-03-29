defmodule Rumbl.SessionController do
  use Rumbl.Web, :controller

  def new(conn, params) do
    # create an empty changeset for just the username and password
    # Render it to a form
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"username" => username, "password" => password}}) do
    # load the changeset, and validate the hash using BCrypt. Should Auth do this,
    # Or the user object itself?
    case Rumbl.Auth.login_by_username_and_pass(conn, username, password, repo: Repo) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: page_path(conn, :index))
      {:error, :unauthorized, conn} ->
        show_notfound(conn)
      {:error, :not_found, conn} ->
        show_notfound(conn)
    end
  end

  def delete(conn, params) do
    conn
    |> Rumbl.Auth.logout()
    |> redirect(to: page_path(conn, :index))
  end

  defp show_notfound(conn) do
    conn
    |> put_flash(:error, "Invalid username/password")
    |> render("new.html")
  end
end
