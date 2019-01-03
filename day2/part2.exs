defmodule GroupStrings do
end

filename = hd(System.argv())
{:ok, device} = File.open(filename, [:read])
lines = IO.stream(device, :line) |> Stream.map(&String.trim/1) |> Enum.to_list()

max_length = List.first(lines) |> String.length()

found = Enum.flat_map(1..max_length-2, fn target ->
  lines
  |> Enum.group_by(&{String.slice(&1, 0, target), String.slice(&1, target+1, max_length - target - 1)})
  |> Map.to_list()
  |> Enum.reject(&(length(elem(&1, 1)) == 1))
  |> Enum.map(&elem(&1, 0))
  |> Enum.map(&(elem(&1, 0) <> elem(&1, 1)))
end)

IO.inspect(found)

#          |> Stream.map(&CharCounter.to_chars/1)
#          |> Stream.map(&CharCounter.to_counts/1)
#          |> Stream.map(&{CharCounter.has_twos?(&1), CharCounter.has_threes?(&1)})
#          |> Stream.scan({0,0}, &CharCounter.total_counts/2)
#          |> Stream.take(-1)
#          |> Enum.to_list()
#          |> List.first()
#
# IO.puts "checksum: #{twos * threes}"
