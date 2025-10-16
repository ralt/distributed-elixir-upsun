defmodule HelloDistributed.DistributedCounter do
  @moduledoc """
  A distributed counter using OTP GenServer.

  This demonstrates OTP distribution by maintaining state across nodes.
  When multiple nodes are connected, they can all interact with this counter.
  """
  use GenServer

  # Client API

  def start_link(_opts) do
    # Register globally - only one process across the cluster will succeed
    case GenServer.start_link(__MODULE__, 0, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        # Another node already has the counter, ignore gracefully
        :ignore
    end
  end

  @doc """
  Get the current counter value from any node in the cluster.
  """
  def get do
    GenServer.call({:global, __MODULE__}, :get)
  end

  @doc """
  Increment the counter from any node in the cluster.
  """
  def increment do
    GenServer.call({:global, __MODULE__}, :increment)
  end

  @doc """
  Get information about all nodes in the cluster.
  """
  def cluster_info do
    all_nodes = [Node.self() | Node.list()]
    %{
      current_node: Node.self(),
      connected_nodes: Node.list(),
      all_nodes: all_nodes,
      total_nodes: length(all_nodes)
    }
  end

  # Server Callbacks

  @impl true
  def init(initial_value) do
    {:ok, initial_value}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:increment, _from, state) do
    new_state = state + 1
    {:reply, new_state, new_state}
  end

  # Private Functions
  # (find_counter_node removed - we now use {:global, __MODULE__} directly)
end
