defmodule Rumbl.CategoryRepoTest do
  use Rumbl.ModelCase, async: false
  alias Rumbl.Repo
  alias Rumbl.Category

  test "alphabetical listings" do
    for category_name <- ~w(c a b) do
      Repo.insert! %Category{name: category_name}
    end
    query = Category.alphabetical(Category)
    query = from c in query, select: c.name
    assert Repo.all(query) == ~w(a b c)
  end

end
