defmodule HelloDistributedWeb.PageJSON do
  @moduledoc """
  JSON rendering for PageController.
  """

  def home(%{message: message, node: node, timestamp: timestamp}) do
    %{
      message: message,
      node: node,
      timestamp: timestamp
    }
  end

  def counter(%{count: count, node: node}) do
    %{
      count: count,
      node: node
    }
  end

  def nodes(%{current_node: current, connected_nodes: connected, all_nodes: all, total: total}) do
    %{
      current_node: current,
      connected_nodes: connected,
      all_nodes: all,
      total_nodes: total
    }
  end
end
