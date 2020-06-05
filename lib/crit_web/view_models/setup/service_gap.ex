defmodule CritWeb.ViewModels.Setup.ServiceGap do
  use Ecto.Schema
  alias CritWeb.ViewModels.FieldFillers.ToWeb
  # import Ecto.Changeset
  # alias Ecto.Datespan
  # use Crit.Errors
  # alias Crit.FieldConverters.ToSpan
  # alias Crit.FieldConverters.FromSpan
  # import Ecto.Query
  # import Ecto.Datespan
  # alias Crit.Sql
  # alias Crit.Sql.CommonQuery
  
  @primary_key false   # I do this to emphasize that ID not be forgotten.
  embedded_schema do
    field :id, :id
    field :reason, :string

    field :institution, :string
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :delete, :boolean, default: false
  end


  def to_web(sources, institution) when is_list(sources),
    do: (for s <- sources, do: to_web(s, institution))

  def to_web(source, institution) do
    %{EnumX.pour_into(source, __MODULE__) |
      institution: institution
    }
    |> ToWeb.service_datestrings(source.span)
  end
end