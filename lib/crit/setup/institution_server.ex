defmodule Crit.Setup.InstitutionServer do
  use GenServer
  alias Crit.Sql.RouteToSchema
  alias Crit.Setup.HiddenSchemas.Species
  alias Crit.Setup.InstitutionApi

  defstruct institution: nil, router: nil, species: []
  

  def server(short_name), do: String.to_atom(short_name)

  def start_link(institution),
    do: GenServer.start_link(__MODULE__, institution,
          name: server(institution.short_name))

  # Server part

  @impl true
  def init(institution) do
    {:ok, new_state(institution)}
  end

  @impl true
  def handle_call(:raw, _from, state) do
    {:reply, state.institution, state}
  end

  @impl true
  def handle_call(:time_slots, _from, state) do
    tuples = 
      state.institution.time_slots
      |> Enum.map(fn %{name: name, id: id} -> {name, id} end)
    {:reply, tuples, state}
  end

  @impl true
  def handle_call({:time_slot_by_id, slot_id}, _from, state) do
    result = 
      state.institution.time_slots
      |> IO.inspect
      |> Enum.find(fn slot -> slot.id == slot_id end)
    {:reply, {:ok, result}, state}
  end

  

  @impl true
  def handle_call(:available_species, _from, state) do
    {:reply, state.species, state}
  end

  @impl true
  def handle_call(:reload, _from, state) do
    short_name = state.institution.short_name
    new_institution = InstitutionApi.one!(short_name: short_name)
    {:reply, :ok, new_state(new_institution)}
  end

  @impl true
  def handle_call({:multi_opts, given_opts}, _from, state) do
    retval = state.router.multi_opts(given_opts, state.institution)
    {:reply, retval, state}
  end

  @impl true
  def handle_call({:sql, sql_command, all_but_last_arg, given_opts}, _from, state) do
    retval =
      state.router.forward(sql_command, all_but_last_arg, given_opts,
        state.institution)
    {:reply, retval, state}
  end
  

  # Util
  defp new_state(institution) do
    router = if institution.prefix, do: RouteToSchema, else: RouteToRepo
    species =
      router.forward(:all, [Species.Query.ordered()], [], institution)
      |> Enum.map(fn %Species{name: name, id: id} -> {name, id} end)

    %__MODULE__{institution: institution, router: router, species: species}
  end

  
end
