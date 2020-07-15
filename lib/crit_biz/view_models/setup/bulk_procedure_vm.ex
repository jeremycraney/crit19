defmodule CritBiz.ViewModels.Setup.BulkProcedure do
  use CritBiz, :view_model
  use ExContract
  alias CritBiz.ViewModels.Setup, as: VM
  alias CritBiz.ViewModels.Common
  alias Crit.Schemas
  alias Crit.Ecto.TrimmedString
  
  alias Ecto.Multi
  alias Crit.Ecto.BulkInsert
  alias Ecto.Changeset
  alias Ecto.ChangesetX
  alias Crit.Setup.InstitutionApi
  

  # The index is used to give each element of the array its own unique id.
  # That may not be necessary, but it doesn't hurt and is arguably clearer.
  @primary_key false
  embedded_schema do
    field :index, :integer
    field :name, TrimmedString, default: ""
    field :species_ids, {:array, :id}, default: []
    field :frequency_id, :integer
    
    field :blank?, :boolean, default: false, virtual: true
  end

  def fields(), do: __schema__(:fields)
  # `:name` and `:species_id` may be absent, if absent together.
  def required(), do: fields() |> ListX.delete([:name, :species_ids])

  def fresh_form_changesets() do
    for i <- 0..9 do 
      %__MODULE__{index: i} |> change
    end
  end

  # ----------------------------------------------------------------------------

  @spec accept_form(params()) :: nary_error([Changeset.t(VM.BulkProcedure)])
  def accept_form(params) do
    params = Common.flatten_to_list(params)
    changesets = Enum.map(params, &fresh_individual_changeset/1)

    for_blank_form? = fn changeset ->
      ChangesetX.newest!(changeset, :blank?)
    end
    
    case Enum.all?(changesets, &(&1.valid?)) do
      true ->
        {:ok, Enum.reject(changesets, for_blank_form?) }
      false ->
        {:error, :form, changesets}
    end
  end

  defp fresh_individual_changeset(attrs) do
    cast(%__MODULE__{}, attrs, fields())
    |> validate_name_and_species
    |> validate_required(required())
  end


  defp validate_name_and_species(original) do
    #Need to find a way to get access to inner workings of validation
    blank_name =
      original
      |> validate_required([:name])
      |> ChangesetX.has_error?(:name)
    
    blank_species =
      ChangesetX.newest!(original, :species_ids) == []

    case {blank_name, blank_species}  do
      {true, true} ->
        put_change(original, :blank?, true)
      {true, _} ->
        validate_required(original, [:name]) # sets the error.
      {_, true} ->
        add_error(original, :species_ids, @at_least_one_species)
      {_, _} ->
        original
    end
  end

  # ----------------------------------------------------------------------------

  @spec lower_changesets([Changeset.t(VM.BulkProcedure)]) :: [Schemas.Procedure]
  def lower_changesets(changesets),
    do: Enum.flat_map(changesets, &lower_changeset/1)
  
  @spec lower_changeset(Changeset.t(VM.BulkProcedure)) :: Schemas.Procedure
  def lower_changeset(vm_changeset) do
    view_model = apply_changes(vm_changeset)
    for species_id <- view_model.species_ids do
      %Schemas.Procedure{
        name: view_model.name,
        frequency_id: view_model.frequency_id,
        species_id: species_id
      }
    end
  end

  # ----------------------------------------------------------------------------

  @spec insert_all([Schemas.Procedure], short_name()) :: [VM.Procedure]
  def insert_all(procedures, institution) do
    insertion_result = 
      (for p <- procedures, do: Schemas.Procedure.constrained(p))
      |> BulkInsert.insertion_script(institution, schema: Schemas.Procedure)
      |> Sql.transaction(institution)
      |> Sql.Transaction.simplify_result(:return_inserted_values)
    
    case insertion_result do
      {:ok, procedures} -> 
        {:ok, VM.Procedure.lift(procedures, institution)}
      {:error, index, changeset} ->
        check Keyword.has_key?(changeset.errors, :name)
        message = duplicate_name_message(changeset, institution)
        {:error, :constraint, %{duplicate_name: index, message: message}}
    end
  end


  defp duplicate_name_message(changeset, institution) do
    data = Changeset.apply_changes(changeset)
    "A procedure named \"" <> data.name <> "\" already exists for species " <>
      InstitutionApi.species_name(data.species_id, institution)
  end

  #### OLD

  def starting_changeset() do
    %__MODULE__{}
    |> cast(%{}, fields())
  end

  def changeset(%__MODULE__{} = struct, attrs) do
    start = cast(struct, attrs, fields())
    case {fetch_change(start, :name), fetch_change(start, :species_ids)} do
      {:error, :error} -> start
      {:error, _} -> start
      {_, :error} -> add_error(start, :species_ids, @at_least_one_species)
      {_, _} -> start
    end
  end

  def changesets(descriptions) do
    changesets = Enum.map(descriptions, &(changeset(%__MODULE__{}, &1)))
    case Enum.all?(changesets, &(&1.valid?)) do
      true -> {:ok, changesets}
      false -> {:error, changesets}
    end
  end

  def insert_changesets(changesets, institution) do
    case make_multi(changesets, institution)|> Sql.transaction(institution) do
      {:ok, from_multi_id__to__procedure} ->
        {:ok, Map.values(from_multi_id__to__procedure)}
      {:error, insertion_id, failing_changeset, _previous_results} ->
        {:error, transfer_multi_error(insertion_id, failing_changeset, changesets)}
    end
  end

  # -------------------------------------------------------------------0- 

  def unfold_to_attrs(changesets) do # public for testing
    one_set = fn %{changes: changes}, species_id ->
      %{name: changes.name,
        species_id: species_id,
        frequency_id: changes.frequency_id}
    end

    Enum.flat_map(changesets, fn changeset ->
      case fetch_change(changeset, :name) do
        {:ok, _} -> 
          Enum.map(fetch_change!(changeset, :species_ids), &(one_set.(changeset, &1)))
        _ ->
          []
      end
    end)
  end

  defp make_multi(changesets, institution) do
    reducer = fn attrs, multi ->
      Multi.insert(multi,
        {attrs.name, attrs.species_id},
        Schemas.Procedure.changeset(%Schemas.Procedure{}, attrs),
        Sql.multi_opts(institution))
    end

    changesets
    |> unfold_to_attrs 
    |> Enum.reduce(Multi.new, reducer)
  end

  defp transfer_multi_error( {name, _id}, %{errors: [name: {msg, _}]}, changesets) do
    index = Enum.find_index(changesets, fn changeset ->
      changeset.changes.name == name
    end)
    
    changesets
    |> List.update_at(index, &(add_error(&1, :name, msg)))
  end
end