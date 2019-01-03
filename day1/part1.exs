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
end

result = IO.stream(:stdio, :line) |> Enum.reduce(0, &FrequencyTracker.tracker/2)
IO.puts "final frequency: #{result}"
