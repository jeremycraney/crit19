defmodule CritWeb.Admin.UserControllerTest do
  use CritWeb.ConnCase
  # def fixture(:user) do
  #   {:ok, user} = Accounts.create_user(@create_attrs)
  #   user
  # end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.admin_user_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Users"
    end
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.admin_user_path(conn, :new))
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "create user" do
    test "redirects to show when data is valid", %{conn: conn} do
      attrs = user_attrs()
      conn = post(conn, Routes.admin_user_path(conn, :create), user: attrs)
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_user_path(conn, :show, id)

      conn = get(conn, Routes.admin_user_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show User"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      attrs = user_attrs(password: "")
      conn = post(conn, Routes.admin_user_path(conn, :create), user: attrs)
      assert html_response(conn, 200) =~ "New User"
    end
  end

  test "edit user renders form for editing chosen user", %{conn: conn} do
    conn = get(conn, Routes.admin_user_path(conn, :edit, saved_user()))
    assert html_response(conn, 200) =~ "Edit User"
  end

  describe "update user" do
    test "redirects when data is valid", %{conn: conn} do
      original = Faker.Name.name()
      user = saved_user(name: original)

      updated = original <> "xyzzy"
      update = %{"name" => updated}

      conn = put(conn, Routes.admin_user_path(conn, :update, user), user: update)
      assert redirected_to(conn) == Routes.admin_user_path(conn, :show, user)

      conn = get(conn, Routes.admin_user_path(conn, :show, user))
      assert html_response(conn, 200) =~ updated
    end

    test "renders errors when data is invalid", %{conn: conn} do
      user = saved_user()
      invalid = %{"name" => ""}
      conn = put(conn, Routes.admin_user_path(conn, :update, user), user: invalid)
      assert html_response(conn, 200) =~ "Edit User"
    end
  end
end
