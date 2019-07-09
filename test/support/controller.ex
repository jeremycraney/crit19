defmodule Crit.Test.Controller do

  def flash_error(conn),
    do: Plug.Conn.get_session(conn, :phoenix_flash)["error"]

  def standard_blank_error, do: "can&#39;t be blank"

  defmacro __using__(opts) do
    controller = opts[:controller]
    quote do
      import Crit.Test.Controller
      
      defp get_via_action(args) do 
        conn = hd(args)
        get(conn, unquote(controller).path(args))
      end

      defp post_to_action(path_args, post_params) do
        conn = hd(path_args)
        post(conn, unquote(controller).path(path_args), post_params)
      end

      defp assert_rendered(conn, file),
        do: assert html_response(conn, 200) =~ unquote(controller).template_file(file)
    end
  end
end
