defmodule HelloDistributed.ClusterStrategy do
  @moduledoc """
  A custom libcluster strategy that reads peer nodes from /run/peers.json.

  The JSON file format is: {"<full node name>":"IP address"}

  This strategy uses EPMD (Erlang Port Mapper Daemon) to connect to the nodes.
  The node names in the JSON file should be fully qualified (e.g., "node@host").
  """
  use Cluster.Strategy
  alias Cluster.Strategy.State
  require Logger

  @default_polling_interval 5_000
  @peers_file "/run/peers.json"

  def start_link(opts) do
    Cluster.Strategy.start_link(__MODULE__, opts)
  end

  @impl true
  def init([%State{} = state]) do
    {:ok, state, 0}
  end

  @impl true
  def handle_info(:timeout, state) do
    handle_info(:load, state)
  end

  def handle_info(:load, %State{topology: topology, connect: connect, disconnect: disconnect, list_nodes: list_nodes} = state) do
    new_nodelist = load_peers()
    removed = MapSet.difference(list_nodes.(), new_nodelist)

    Cluster.Strategy.disconnect_nodes(topology, disconnect, list_nodes, MapSet.to_list(removed))
    Cluster.Strategy.connect_nodes(topology, connect, list_nodes, MapSet.to_list(new_nodelist))

    polling_interval = Keyword.get(state.config, :polling_interval, @default_polling_interval)
    Process.send_after(self(), :load, polling_interval)

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp load_peers do
    if File.exists?(@peers_file) do
      case File.read(@peers_file) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, peers} when is_map(peers) ->
              current_node = Node.self()

              peers
              |> Map.keys()
              |> Enum.map(&String.to_atom/1)
              |> Enum.reject(&(&1 == current_node))
              |> MapSet.new()

            {:error, reason} ->
              Logger.warning("Failed to parse peers JSON from #{@peers_file}: #{inspect(reason)}")
              MapSet.new()
          end

        {:error, reason} ->
          Logger.warning("Failed to read peers file #{@peers_file}: #{inspect(reason)}")
          MapSet.new()
      end
    else
      Logger.debug("Peers file not found at #{@peers_file}")
      MapSet.new()
    end
  end
end
