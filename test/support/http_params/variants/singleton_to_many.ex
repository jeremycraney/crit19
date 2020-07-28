defmodule Crit.Params.Variants.SingletonToMany do
  @moduledoc """
  A builder for controller params of this form:

  %{
    "0" => %{..., "split_field" => ...}},
    "1" => %{..., "split_field" => ...}},
    ...
  }

  A controller will typically receive N indexed parameters. For tests 
  using this module, only a single value is sent (with an index of "0").
  
  A further wrinkle is that the *split field* is used to produce separate copies
  of all the fields. For example, the split field might be a list of
  integers representing ids from a set of checkboxes. See `OneToMany` for more.

  Note: This builder will also insert an "index" field into each exemplars
  params. For example, a multi-exemplar set of params will look like this:

    %{
     "0" => %{
       "frequency_id" => "1",
       "index" => "0",              ## <<<---
       "name" => ""
     },
     "1" => %{
       "frequency_id" => "1",
       "index" => "1",              ## <<<---
       "name" => "",
       "species_ids" => ["1"]
     },
     "2" => %{
       "frequency_id" => "2",
       "index" => "2",              ## <<<---
       "name" => "valid",
       "species_ids" => ["1"]
     }

  That should work fine even if your schema doesn't include such
  an index. It should be thrown away by `Changeset.cast`. However,
  if you don't want it, just change the call to `Get.doubly_numbered_params`
  below into a call to `Get.numbered_params`.
  """

  defmacro __using__(_) do
    quote do
      use Crit.Params.Variants.Common
      alias Crit.Params.Get
      alias Crit.Params.Validation

      # ----------------------------------------------------------------------------

      defp make_params_for_name(config, name),
        do: Get.doubly_numbered_params(config(), [name], "index")

      def that_are(descriptors) when is_list(descriptors) do
        Get.doubly_numbered_params(config(), descriptors, "index")
      end
  
      def that_are(descriptor),       do: that_are([descriptor])
      def that_are(descriptor, opts), do: that_are([[descriptor | opts]])
    end
  end  
end
