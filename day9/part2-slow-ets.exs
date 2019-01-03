defmodule Circle do
  defstruct current_idx: 0, marbles: nil, scores: nil, current_player: 0, max_marbles: 0, max_players: 0, marble_count: 0

  def step(circle, new_marble) when rem(new_marble, 23) == 0 do
    new_index = Integer.mod(circle.current_idx - 7, circle.marble_count)
    new_current_player = rem(circle.current_player+1, circle.max_players)

    [removed_marble] = :ets.select(circle.marbles, at_pos_ms(new_index))
    :ets.delete(circle.marbles, removed_marble)
    :ets.select_replace(circle.marbles, bump_elements_after_ms(new_index, -1))

    :ets.update_counter(circle.scores, circle.current_player, {2, removed_marble + new_marble})

    %{ circle | current_idx: new_index, current_player: new_current_player, marble_count: circle.marble_count - 1 }
  end

  def step(circle, new_marble) do
    new_index = Integer.mod(circle.current_idx + 1, circle.marble_count)+1
    new_current_player = rem(circle.current_player+1, circle.max_players)

    :ets.select_replace(circle.marbles, bump_elements_after_ms(new_index, 1))
    :ets.insert(circle.marbles, {new_marble, new_index})

    %{ circle | current_idx: new_index, current_player: new_current_player, marble_count: circle.marble_count + 1 }
  end

  def run(max_marbles, max_players) do
    marbles = :ets.new(Circle.Marbles, [:set])
    :ets.insert(marbles, {0, 0})

    scores = :ets.new(Circle.Scores, [:set])
    Enum.each(0..max_players-1, &:ets.insert(scores, {&1, 0}))
    Enum.reduce(1..max_marbles, %Circle{marbles: marbles, scores: scores, max_marbles: max_marbles, max_players: max_players, marble_count: 1}, &Circle.step(&2, &1))
  end

  def max_score(circle) do
    :ets.select(circle.scores, just_second_ms())
    |> Enum.max()
  end

  def in_order(circle) do
    data = :ets.tab2list(circle.marbles)
    max_position = get_in(data, [Access.all(), Access.elem(1)]) |> Enum.max()
    result = List.duplicate(nil, max_position+1)
    Enum.reduce(data, result, &List.replace_at(&2, elem(&1, 1), elem(&1, 0)))
  end

  defp bump_elements_after_ms(target, offset) do
    # :ets.fun2ms(fn {key, pos} when pos >= target -> {key, pos+offset} end)
    [{{:"$1", :"$2"}, [{:>=, :"$2", target}], [{{:"$1", {:+, :"$2", offset}}}]}]
  end

  defp at_pos_ms(position) do
    # :ets.fun2ms(fn {key, pos} when pos == position -> key end)
    [{{:"$1", :"$2"}, [{:==, :"$2", position}], [:"$1"]}]
  end

  defp just_second_ms() do
    [{{:"$1", :"$2"}, [true], [:"$2"]}]
  end
end

max_marbles = 71305
player_count = 479

# cases = [
# %{players: 9, marbles: 1..25, expected: 32},
# %{players: 10, marbles: 1..1618, expected: 8317},
# %{players: 13, marbles: 1..7999, expected: 146373},
# %{players: 17, marbles: 1..1104, expected: 2764},
# %{players: 21, marbles: 1..6111, expected: 54718},
# %{players: 30, marbles: 1..5807, expected: 37305},
# %{players: 479, marbles: 1..71305, expected: "output"} # TODO: 368702 is too high
# ]

circle = Circle.run(max_marbles, player_count)
IO.inspect(Circle.max_score(circle))
