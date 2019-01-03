defmodule StarMessage do
  defmodule Point do
    import Kernel, except: [min: 2, max: 2]

    defstruct [:x, :y]

    def new(x, y), do: %Point{x: x, y: y}

    def min(%Point{}=p1, %Point{}=p2) do
      new(Kernel.min(p1.x, p2.x), Kernel.min(p1.y, p2.y))
    end

    def min(points) do
      Enum.reduce(points, &min/2)
    end

    def max(%Point{}=p1, %Point{}=p2) do
      new(Kernel.max(p1.x, p2.x), Kernel.max(p1.y, p2.y))
    end

    def max(points) do
      Enum.reduce(points, &max/2)
    end

    def add(%Point{x: x1, y: y1}, %Point{x: x2, y: y2}) do
      new(x1+x2, y1+y2)
    end

    def sub(%Point{x: x1, y: y1}, %Point{x: x2, y: y2}) do
      new(x1-x2, y1-y2)
    end

    def scale(%Point{x: x, y: y}, a) do
      new(x*a, y*a)
    end

    def abs2(%Point{x: x, y: y}) do
      x*x + y*y
    end
  end

  defmodule Rect do
    defstruct [:min, :max]

    def new(%Point{}=p), do: new(p, p)
    def new(p1, p2) do
      %Rect{min: p1, max: p2}
    end

    def add_bound(%Point{}=p1, p2) do
      add_bound(new(p1), p2)
    end
    def add_bound(%Rect{min: p1, max: p2}, %Point{} = p_new) do
      points = [p1, p2, p_new]
      new(Point.min(points), Point.max(points))
    end

    def size(%Rect{min: p1, max: p2}) do
      Point.sub(p2, p1)
    end
  end

  defmodule Star do
    defstruct [:p, :v]

    @format ~r/position=<\s*(-?\d+),\s*(-?\d+)> velocity=<\s*(-?\d+),\s*(-?\d+)>/

    def parse(line) do
      [x, y, v_x, v_y] = Regex.run(@format, line, capture: :all_but_first) |> Enum.map(&String.to_integer/1)
      %Star{p: Point.new(x, y), v: Point.new(v_x, v_y)}
    end

    def at(%Star{p: p, v: v}, t) do
      Point.add(p, Point.scale(v, t))
    end
  end

  def at(stars, t) do
    star_stream(stars, t)
  end

  def bounding_box_at(stars, t) do
    star_stream(stars, t)
    |> Enum.reduce(&Rect.add_bound(&2, &1))
  end

  defp star_stream(stars, t) do
    stars
    |> Task.async_stream(&Star.at(&1, t))
    |> Stream.map(&elem(&1, 1))
  end
end

stars =
  IO.stream(:stdio, :line)
  |> Stream.map(&String.trim/1)
  |> Stream.map(&StarMessage.Star.parse/1)
  |> Enum.to_list()

t = 0..1_000_000_000_000
|> Stream.map(&StarMessage.bounding_box_at(stars, &1))
|> Stream.map(&StarMessage.Rect.size/1)
|> Stream.map(&StarMessage.Point.abs2/1)
|> Stream.transform(1_000_000_000_000, fn (n, current_min) ->
  if n > current_min do
    {:halt, n}
  else
    {[n], n}
  end
end)
|> Enum.to_list()
|> length()
|> IO.inspect(label: "time+1")

StarMessage.at(stars, t-1)
|> Stream.each(&IO.puts("#{&1.x}, #{-&1.y}"))
|> Stream.run()
