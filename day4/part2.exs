defmodule GuardSleeping do
  defmodule Event do
    defstruct [:action, :date, :guard, :hour, :minute]

    def regex do
      ~r/\[1518-(?<date>\d{2}-\d{2}) (?<hour>\d{2}):(?<minute>\d{2})\] (?:Guard #(?<guard>\d+) )?(?<action>begins shift|wakes up|falls asleep)/
    end

    def from_map(map) do
      atomized = for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
      struct(Event, atomized)
    end

    def round_up(%Event{date: date, hour: "23"} = event) do
      %{event | hour: "00", minute: "00", date: next_date(date) }
    end
    def round_up(%Event{} = event), do: event

    defp next_date(date) do
      [month, day] = String.split(date, "-")
      new_day = String.to_integer(day) + 1
      "#{month}-#{String.pad_leading(Integer.to_string(new_day), 2, "0")}"
    end

    def fill_guard(%Event{action: "begins shift", guard: guard} = event, _current_guard) do
      {[event], guard}
    end

    def fill_guard(%Event{} = event, current_guard) do
      {[%{event | guard: current_guard}], current_guard}
    end
  end

  defmodule Day do
    defstruct [:date, :guard, :sleeping]

    def from_group(group) do
      %{base_day(group) | sleeping: sleeping_days(group, MapSet.new())}
    end

    defp base_day([event | _rest]) do
      %Day{date: event.date, guard: event.guard}
    end

    defp sleeping_days(events, acc, last_minute \\ 0, sleeping \\ false)
    defp sleeping_days([], acc, _, _), do: acc
    defp sleeping_days([%Event{action: "begins shift", minute: arrival} | rest], acc, _, false) do
      sleeping_days(rest, acc, arrival, false)
    end
    defp sleeping_days([%Event{action: "falls asleep", minute: sleeps} | rest], acc, _, false) do
      sleeping_days(rest, acc, sleeps, true)
    end
    defp sleeping_days([%Event{action: "wakes up", minute: wakes} | rest], acc, last_minute, true) do
      days = String.to_integer(last_minute)..String.to_integer(wakes)-1
      new_acc = Enum.reduce(days, acc, &(MapSet.put(&2, &1)))
      sleeping_days(rest, new_acc, wakes, false)
    end

    def to_row(%Day{} = from) do
      padded_guard = String.pad_leading(from.guard, 6, " ")
      "#{from.date} #{padded_guard} #{format_sleeping(from.sleeping)}"
    end
    def to_rows(days) do
      Enum.map(days, &to_row/1)
    end

    defp format_sleeping(sleeping) do
      (0..59)
      |> Enum.map(&(MapSet.member?(sleeping, &1)))
      |> Enum.map(&((&1 && "#") || "."))
      |> Enum.join()
    end

    def count_sleeps(%Day{sleeping: sleeping}) do
      MapSet.size(sleeping)
    end

    def sleeping_at?(%Day{sleeping: sleeping}, minute) do
      MapSet.member?(sleeping, minute)
    end
  end

  def event_stream do
    input_stream()
    |> Stream.map(&to_event/1)
  end

  defp input_stream do
    IO.stream(:stdio, :line)
  end

  defp to_event(line) do
    Regex.named_captures(Event.regex(), line)
    |> Event.from_map()
  end

  def count_sleeps(days) do
    days
    |> Enum.map(&Day.count_sleeps/1)
    |> Enum.sum()
  end

  def most_frequent_sleep(days) do
    (0..59)
    |> Enum.map(&count_sleeping_on(days, &1))
    |> Enum.max_by(&elem(&1, 1))
  end

  defp count_sleeping_on(days, minute) do
    {minute, Enum.count(days, &MapSet.member?(&1.sleeping, minute))}
  end
end

days_by_guard =
  GuardSleeping.event_stream
  |> Stream.transform("", &GuardSleeping.Event.fill_guard/2)
  |> Stream.map(&GuardSleeping.Event.round_up/1)
  |> Stream.chunk_by(&(&1.date))
  |> Stream.map(&GuardSleeping.Day.from_group/1)
  |> Enum.group_by(&(&1.guard))

{sleepy_guard, {minute, count}} =
  days_by_guard
  |> Enum.map(&{elem(&1,0), GuardSleeping.most_frequent_sleep(elem(&1,1))})
  |> Enum.max_by(fn {_, {_, n}} -> n end)

IO.puts "Guard #{sleepy_guard}, minute #{minute}, count #{count}"
