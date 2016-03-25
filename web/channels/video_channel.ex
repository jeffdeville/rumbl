defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel
  alias Rumbl.Video
  alias Rumbl.Annotation
  alias Rumbl.User
  alias Rumbl.Repo

  def join("videos:" <> video_id_str, params, socket) do
    last_seen_id = params["last_seen_id"] || 0
    video_id = String.to_integer(video_id_str)
    annotations = Repo.all from a in Annotation,
                             where:     a.video_id == ^video_id,
                             where:     a.id > ^last_seen_id,
                             order_by:  [desc: a.at],
                             limit:     200,
                             preload:   [:user]
    resp = %{annotations: Phoenix.View.render_many(annotations, Rumbl.AnnotationView, "annotation.json")}
    {:ok, resp, assign(socket, :video_id, video_id)}
  end

  def handle_in("new_annotation", params, socket) do
    user = Repo.get(User, socket.assigns.user_id)
    handle_in("new_annotation", params, user, socket)
  end

  def handle_in("new_annotation", params, user, socket) do
    changeset =
      user
      |> build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)
    case Repo.insert(changeset) do
      {:ok, annotation} ->
        broadcast_annotation(socket, annotation, user)
        Task.start_link(fn -> compute_addl_info(socket, annotation) end)
        {:reply, :ok, socket}
      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  defp broadcast_annotation(socket, annotation, user) do
    broadcast! socket, "new_annotation", %{
      id: annotation.id,
      user: Rumbl.UserView.render("user.json", %{user: user}),
      body: annotation.body,
      at: annotation.at,
    }
  end

  defp compute_addl_info(socket, annotation) do
    for result <- Rumbl.InfoSys.compute(annotation.body, limit: 1, timeout: 10_000) do
      attrs = %{
        url: result.url,
        body: result.text,
        at: annotation.at
      }
      backend_user = Repo.get_by!(Rumbl.User, username: result.backend)
      info_changeset =
        backend_user
        |> build_assoc(:annotations, video_id: socket.assigns.video_id)
        |> Rumbl.Annotation.changeset(attrs)
      case Repo.insert(info_changeset) do
        {:ok, annotation} ->
          broadcast_annotation(socket, annotation, backend_user)
        {:error, _changeset} -> :ignore
      end
    end
  end
end
