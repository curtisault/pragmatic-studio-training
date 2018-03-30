defmodule Servy.GenericServer do
  def start(callback_module, initial_state, processName) do
    pid = spawn(__MODULE__, :listen_loop, [initial_state, callback_module])
    Process.register(pid, processName)
    pid
  end

  # Helper Functions
  def call(pid, message) do
    send pid, {:call, self(), message}
    receive do {:response, response} -> response end
  end

  def cast(pid, message) do
    send pid, {:cast, message}
  end

  # Server Functions
  def listen_loop(state, callback_module) do
    IO.puts "\nWaiting for a message..."

    receive do
      {:call, sender, message} when is_pid(sender) ->
        {response, new_state} = callback_module.handle_call(message, state)
        send sender, {:response, response}
        listen_loop(new_state, callback_module)

      {:cast, message} ->
        new_state = callback_module.handle_cast(message, state)
        listen_loop(new_state, callback_module)

      unexpected ->
        IO.puts "Unexpected message: #{inspect unexpected}"
        listen_loop(state, callback_module)
    end
  end

end

defmodule Servy.PledgeServerHandRolled do

  alias Servy.GenericServer

  @processName :pledge_server_hand_rolled

  def start do
    IO.puts "Starting the pledge server..."
    GenericServer.start(__MODULE__, [], @processName)
  end

  # Client interface functions
  def create_pledge(name, amount) do
    GenericServer.call @processName, {:create_pledge, name, amount}
  end

  def recent_pledges do
    GenericServer.call @processName, :recent_pledges
  end

  def total_pledged do
    GenericServer.call @processName, :total_pledged
  end

  def clear do
    GenericServer.cast @processName, :clear
  end

  # server callbacks
  def handle_cast(:clear, _state) do
    []
  end

  def handle_call(:total_pledged, state) do
    total = Enum.map(state, &elem(&1, 1)) |> Enum.sum
    {total, state}
  end

  def handle_call(:recent_pledges, state) do
    {state, state}
  end

  def handle_call({:create_pledge, name, amount}, state) do
    {:ok, id} = send_pledge_to_service(name, amount)
    most_recent_pledges = Enum.take(state, 2)
    cache = [{name, amount} | most_recent_pledges]
    {id, cache}
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

  def run_create_pledge_test do
    # send pid, {:stop, "hammertime"}
    Servy.PledgeServerHandRolled.create_pledge("larry", 10)
    Servy.PledgeServerHandRolled.create_pledge("curtis", 80)
    Servy.PledgeServerHandRolled.create_pledge("bill", 40)
    Servy.PledgeServerHandRolled.create_pledge("erik", 15)
    Servy.PledgeServerHandRolled.recent_pledges
    Servy.PledgeServerHandRolled.total_pledged
    Process.info(self(), :messages)
  end

end

