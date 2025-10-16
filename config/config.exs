import Config

# Configures the endpoint
config :hello_distributed, HelloDistributedWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: HelloDistributedWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HelloDistributed.PubSub,
  live_view: [signing_salt: "random_salt"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config
import_config "#{config_env()}.exs"
