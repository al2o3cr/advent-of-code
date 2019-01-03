defmodule InsnSorter do
  def parse_one(line) do
    [req, for_step] = Regex.run(~r/Step (\w) must be finished before step (\w) can begin./, line, capture: :all_but_first)
    {for_step, req}
  end

  def add_dependency(g, {for_step, req}) do
    :digraph.add_vertex(g, for_step)
    :digraph.add_vertex(g, req)
    :digraph.add_edge(g, req, for_step)
  end
end

g = :digraph.new()

IO.stream(:stdio, :line)
|> Stream.map(&InsnSorter.parse_one/1)
|> Stream.each(&InsnSorter.add_dependency(g, &1))
|> Stream.run()

if path = :digraph_utils.topsort(g) do
  IO.inspect path
else
  IO.puts "cycles detected"
end
