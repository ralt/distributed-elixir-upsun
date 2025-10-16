defmodule HelloDistributedWeb.Router do
  use HelloDistributedWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

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
    pipe_through :browser
    live_dashboard "/dashboard", metrics: HelloDistributedWeb.Telemetry
  end
end
