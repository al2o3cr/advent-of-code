defmodule Circle do
  defstruct current_number: 0, marbles: nil, scores: nil, current_player: 0, max_players: 0

  def step(circle, new_marble) when rem(new_marble, 23) == 0 do
    {removed_marble, removed_next, removed_prev} = offset_from(circle, circle.current_number, -7)
    {^removed_prev, _, prev_left} = lookup(circle, removed_prev)
    {^removed_next, next_right, _} = lookup(circle, removed_next)

    :ets.delete(circle.marbles, removed_marble)
    :ets.insert(circle.marbles, {removed_prev, removed_next, prev_left})
    :ets.insert(circle.marbles, {removed_next, next_right, removed_prev})

    :ets.update_counter(circle.scores, circle.current_player, {2, removed_marble + new_marble})

    new_current_player = rem(circle.current_player+1, circle.max_players)
    %{ circle | current_number: removed_next, current_player: new_current_player }
  end

  def step(circle, new_marble) do
    {val_left, _, prev_left} = offset_from(circle, circle.current_number, 1)
    {val_right, next_right, _} = offset_from(circle, circle.current_number, 2)

    :ets.insert(circle.marbles, {new_marble, val_right, val_left})
    if val_left == val_right do
      :ets.insert(circle.marbles, {val_left, new_marble, new_marble})
    else
      :ets.insert(circle.marbles, {val_left, new_marble, prev_left})
      :ets.insert(circle.marbles, {val_right, next_right, new_marble})
    end

    new_current_player = rem(circle.current_player+1, circle.max_players)
    %{ circle | current_number: new_marble, current_player: new_current_player }
  end

  def run(max_marbles, max_players) do
    marbles = :ets.new(Circle.Marbles, [:set])
    :ets.insert(marbles, {0, 0, 0})

    scores = :ets.new(Circle.Scores, [:set])
    Enum.each(0..max_players-1, &:ets.insert(scores, {&1, 0}))
    Enum.reduce(1..max_marbles, %Circle{marbles: marbles, scores: scores, max_players: max_players}, &Circle.step(&2, &1))
  end

  def max_score(circle) do
    :ets.select(circle.scores, just_second_ms())
    |> Enum.max()
  end

  def in_order(circle) do
    Stream.iterate(0, &elem(lookup(circle, &1), 1))
    |> Stream.drop(1)
    |> Stream.take_while(&(&1 > 0))
    |> Enum.to_list()
  end

  defp just_second_ms() do
    [{{:"$1", :"$2"}, [true], [:"$2"]}]
  end

  def offset_from(circle, number, 0), do: lookup(circle, number)
  def offset_from(circle, number, offset) when offset < 0 do
    prev = elem(lookup(circle, number), 2)
    offset_from(circle, prev, offset + 1)
  end
  def offset_from(circle, number, offset) when offset > 0 do
    next = elem(lookup(circle, number), 1)
    offset_from(circle, next, offset - 1)
  end

  def lookup(circle, number) do
    hd(:ets.lookup(circle.marbles, number))
  end
end

max_marbles = 7103500
player_count = 479

# cases = [
# %{players: 9, marbles: 1..25, expected: 32},
# %{players: 10, marbles: 1..1618, expected: 8317},
# %{players: 13, marbles: 1..7999, expected: 146373},
# %{players: 17, marbles: 1..1104, expected: 2764},
# %{players: 21, marbles: 1..6111, expected: 54718},
# %{players: 30, marbles: 1..5807, expected: 37305},
# %{players: 479, marbles: 1..71035, expected: 367634}
# 100x tried 3043992762, too high
# ]

circle = Circle.run(max_marbles, player_count)
IO.inspect(Circle.max_score(circle))
