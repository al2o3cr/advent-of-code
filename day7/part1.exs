defmodule InsnSorter do
  def parse_one(line) do
    [req, for_step] = Regex.run(~r/Step (\w) must be finished before step (\w) can begin./, line, capture: :all_but_first)
    {for_step, req}
  end

  def add_dependency(g, {for_step, req}) do
    update_deps(g, req, &(&1))
    update_deps(g, for_step, &MapSet.put(&1, req))
  end

  def next_available(g) do
    :ets.foldl(&do_next_available/2, nil, g)
  end

  def satisfy(g, key) do
    :ets.delete(g, key)
    Enum.each(all_vertexes(g), &remove_dep(g, &1, key))
  end

  def deps_for(g, key) do
    case :ets.lookup(g, key) do
      [{^key, deps}] -> deps
      [] -> MapSet.new()
    end
  end

  def update_deps(g, key, fun) do
    new_deps = fun.(deps_for(g, key))
    :ets.insert(g, {key, new_deps})
  end

  def any_vertexes(g) do
    :ets.first(g) != :"$end_of_table"
  end

  def solve(g, vertexes \\ []) do
    if any_vertexes(g) do
      nv = next_available(g)
      satisfy(g, nv)
      solve(g, [nv | vertexes])
    else
      Enum.reverse(vertexes)
    end
  end

  defp do_next_available({key, deps}, nil) do
    if MapSet.size(deps) == 0 do
      key
    else
      nil
    end
  end
  defp do_next_available({_k, _d}, acc), do: acc

  defp all_vertexes(g) do
    :ets.foldr(&[elem(&1, 0) | &2], [], g)
  end

  defp remove_dep(g, key, to_remove) do
    update_deps(g, key, &MapSet.delete(&1, to_remove))
  end
end

g = :ets.new(InsnSorter, [:ordered_set])

IO.stream(:stdio, :line)
|> Stream.map(&InsnSorter.parse_one/1)
|> Stream.each(&InsnSorter.add_dependency(g, &1))
|> Stream.run()

:ets.foldl(fn ({k, v}, _) -> IO.inspect(v, label: k) end, [], g)

InsnSorter.solve(g) |> Enum.join("") |> IO.inspect()
