defmodule Ash.Api.Transformers.ValidateManyToManyJoinAttributes do
  @moduledoc """
  Validates that `join_attributes` on many to many relationships exist on the join resource
  """
  use Ash.Dsl.Transformer

  @impl true
  def after_compile?, do: true

  @impl true
  def after?(Ash.Api.Transformers.EnsureResourcesCompiled), do: true
  def after?(_), do: false

  @impl true
  def transform(api, dsl) do
    api
    |> Ash.Api.resources()
    |> Enum.each(fn resource ->
      resource
      |> Ash.Resource.Info.relationships()
      |> Enum.filter(&(&1.type == :many_to_many && &1.join_attributes != []))
      |> Enum.each(&validate_relationship/1)
    end)

    {:ok, dsl}
  end

  defp validate_relationship(relationship) do
    through_attributes =
      relationship.through
      |> Ash.Resource.Info.attributes()
      |> Enum.map(& &1.name)

    for join_attribute <- relationship.join_attributes do
      unless join_attribute in through_attributes do
        raise Ash.Error.Dsl.DslError,
          module: __MODULE__,
          path: [:relationships, relationship.name],
          message:
            "Relationship `#{relationship.name}` expects join_attribute `#{join_attribute}` to be defined on the `through` resource #{inspect(relationship.through)}"
      end
    end
  end
end
