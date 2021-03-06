defmodule Discuss.TopicController do
  use Discuss.Web, :controller

  alias Discuss.Topic

  plug Discuss.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]
  plug :check_topic_owner when action in [:edit, :update, :delete]

  def index(conn, _params) do
  	topics = Repo.all(Topic)

  	render conn, "index.html", topics: topics
  end

  def new(conn, _params) do
    changeset = Topic.changeset(%Topic{}, %{})

    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"topic" => topic}) do
  	changeset = conn.assigns.user
      |> build_assoc(:topics)
      |> Topic.changeset(topic)

  	case Repo.insert(changeset) do
  	  {:ok, _topic} -> 
  	    conn
  	    |> put_flash(:info, "Topic created")
  	    |> redirect(to: topic_path(conn, :index))
  	  {:error, changeset} -> render conn, "new.html", changeset: changeset
  	end
  end

  def edit(conn, %{"id" => id}) do
  	topic = Repo.get!(Topic, id)
  	changeset = Topic.changeset(topic)

  	render conn, "edit.html", changeset: changeset, topic: topic
  end

  def update(conn, %{"topic" => topic, "id" => id}) do
    old_topic = Repo.get!(Topic, id)
    changeset = Topic.changeset(old_topic, topic)

    case Repo.update(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic updated")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} -> render conn, "edit.html", changeset: changeset, topic: old_topic
     end
  end

  def delete(conn, %{"id" => id}) do
    topic = Repo.get!(Topic, id)

    case Repo.delete(topic) do
      {:ok, _topic} -> 
        conn
        |> put_flash(:info, "Topic \"#{topic.title}\" deleted")
        |> redirect(to: topic_path(conn, :index))
      {:error, _changeset} -> 
        conn
        |> put_flash(:info, "Topic \"#{topic.title}\" delete failed")
        |> redirect(to: topic_path(conn, :index))
    end
  end

  def check_topic_owner(%{params: %{"id" => topic_id}} = conn, _params) do
    if Repo.get(Topic, topic_id).user_id == conn.assigns.user.id do
      conn
    else 
      conn
      |> put_flash(:error, "You can't edit that topic")
      |> redirect(to: topic_path(conn, :index))
      |> halt()
    end
  end
end
