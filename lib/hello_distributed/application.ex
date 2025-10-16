defmodule HelloDistributed.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Configure libcluster topology
    topologies = [
      peers: [
        strategy: HelloDistributed.ClusterStrategy,
        config: [
          polling_interval: 5_000
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
