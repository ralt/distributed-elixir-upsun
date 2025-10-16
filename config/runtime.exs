import Config

# Runtime configuration for production
if config_env() == :prod do
  # Get runtime configuration from environment variables
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "8080")

  config :hello_distributed, HelloDistributedWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      port: port
    ],
    secret_key_base: secret_key_base

  # Configure the node for distributed Erlang
  # The cookie is used for authentication between nodes
  erlang_cookie = System.get_env("ERLANG_COOKIE")

  if erlang_cookie do
    Node.set_cookie(String.to_atom(erlang_cookie))
  end

  # Set the node name for distributed Erlang
  node_name = System.get_env("NODE_NAME")
  instance_id = System.get_env("PLATFORM_APPLICATION_NAME")

  # This will be something like hello_distributed@app-0
  full_node_name = "#{node_name}@#{instance_id}"

  if System.get_env("ENABLE_DISTRIBUTION") == "true" do
    Node.start(String.to_atom(full_node_name), :longnames)
  end
end
