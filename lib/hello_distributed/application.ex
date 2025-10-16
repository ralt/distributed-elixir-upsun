defmodule HelloDistributed.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Base children that should run on all nodes
    base_children = [
      # Telemetry supervisor
      HelloDistributedWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: HelloDistributed.PubSub},
      # Start the Endpoint (http/https)
      HelloDistributedWeb.Endpoint,
      # Connect to peer nodes
      HelloDistributed.PeerConnector
    ]

    # Only start the counter on the primary node to ensure single source of truth
    children = if is_primary_node?() do
      base_children ++ [{HelloDistributed.DistributedCounter, name: HelloDistributed.DistributedCounter}]
    else
      base_children
    end

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

  # Determines if this node should be the primary node (the one running the counter)
  # Strategy: Use environment variable PRIMARY_NODE=true, or default to the first node alphabetically
  defp is_primary_node? do
    case System.get_env("PRIMARY_NODE") do
      "true" -> true
      "false" -> false
      _ ->
        # If not specified, the primary is the first node alphabetically
        # This ensures deterministic primary selection across the cluster
        all_nodes = Enum.sort([Node.self() | Node.list()])
        Node.self() == List.first(all_nodes)
    end
  end
end
