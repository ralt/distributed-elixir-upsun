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

end
