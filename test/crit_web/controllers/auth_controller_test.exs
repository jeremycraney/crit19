defmodule CritWeb.AuthControllerTest do
  use CritWeb.ConnCase
  alias Ueberauth.Strategy.Helpers

  describe "request" do
    test "renders the login page", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :request, :identity))
      assert html_response(conn, 200) =~ "method=\"post\""
      assert html_response(conn, 200) =~ "action=\"#{Helpers.callback_url(conn)}\""
    end
  end

  describe "credential check" do
    setup do
      data = %{ 
        id:       "valid@example.com",
        wrong_id: "valiX@example.com",
        password: "a valid password",
      }

      user = saved_user(email: data.id, password: data.password)
      
      [data: Map.put(data, :user, user)]
    end
    
    test "succeeds", %{conn: conn, data: data} do
      conn = post(conn, Routes.auth_path(conn, :identity_callback),
        email: data.id, password: data.password)
      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert get_session(conn, :current_user) == data.user
      assert get_session(conn, :phoenix_flash)["info"] =~ "Success"
    end
    
    test "fails", %{conn: conn, data: data} do
      conn = post(conn, Routes.auth_path(conn, :identity_callback),
        email: data.wrong_id, password: data.password)
      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert get_session(conn, :phoenix_flash)["error"] =~ "wrong"
    end
  end
end