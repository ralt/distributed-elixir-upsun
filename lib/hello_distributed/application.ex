defmodule HelloDistributed.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Telemetry supervisor
      HelloDistributedWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: HelloDistributed.PubSub},
      # Start the Endpoint (http/https)
      HelloDistributedWeb.Endpoint,
      # Start the distributed counter GenServer
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
end
