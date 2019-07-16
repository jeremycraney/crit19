defmodule CritWeb.Router do
  use CritWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CritWeb.Plug.Session
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CritWeb do
    pipe_through :browser

    get "/", PublicController, :index
    get "/login", PublicController, :redirect_to_login
  end

  scope "/user_management", CritWeb.UserManagement, as: :user_management do
    pipe_through :browser
    resources "/users", UserController, except: [:delete]
  end

  scope "/current_user", CritWeb.CurrentUser, as: :current_user do
    pipe_through :browser
    get "/password_using/:token_text", AuthorizationController, :fresh_password_form
    post "/fresh_password", AuthorizationController, :set_fresh_password


    get "/login", AuthorizationController, :get_login_form
    post "/login", AuthorizationController, :try_login 
    delete "/logout", AuthorizationController, :logout


  end
  

  # Other scopes may use custom stacks.
  # scope "/api", CritWeb do
  #   pipe_through :api
  # end
end
