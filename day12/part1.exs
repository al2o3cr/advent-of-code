defmodule Flowers do
  @window_regex ~r/(?<=([.#_$])([.#_$]))([.#_$])(?=([.#_$])([.#_$]))/

  def initial_state("initial state: " <> <<c::binary-size(1)>> <> rest) do
    to_zero(c) <> String.trim(rest)
  end

  def parse_rule(<<input::binary-size(5)>> <> " => " <> <<output::binary-size(1)>>) do
    key = input |> String.split("", trim: true) |> List.to_tuple()
    {key, output}
  end

  def lookup_fun(lookup) do
    fn (_, a, b, c, d, e) ->
      key = [a,b,c,d,e] |> Enum.map(&from_zero/1) |> List.to_tuple()
      result = Map.get(lookup, key, ".")
      if from_zero(c) == c do
        result
      else
        to_zero(result)
      end
    end
  end

  def step(s, lookup) do
    Regex.replace(@window_regex, "....." <> s <> ".....", lookup_fun(lookup))
    |> String.trim(".")
  end

  def score(s) do
    [negative, _, positive] = String.split(s, ~r/([_$])/, parts: 2, include_captures: true)
    partial_score(positive) - partial_score(String.reverse(negative))
  end

  def partial_score(s) do
    s
    |> String.codepoints()
    |> Enum.with_index(1)
    |> Enum.map(fn {c, i} -> if c == "#", do: i, else: 0 end)
    |> Enum.sum()
  end

  def to_zero(c) do
    case c do
      "#" -> "$"
      "." -> "_"
      _ -> c
    end
  end

  def from_zero(c) do
    case c do
      "$" -> "#"
      "_" -> "."
      _ -> c
    end
  end
end

# h = %{"..#" => "#"}
# s = ".#."
# s = Regex.replace(~r/(?<=([.#]))([.#])(?=([.#]))/, "." <> s <> ".", fn (_, x, y, z) -> Map.get(h, IO.inspect(x<>y<>z), ".") end)

initial_state = Flowers.initial_state(IO.read(:stdio, :line))
# skip blank line
IO.read(:stdio, :line)

lookup = IO.stream(:stdio, :line)
  |> Stream.map(&String.trim/1)
  |> Stream.map(&Flowers.parse_rule/1)
  |> Map.new()

results = Stream.iterate(initial_state, &Flowers.step(&1, lookup))

results
|> Stream.with_index()
|> Stream.each(fn {v, i} -> IO.puts("#{i}: #{Flowers.score(v)}") end)
# |> Stream.each(fn {v, i} -> IO.puts("#{i}: #{v}") end)
|> Stream.take(300)
|> Stream.run()

[two_hundred, next] = results
  |> Stream.take(202)
  |> Stream.take(-2)
  |> Stream.map(&Flowers.score/1)
  |> Enum.to_list()

diff = next - two_hundred
offset = 50_000_000_000 - 200
final = two_hundred + diff * offset

IO.inspect(final)
