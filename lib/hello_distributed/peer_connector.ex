defmodule HelloDistributed.PeerConnector do
  @moduledoc """
  Connects to peer nodes listed in /run/peers.json
  """
  use GenServer
  require Logger

  @peers_file "/run/peers.json"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Connect to peers after the application has fully started
    send(self(), :connect_peers)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:connect_peers, state) do
    connect_to_peers()
    {:noreply, state}
  end

  defp connect_to_peers do
    if File.exists?(@peers_file) do
      Logger.info("Reading peers from #{@peers_file}")

      case File.read(@peers_file) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, peers} ->
              Logger.info("Found peers: #{inspect(peers)}")

              current_node = Node.self()
              Logger.info("Current node: #{current_node}")

              node_name = System.get_env("NODE_NAME", "hello_distributed")

              Enum.each(peers, fn {_node_name, ip_address} ->
                peer_node = String.to_atom("#{node_name}@#{ip_address}")

                if peer_node != current_node do
                  Logger.info("Attempting to connect to: #{peer_node}")

                  case Node.connect(peer_node) do
                    true -> Logger.info("Successfully connected to #{peer_node}")
                    false -> Logger.warning("Failed to connect to #{peer_node}")
                    :ignored -> Logger.warning("Connection to #{peer_node} ignored (local node not alive)")
                  end
                else
                  Logger.info("Skipping self: #{peer_node}")
                end
              end)

              Logger.info("Connected nodes: #{inspect(Node.list())}")

            {:error, reason} ->
              Logger.error("Failed to parse JSON: #{inspect(reason)}")
          end

        {:error, reason} ->
          Logger.error("Failed to read peers file: #{inspect(reason)}")
      end
    else
      Logger.info("Peers file not found at #{@peers_file}")
    end
  end
end
