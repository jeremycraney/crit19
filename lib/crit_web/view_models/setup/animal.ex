defmodule CritWeb.ViewModels.Setup.Animal do
  use Ecto.Schema
  alias Crit.Ecto.TrimmedString
  alias CritWeb.ViewModels.Setup, as: ViewModels
  alias Crit.Setup.AnimalApi
  alias CritWeb.ViewModels.FieldFillers.ToWeb

  @primary_key false   # I do this to keep `id` from being forgotten.
  embedded_schema do
    field :id, :id
    # The fields below are the true fields in the table.
    field :name, TrimmedString
    field :lock_version, :integer
    
    # Fields used for displays or forms presented to a human
    field :institution, :string
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :species_name, :string

    field :service_gaps, {:array, ViewModels.ServiceGap}
  end

  def fetch(:all_possible, institution) do
      AnimalApi.inadequate_all(institution, preload: [:species])
      |> to_web(institution)
  end

  def fetch(:one_for_summary, id, institution) do
    AnimalApi.one_by_id(id, institution, preload: [:species])
    |> to_web(institution)
  end

  def fetch(:one_for_edit, id, institution) do
    AnimalApi.one_by_id(id, institution, preload: [:species, :service_gaps])
    |> to_web(institution)
  end

  # ----------------------------------------------------------------------------

  def to_web(sources, institution) when is_list(sources), 
    do: (for s <- sources, do: to_web(s, institution))

  def to_web(source, institution) do
    %{EnumX.pour_into(source, __MODULE__) |
      species_name: source.species.name,
      institution: institution
    }
    |> ToWeb.service_datestrings(source.span)
    |> ToWeb.when_loaded(:service_gaps, source,
                         &(ViewModels.ServiceGap.to_web(&1, institution)))
  end
end