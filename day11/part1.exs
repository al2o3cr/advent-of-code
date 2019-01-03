defmodule PowerGrid do
  @serial_number 8868
  @grid_size 300

  # Test case 1: {{33, 45}, 29}
  # @serial_number 18
  # @grid_size 300

  # Test case 2: {{21, 61}, 30}
  # @serial_number 42
  # @grid_size 300

  def power_level({x, y}) do
    rack_id = x + 10
    initial_level = rack_id * (rack_id * y + @serial_number)
    hundreds_digit(initial_level) - 5
  end

  defp hundreds_digit(n) do
    rem(div(n, 100), 10)
  end

  def display(stream) do
    data = Map.new(stream)
    Stream.each(indexes(), fn (y) ->
      Stream.each(indexes(), fn(x) ->
        sign = if data[{x, y}] < 0, do: "-", else: " "
        IO.write "#{sign}#{abs(data[{x,y}])} "
      end)
      |> Stream.run()
      IO.puts ""
    end)
    |> Stream.run()
  end

  def coordinates() do
    indexes()
    |> Stream.flat_map(fn (x) ->
      Stream.map(indexes(), fn (y) ->
        {x, y}
      end)
    end)
  end

  def power_levels() do
    Stream.map(coordinates(), &{&1, power_level(&1)})
  end

  def square_totals(s) do
    [{0,0},{0,1},{0,2},{1,0},{1,1},{1,2},{2,0},{2,1},{2,2}]
    |> Enum.map(&delay(s, &1))
    |> Stream.zip()
    |> Stream.map(&square_sum/1)
  end

  defp square_sum({{{x, y}, v1}, {_,v2}, {_,v3}, {_,v4}, {_,v5}, {_,v6}, {_,v7}, {_,v8}, {_,v9}}) do
    {{x, y}, v1+v2+v3+v4+v5+v6+v7+v8+v9}
  end

  def find_max(s) do
    Enum.max_by(s, &elem(&1, 1))
  end

  def delay(s, {0, 0}), do: s
  def delay(s, {0, y}) do
    delay_one_row(s) |> delay({0, y-1})
  end
  def delay(s, {x, y}) do
    delay_one_column(s) |> delay({x-1, y})
  end

  def delay_one_row(s) do
    Stream.flat_map(s, fn ({{x, y}, v}) ->
      case y do
        1 ->
          []
        @grid_size ->
          [{{x, @grid_size-1}, v}, {{x, @grid_size}, 0}]
        _ ->
          [{{x, y-1}, v}]
      end
    end)
  end

  def delay_one_column(s) do
    Stream.flat_map(s, fn ({{x, y}, v}) ->
      case {x, y} do
        {@grid_size, @grid_size} ->
          empty = indexes() |> Stream.map(&{{@grid_size, &1},0})
          Stream.concat([{{@grid_size-1, @grid_size}, v}], empty)
        {1, _} ->
          []
        _ -> [{{x-1, y}, v}]
      end
    end)
  end

  # def delay_one_row(s) do
  #   Stream.flat_map(s, fn ({{x, y}, v}) ->
  #     case y do
  #       1 ->
  #         [{{x, 1}, 0}, {{x, 2}, v}]
  #       @grid_size ->
  #         []
  #       _ ->
  #         [{{x, y+1}, v}]
  #     end
  #   end)
  # end

  # def delay_one_column(s) do
  #   Stream.flat_map(s, fn ({{x, y}, v}) ->
  #     case {x, y} do
  #       {1, 1} ->
  #         indexes()
  #         |> Stream.map(&{{1, &1},0})
  #         |> Stream.concat([{{2, 1}, v}])
  #       {@grid_size, _} ->
  #         []
  #       _ -> [{{x+1, y}, v}]
  #     end
  #   end)
  # end

  defp indexes() do
    1..@grid_size
  end
end

# PowerGrid.power_levels() |> PowerGrid.square_totals() |> PowerGrid.display()
PowerGrid.power_levels() |> PowerGrid.square_totals() |> PowerGrid.find_max() |> IO.inspect()
