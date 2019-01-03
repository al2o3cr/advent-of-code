defmodule CharCounter do
  def to_chars(box_id) do
    box_id
    |> String.trim()
    |> String.to_charlist()
  end

  def to_counts(chars) do
    List.foldl(chars, %{}, fn char, seen -> Map.update(seen, char, 1, &(&1+1)) end)
  end

  def has_twos?(counts) do
    counts |> Map.values() |> Enum.any?(&(&1 == 2))
  end

  def has_threes?(counts) do
    counts |> Map.values() |> Enum.any?(&(&1 == 3))
  end

  def total_counts({false, false}, acc), do: acc
  def total_counts({false, true}, {twos, threes}), do: {twos, threes+1}
  def total_counts({true, false}, {twos, threes}), do: {twos+1, threes}
  def total_counts({true, true}, {twos, threes}), do: {twos+1, threes+1}
end

filename = hd(System.argv())
{:ok, device} = File.open(filename, [:read])
{twos, threes} = IO.stream(device, :line)
         |> Stream.map(&CharCounter.to_chars/1)
         |> Stream.map(&CharCounter.to_counts/1)
         |> Stream.map(&{CharCounter.has_twos?(&1), CharCounter.has_threes?(&1)})
         |> Stream.scan({0,0}, &CharCounter.total_counts/2)
         |> Stream.take(-1)
         |> Enum.to_list()
         |> List.first()

IO.puts "checksum: #{twos * threes}"
