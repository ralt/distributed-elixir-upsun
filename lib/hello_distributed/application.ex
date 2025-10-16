defmodule HelloDistributed.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @peers_file "/run/peers.json"

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
	      |> Enum.map(fn {peer, address} -> "#{extract_name(peer)}@#{address}" end)

            {:error, reason} ->
              Logger.warning("Failed to parse peers JSON from #{@peers_file}: #{inspect(reason)}")
              []
          end

        {:error, reason} ->
          Logger.warning("Failed to read peers file #{@peers_file}: #{inspect(reason)}")
          []
      end
    else
      Logger.debug("Peers file not found at #{@peers_file}")
      []
    end
  end

  defp extract_name(long_node_name) do
    String.split(long_node_name, ".") |> List.first()
  end

  @impl true
  def start(_type, _args) do
    # Configure libcluster topology
    topologies = [
      peers: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: [load_peers()]
        ]
      ]
    ]

    # Children that should run on all nodes
    # The counter uses :global registration, so only one will be active cluster-wide
    # but starting it on all nodes enables automatic failover
    children = [
      # Telemetry supervisor
      HelloDistributedWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: HelloDistributed.PubSub},
      # Start the Endpoint (http/https)
      HelloDistributedWeb.Endpoint,
      # Connect to peer nodes using libcluster
      {Cluster.Supervisor, [topologies, [name: HelloDistributed.ClusterSupervisor]]},
      # Start the distributed counter (globally registered, only one active)
      {HelloDistributed.DistributedCounter, name: HelloDistributed.DistributedCounter}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HelloDistributed.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HelloDistributedWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Private Functions
  # (is_primary_node? removed - counter now uses :global registration for automatic failover)
end
