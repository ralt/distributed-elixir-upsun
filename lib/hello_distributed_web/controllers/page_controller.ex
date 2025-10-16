defmodule HelloDistributedWeb.PageController do
  use HelloDistributedWeb, :controller

  def home(conn, _params) do
    node_name = Node.self()
    json(conn, %{
      message: "Hello, World from Distributed Elixir!",
      node: node_name,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  def counter(conn, _params) do
    count = HelloDistributed.DistributedCounter.get()
    json(conn, %{
      count: count,
      node: Node.self()
    })
  end

  def increment(conn, _params) do
    new_count = HelloDistributed.DistributedCounter.increment()
    json(conn, %{
      count: new_count,
      node: Node.self(),
      message: "Counter incremented"
    })
  end

  def nodes(conn, _params) do
    all_nodes = [Node.self() | Node.list()]
    json(conn, %{
      current_node: Node.self(),
      connected_nodes: Node.list(),
      all_nodes: all_nodes,
      total_nodes: length(all_nodes)
    })
  end
end
