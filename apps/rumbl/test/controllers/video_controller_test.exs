defmodule Rumbl.VideoControllerTest do
  use Rumbl.ConnCase
  alias Rumbl.Repo
  alias Rumbl.Video

  setup %{conn: conn} = config do
    if username = config[:login_as] do
      user = insert_user(username: username)
      conn = assign(conn(), :current_user, user)
      {:ok, conn: conn, user: user}
    else
      :ok
    end
  end

  test "requires user authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, video_path(conn, :new)),
      get(conn, video_path(conn, :index)),
      get(conn, video_path(conn, :show, "123")),
      get(conn, video_path(conn, :edit, "123")),
      put(conn, video_path(conn, :update, "123")),
      post(conn, video_path(conn, :create, %{})),
      delete(conn, video_path(conn, :delete, "123")),
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end

  @tag login_as: "max"
  test "lists all user's videos on index", %{conn: conn, user: user} do
    user_video = insert_video(user, title: "funny cats")
    other_video = insert_video(insert_user(username: "other"), title: "another video")

    conn = get(conn, video_path(conn, :index))
    assert html_response(conn, 200) =~ "funny cats"
    assert String.contains?(conn.resp_body, user_video.title)
    refute String.contains?(conn.resp_body, other_video.title)
  end

  @valid_video_attrs %{
    url: "http://youtu.be",
    title: "title",
    description: "desc"
  }
  @invalid_video_attrs %{
    url: "http://youtu.be"
  }

  defp num_videos do
    Repo.one(
      from v in Video,
      select: count(v.id))
  end

  @tag login_as: "max"
  test "creates user video and redirects", %{conn: conn, user: user} do
    conn = post conn, video_path(conn, :create), video: @valid_video_attrs
    assert redirected_to(conn) == video_path(conn, :index)
    assert Repo.get_by(Video, @valid_video_attrs).user_id == user.id
  end

  @tag login_as: "max"
  test "shows error if not providing all values", %{conn: conn} do
    count_before = num_videos
    conn = post conn, video_path(conn, :create), video: @invalid_video_attrs
    assert html_response(conn, 200) =~ "check the errors"
    count_after = num_videos
    assert count_after == count_before
  end

  @tag login_as: "max"
  test "prevent users from seeing videos they didn't create", %{conn: conn, user: user} do
    video = insert_video(user, %{ url: "url", title: "title", description: "desc"})
    non_user = insert_user(%{username: "sneakster_pants"})
    conn = assign(conn, :current_user, non_user)
    assert_error_sent :not_found, fn ->
      get conn, video_path(conn, :show, video.id)
    end

    assert_error_sent :not_found, fn ->
      get conn, video_path(conn, :edit, video.id)
    end
  end
end
