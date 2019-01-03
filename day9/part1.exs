defmodule Circle do
  defstruct current_idx: 0, marbles: [0], scores: [], current_player: 0

  def step(circle, new_marble) when rem(new_marble, 23) == 0 do
    new_index = Integer.mod(circle.current_idx - 7, length(circle.marbles))
    new_current_player = rem(circle.current_player+1, length(circle.scores))
    {removed_marble, new_marbles} = List.pop_at(circle.marbles, new_index)
    new_scores = List.update_at(circle.scores, circle.current_player, &(&1 + new_marble + removed_marble))
    %Circle{
      current_idx: new_index,
      marbles: new_marbles,
      current_player: new_current_player,
      scores: new_scores
    }
  end

  def step(circle, new_marble) do
    new_index = Integer.mod(circle.current_idx + 1, length(circle.marbles))+1
    new_current_player = rem(circle.current_player+1, length(circle.scores))
    new_marbles = List.insert_at(circle.marbles, new_index, new_marble)
    %Circle{
      current_idx: new_index,
      marbles: new_marbles,
      current_player: new_current_player,
      scores: circle.scores
    }
  end

  def run(players, marbles) do
    Enum.reduce(marbles, %Circle{scores: List.duplicate(0, players)}, &Circle.step(&2, &1))
  end

  def max_score(circle) do
    Enum.max(circle.scores)
  end
end

cases = [
  %{players: 9, marbles: 1..25, expected: 32},
  %{players: 10, marbles: 1..1618, expected: 8317},
  %{players: 13, marbles: 1..7999, expected: 146373},
  %{players: 17, marbles: 1..1104, expected: 2764},
  %{players: 21, marbles: 1..6111, expected: 54718},
  %{players: 30, marbles: 1..5807, expected: 37305},
  %{players: 479, marbles: 1..71305, expected: "output"} # TODO: 368702 is too high
]

Enum.each(cases, fn (d) -> Circle.run(d.players, d.marbles) |> Circle.max_score() |> IO.inspect(label: d.expected) end)
