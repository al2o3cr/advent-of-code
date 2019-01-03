defmodule ClaimParser do
  defmodule Claim do
    defstruct [:id, :left, :top, :width, :height]
  end

  def parse(claim_string) do
    [id, left, top, width, height] = Regex.run(~r/#(\d+) @ (\d+),(\d+): (\d+)x(\d+)/, claim_string, capture: :all_but_first)

    %Claim{
      id: String.to_integer(id),
      left: String.to_integer(left),
      top: String.to_integer(top),
      width: String.to_integer(width),
      height: String.to_integer(height)
    }
  end

  def to_squares(claim) do
    Stream.flat_map(0..claim.width-1, fn xoff ->
      Stream.map(0..claim.height-1, fn yoff ->
        [{claim.left + xoff, claim.top + yoff}, claim.id]
      end)
    end)
  end
end

filename = hd(System.argv())
{:ok, device} = File.open(filename, [:read])
claims = IO.stream(device, :line)
         |> Stream.map(&String.trim/1)
         |> Stream.map(&ClaimParser.parse/1)
         |> Stream.flat_map(&ClaimParser.to_squares/1)
         |> Enum.reduce(%{}, fn [sq, id], acc ->
           Map.update(acc, sq, MapSet.new([id]), &(MapSet.put(&1, id)))
         end)
         |> Map.values()

all_ids = claims
         |> Enum.reduce(&MapSet.union/2)

double_covered = claims
         |> Enum.filter(&(MapSet.size(&1) > 1))
         |> Enum.reduce(&MapSet.union/2)

only_once = MapSet.difference(all_ids, double_covered)

IO.inspect(only_once)

