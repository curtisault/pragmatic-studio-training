defmodule Servy.Supervisor do
  use GenServer

  def start_link do
    IO.puts "Starting THE supervisor..."
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      Servy.Kickstarter,
      {Servy.ServicesSupervisor, 60}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
