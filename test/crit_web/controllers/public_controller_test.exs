defmodule CritWeb.PublicControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.CurrentUser.SessionController
  

  setup %{conn: conn} do
    [conn: Plug.Test.init_test_session(conn, [])]
  end

  describe "/" do 
    test "show home page when logged in", %{conn: conn} do
      conn
      |> logged_in()
      |> get("/")
      |> assert_purpose(home_page_for_logged_in_user())
    end
  
    test "without a logged in user, go to login form", %{conn: conn} do
      assert conn = get(conn, "/")
      assert redirected_to(conn) == SessionController.path(:get_login_form)
    end
  end
end
