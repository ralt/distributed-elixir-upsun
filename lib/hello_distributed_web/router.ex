defmodule HelloDistributedWeb.Router do
  use HelloDistributedWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloDistributedWeb do
    pipe_through :api

    get "/", PageController, :home
    get "/counter", PageController, :counter
    post "/counter/increment", PageController, :increment
    get "/nodes", PageController, :nodes
  end

  # LiveDashboard
  scope "/" do
    live_dashboard "/dashboard", metrics: HelloDistributedWeb.Telemetry
  end
end
