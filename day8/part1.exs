defmodule LicenseTree do
  defmodule Node do
    defstruct child_count: 0, children: [],
              metadata_count: 0, metadata: [],
              data: [], start_idx: 0, end_idx: nil

    def new(data, start_idx \\ 0) do
      %Node{
        data: data,
        start_idx: start_idx,
        end_idx: start_idx+2,
        child_count: Enum.fetch!(data, start_idx),
        metadata_count: Enum.fetch!(data, start_idx+1)
      }
      |> add_children()
      |> add_metadata()
    end

    defp add_children(node) do
      Stream.iterate(node, &do_add_child/1)
      |> Stream.take(node.child_count+1)
      |> Enum.to_list()
      |> List.last()
    end

    defp do_add_child(node) do
      child = new(node.data, node.end_idx)
      %{ node | children: node.children ++ [child], end_idx: child.end_idx }
    end

    def add_metadata(%Node{data: data, end_idx: end_idx, metadata_count: metadata_count} = node) do
      %{ node | metadata: Enum.slice(data, end_idx, metadata_count), end_idx: end_idx+metadata_count }
    end

    def traverse_stream(node) do
      Stream.concat([node], Stream.flat_map(node.children, &traverse_stream/1))
    end

    def value(%Node{child_count: 0, metadata: metadata}), do: Enum.sum(metadata)
    def value(node) do
      node.metadata
      |> Enum.map(&value_from_metadata(node, &1))
      |> Enum.sum()
    end

    def value_from_metadata(_, 0), do: 0
    def value_from_metadata(node, index) do
      case Enum.fetch(node.children, index-1) do
        {:ok, child} -> value(child)
        _ -> 0
      end
    end
  end

  def parse(data) do
    Node.new(data)
  end

  def traverse(tree) do
    Node.traverse_stream(tree)
  end
end

# {:ok, input} = File.read("test_input.txt")
{:ok, input} = File.read("input.txt")

data = input
|> String.split(" ")
|> Enum.map(&String.to_integer/1)

tree = LicenseTree.parse(data)

tree
|> LicenseTree.traverse()
|> Stream.flat_map(&(&1.metadata))
|> Enum.sum()
|> IO.inspect(label: "metadata sum")

LicenseTree.Node.value(tree) |> IO.inspect(label: "root value")
