polymer = IO.read(:stdio, :line) |> String.trim()

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
end

polymer
|> PolymerReducer.reduce()
|> String.length()
|> IO.puts()
