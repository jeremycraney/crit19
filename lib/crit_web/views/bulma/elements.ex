defmodule CritWeb.Bulma.Elements do
  use Phoenix.HTML
  import CritWeb.ErrorHelpers

  def compact_checkbox(form, field) do
    content_tag(:div, 
      [ checkbox(form, field),
        raw("&nbsp;"),
        humanize(field),
      ])
  end

  def form_button(text) do
   ~E"""
   <div class="field">
     <%= submit "#{text}", class: "button is-success" %>
   </div>
   """
  end

  def labeled_text_field(f, tag, label, text_input_extras \\ []) do
    wrapper = label f, tag, label, class: "label"
    error = error_tag f, tag
    IO.inspect error
    input = text_input f, tag, Keyword.put_new(text_input_extras, :class, "input")
    
    ~E"""
    <div class="field">
      <%= wrapper %>
      <div class="control">
         <%= input %>
         <%= error %>
      </div>
    </div>
    """
  end
end



