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

  def histogram(freq, hist) do
    Map.update(hist, freq, 1, &(&1 + 1))
  end

  def no_repeats?(hist) do
    hist |> Map.keys() |> Enum.min_max() |> IO.inspect()
    hist
    |> Map.values()
    |> Enum.all?(&(&1 <= 1))
  end
end

filename = hd(System.argv())
{:ok, device} = File.open(filename, [:read])
lines = device |> IO.stream(:line) |> Enum.to_list()
result = lines
|> Stream.cycle()
|> Stream.scan(0, &FrequencyTracker.tracker/2)
|> Stream.scan(%{0 => 1}, &FrequencyTracker.histogram/2)
|> Stream.drop_while(&FrequencyTracker.no_repeats?/1)
|> Stream.take(1)
|> Enum.to_list()
|> List.first()
|> Map.to_list()
|> Enum.find(&(elem(&1, 1) > 1))
|> elem(0)

IO.puts "final frequency: #{result}"
