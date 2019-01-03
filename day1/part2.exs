defmodule FrequencyTracker do
  def tracker("+" <> amount_string, initial_frequency) do
    initial_frequency + parse(amount_string)
  end

  def tracker("-" <> amount_string, initial_frequency) do
    initial_frequency - parse(amount_string)
  end

  defp parse(amount_string) do
    amount_string |> String.trim |> String.to_integer
  end

  def track_repeats(_, :halt), do: {:halt, nil}
  def track_repeats(el, seen) do
    if MapSet.member?(seen, el) do
      {[el], :halt}
    else
      {[], MapSet.put(seen, el)}
    end
  end
end

filename = hd(System.argv())
{:ok, device} = File.open(filename, [:read])
lines = device |> IO.stream(:line) |> Enum.to_list()
total = lines |> Enum.reduce(0, &FrequencyTracker.tracker/2)
sums = lines
|> Stream.scan(0, &FrequencyTracker.tracker/2)
|> Enum.to_list()

result = 
Stream.iterate(0, &(&1 + total))
|> Stream.flat_map(fn offset ->
  Stream.map(sums, &(&1 + offset))
end)
|> Stream.transform(MapSet.new([0]), &FrequencyTracker.track_repeats/2)
|> Enum.to_list()
|> List.first()

IO.puts "final frequency: #{result}"
