defmodule CritWeb.Usables.AnimalController.BulkCreationTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Usables.FieldConverters.ToNameList
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.Animal
  alias CritWeb.Audit
  alias Crit.Exemplars

  setup :logged_in_as_usables_manager

  describe "request the bulk creation form" do
    test "renders form", %{conn: conn} do
      conn
      |> get_via_action(:bulk_create_form)
      |> assert_purpose(form_for_creating_new_animal())
      |> assert_user_sees(@today)
      |> assert_user_sees(@never)
      |> assert_user_sees(@bovine)
    end
  end

  describe "bulk create animals" do
    setup do
      act = fn conn, params ->
        post_to_action(conn, :bulk_create, under(:bulk_animal, params))
      end
      [act: act]
    end

    setup do
      # It's relatively easy to accidentally put persistent data into
      # the test database, so this checks for that
      assert SqlX.all_ids(Animal) == []
      []
    end

    test "success case", %{conn: conn, act: act} do
      {names, params} = bulk_creation_params()
      conn = act.(conn, params)
      
      assert_purpose conn, displaying_animal_summaries()

      assert length(SqlX.all_ids(Animal)) == length(names)
      assert_user_sees(conn, Enum.at(names, 0))
      assert_user_sees(conn, Enum.at(names, -1))
    end

    test "renders errors when data is invalid", %{conn: conn, act: act} do
      {_names, params} = bulk_creation_params()

      bad_params = Map.put(params, "names", " ,     ,")

      act.(conn, bad_params)
      |> assert_purpose(form_for_creating_new_animal())

      # error messages
      |> assert_user_sees(ToNameList.no_names_error_message())
      # Fields retain their old values.
      |> assert_user_sees(bad_params["names"])
    end

    test "an audit record is created", %{conn: conn, act: act} do
      {_names, params} = bulk_creation_params()
      conn = act.(conn, params)

      {:ok, audit} = latest_audit_record(conn)

      ids = SqlX.all_ids(Animal)
      typical_animal = AnimalApi.updatable!(hd(ids), @institution)

      assert audit.event == Audit.events.created_animals
      assert audit.event_owner_id == user_id(conn)
      assert audit.data.ids == ids
      assert audit.data.in_service_date == typical_animal.in_service_date
      assert audit.data.out_of_service_date == typical_animal.out_of_service_date
    end
  end

  defp bulk_creation_params() do
    {in_service_datestring, out_of_service_datestring} = Exemplars.Date.date_pair()
    namelist = Factory.unique_names()

    params = %{"names" => Factory.names_to_input_string(namelist),
               "species_id" => Factory.some_species_id,
               "in_service_datestring" => in_service_datestring,
               "out_of_service_datestring" => out_of_service_datestring
              }

    {namelist, params}
  end
  
end