defmodule Servy.PledgeServer do

  @processName :pledge_server

  use GenServer

  defmodule State do
    defstruct cache_size: 3, pledges: []
  end

  def start_link(_arg) do
    IO.puts "Starting the pledge server..."
    GenServer.start_link(__MODULE__, %State{}, name: @processName)
  end

  # Client interface functions
  def create_pledge(name, amount) do
    GenServer.call @processName, {:create_pledge, name, amount}
  end

  def recent_pledges do
    GenServer.call @processName, :recent_pledges
  end

  def total_pledged do
    GenServer.call @processName, :total_pledged
  end

  def clear do
    GenServer.cast @processName, :clear
  end

  def set_cache_size(size) do
    GenServer.cast @processName, {:set_cache_size, size}
  end

  # server callbacks

  def init(state) do
    pledges = fetch_recent_pledges_from_service()
    new_state = %{state | pledges: pledges}
    {:ok, new_state}
  end

  def handle_cast(:clear, state) do
    {:noreply, %{ state | pledges: [] }}
  end

  def handle_cast({:set_cache_size, size}, state) do
    new_state = %{ state | cache_size: size }
    {:noreply, new_state}
  end

  def handle_call(:total_pledged, _from, state) do
    total = Enum.map(state.pledges, &elem(&1, 1)) |> Enum.sum
    {:reply, total, state}
  end

  def handle_call(:recent_pledges, _from, state) do
    {:reply, state.pledges, state}
  end

  def handle_call({:create_pledge, name, amount}, _from, state) do
    {:ok, id} = send_pledge_to_service(name, amount)
    most_recent_pledges = Enum.take(state.pledges, state.cache_size - 1)
    cache = [{name, amount} | most_recent_pledges]
    new_state = %{ state | pledges: cache }
    {:reply, id, new_state}
  end

  def handle_info(message, state) do
    IO.puts "Can't touch this! \n#{inspect message}"
    {:noreply, state}
  end

  # Client interface functions
  # These functions were refactored to the above to show how gen servers work
  # def create_pledge(name, amount) do
  #   send @processName, {self(), :create_pledge, name, amount}
  #   receive do {:response, response} -> IO.inspect response end
  # end

  # def recent_pledges do
  #   send @processName, {self(), :recent_pledges}
  #   receive do {:response, response} -> IO.inspect response end
  # end

  # def total_pledged do
  #   send @processName, {self(), :total_pledged}
  #   receive do {:response, response} -> IO.inspect response end
  # end

  # Server functions
  # def listen_loop(state) do
  #   IO.puts "\nWaiting for a message..."

  #   receive do

  #     {sender, message} ->
  #       send sender, {:response, response}
  #       listen_loop(state)

  #     {sender, {:create_pledge, name, amount}} ->
  #       {:ok, id} = send_pledge_to_service(name, amount)
  #       most_recent_pledges = Enum.take(state, 2)
  #       cache = [{name, amount} | most_recent_pledges]
  #       send sender, {:response, id}
  #       listen_loop(cache)

  #     {sender, :recent_pledges } -> 
  #       send sender, {:response, state}
  #       listen_loop(state)

  #     {sender, :total_pledged } -> 
  #       total = Enum.map(state, &elem(&1, 1)) |> Enum.sum
  #       send sender, {:response, total}
  #       listen_loop(state)

  #     unexpected ->
  #       IO.puts "Unexpected message: #inspect unexpected}"
  #       listen_loop(state)
  #   end

  # end

  defp send_pledge_to_service(_name, _amount) do
    # CODE TO SEND TO EXTERNAL SERVICE GOES HERE
    {:ok, "pledge-#{:rand.uniform(1000)}"}
  end

  defp fetch_recent_pledges_from_service do
    [{"wilma", 55}, {"fred", 25}]
  end
end

# alias Servy.PledgeServer
# {:ok, pid} = Servy.PledgeServer.start()
# PledgeServer.set_cache_size(4)
# send pid, {:stop, "hammertime"}
# PledgeServer.create_pledge("larry", 10)
# PledgeServer.create_pledge("curtis", 80)
# PledgeServer.create_pledge("bill", 40)
# PledgeServer.create_pledge("erik", 15)
# IO.inspect PledgeServer.recent_pledges
# IO.inspect PledgeServer.total_pledged
# IO.inspect Process.info(pid, :messages)


