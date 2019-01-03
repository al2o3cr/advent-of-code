defmodule InsnSorter do

  defmodule WorkerSet do
    def new(n) do
      List.duplicate({}, n)
    end

    def any_complete?(workers, now) do
      Enum.any?(workers, &complete?(&1, now))
    end

    def any_free?(workers) do
      Enum.any?(workers, &free?/1)
    end

    def pop_completes(workers, t) do
      get_and_update_in(workers, [Access.filter(&complete?(&1, t))], &{elem(&1, 0), {}})
    end

    def schedule(workers, key, complete_at) do
      free_worker = Enum.find_index(workers, &free?/1)
      List.replace_at(workers, free_worker, {key, complete_at})
    end

    def complete?({_, t}, t), do: true
    def complete?(_, _), do: false

    def free?({}), do: true
    def free?(_), do: false

    def duration(task) do
      List.first(String.to_charlist(task)) - 65 + 61
    end

    def final_completion(workers) do
      Enum.max_by(workers, &completion_time/1)
    end

    defp completion_time({_, t}), do: t
    defp completion_time({}), do: -1
  end

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

  def no_vertexes(g) do
    !any_vertexes(g)
  end

  def solve(g, workers, t \\ 0) do
    cond do
      no_vertexes(g) ->
        WorkerSet.final_completion(workers)
      WorkerSet.any_complete?(workers, t) ->
        {completed, new_workers} = WorkerSet.pop_completes(workers, t)
        Enum.each(completed, &satisfy(g, &1))
        solve(g, new_workers, t)
      WorkerSet.any_free?(workers) ->
        next = next_available(g)
        if next do
          IO.puts("starting #{next} at #{t}")
          :ets.delete(g, next)
          complete_at = t + WorkerSet.duration(next)
          new_workers = WorkerSet.schedule(workers, next, complete_at)
          solve(g, new_workers, t)
        else
          solve(g, workers, t+1)
        end
      true ->
        solve(g, workers, t+1)
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

workers = InsnSorter.WorkerSet.new(5)

InsnSorter.solve(g, workers) |> IO.inspect()
