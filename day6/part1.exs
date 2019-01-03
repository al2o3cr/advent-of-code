defmodule SafeDistance do
  defmodule Point do
    defstruct [:x, :y]

    def new([x, y]) do
      %Point{x: String.to_integer(x), y: String.to_integer(y)}
    end

    def distance(%Point{x: x1, y: y1}, %Point{x: x2, y: y2}) do
      abs(x1-x2) + abs(y1-y2)
    end

    def edge?(%Point{}=p, %Point{}=bound) do
      p.x == 0 || p.y == 0 || p.x >= bound.x || p.y >= bound.y
    end

    def pmax(%Point{}=a, %Point{}=b) do
      %Point{x: max(a.x, b.x), y: max(a.y, b.y)}
    end

    def zero do
      %Point{x: 0, y: 0}
    end

    def all(%Point{}=bound) do
      0..bound.x
      |> Stream.flat_map(fn (x) -> Stream.map(0..bound.y, &%Point{x: x, y: &1}) end)
    end
  end

  defmodule Area do
    defstruct [:n, :infinite, :bound]

    def new(%Point{}=bound) do
      %Area{n: 0, infinite: false, bound: bound}
    end

    def add(%Area{infinite: true}=a, _), do: a
    def add(%Area{n: n, bound: bound}=a, %Point{}=p) do
      if Point.edge?(p, bound) do
        %{a | n: 0, infinite: true}
      else
        %{a | n: n+1}
      end
    end
  end

  def points do
    IO.stream(:stdio, :line)
      |> Stream.map(&String.trim/1)
      |> Stream.map(&String.split(&1, ", "))
      |> Stream.map(&SafeDistance.Point.new/1)
      |> Enum.to_list()
  end
end

points = SafeDistance.points()

bound = Enum.reduce(points, SafeDistance.Point.zero(), &SafeDistance.Point.pmax/2)

areas = Map.new(points, &{&1, SafeDistance.Area.new(bound)})

nearest = fn (p) ->
  [first, second | _] =
    points
    |> Enum.map(&{&1, SafeDistance.Point.distance(p, &1)})
    |> Enum.sort_by(&elem(&1,1))

  if elem(first,1) == elem(second,1) do
    nil
  else
    elem(first,0)
  end
end

SafeDistance.Point.all(bound)
|> Stream.map(&{&1, nearest.(&1)})
|> Enum.reduce(areas, fn
                 {_, nil}, acc -> acc
                 {p, target}, acc ->
                   Map.update!(acc, target, &SafeDistance.Area.add(&1, p))
end)
|> Enum.reject(&(elem(&1,1).infinite))
|> Enum.max_by(&(elem(&1,1).n))
|> IO.inspect()
