defmodule HelloDistributedWeb.Router do
  use HelloDistributedWeb, :router

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
end
