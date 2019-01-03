defmodule PolymerReducer do
  def regex do
    {:ok, result} =
      ?a..?z
      |> Enum.map(&to_string([&1, &1 - 32 ]))
      |> Enum.flat_map(&[&1, String.reverse(&1)])
      |> Enum.join("|")
      |> Regex.compile()
    result
  end

  def reduce_one(string, r) do
    Regex.replace(r, string, "")
  end

  def reduce(string, r \\ nil) do
    r = r || regex()
    result = reduce_one(string, r)
    if String.length(string) == String.length(result) do
      string
    else
      reduce(result, r)
    end
  end

  def remove_element(string, element) do
    [element, ?|, element-32]
    |> to_string()
    |> Regex.compile()
    |> elem(1)
    |> Regex.replace(string, "")
  end
end

polymer = IO.read(:stdio, :line) |> String.trim()

?a..?z
|> Enum.map(&{to_string([&1]), PolymerReducer.remove_element(polymer, &1)})
|> Task.async_stream(&{elem(&1,0), PolymerReducer.reduce(elem(&1,1))}, timeout: 100000)
|> Stream.map(&elem(&1,1))
|> Stream.each(&IO.inspect(elem(&1,0)))
|> Enum.min_by(&String.length(elem(&1,1)))
|> elem(1)
|> String.length()
|> IO.inspect()
