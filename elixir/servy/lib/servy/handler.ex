defmodule Servy.Handler do
  @moduledoc "Handles HTTP requests."

  alias Servy.Conv
  alias Servy.BearController
  alias Servy.VideoCam

  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]
  import Servy.Parser

  @doc "Example of a constant"
  @pages_path Path.expand("../../pages", __DIR__)

  @doc "Transforms the request into a response."
  def handle(request) do
    request
      |> parse
      |> rewrite_path
      # |> log
      |> route
      |> track
      |> format_response
  end

  # def route(conv) do
  #   route(conv, conv.method, conv.path)
  # end

  def route(%Conv{method: "POST", path: "/pledges"} = conv) do
    Servy.PledgeController.create(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/pledges"} = conv) do
    Servy.PledgeController.index(conv)
  end

  def route(%Conv{ method: "GET", path: "/sensors" } = conv) do
    # This code now sits in the SensorServer which uses a GenServer
    # cameras = ["cam-1","cam-2","cam-3"]
    # task = Task.async(fn -> Servy.Tracker.get_location("bigfoot") end)

    # snapshots = 
    #   cameras 
    #   |> Enum.map(&Task.async(fn -> VideoCam.get_snapshot(&1) end))
    #   |> Enum.map(&Task.await/1)

    # where_is_bigfoot = Task.await(task)

    sensor_data = Serv.SensorServer.get_sensor_data()
    %{ conv | status: 200, resp_body: inspect sensor_data}
  end

  # def route(%Conv{ method: "GET", path: "/sensors" } = conv) do
  #   cameras = ["cam-1","cam-2","cam-3"]
  #   # Task is a drop in replacement for the Fetcher function (they're identical)
  #   # however, it does not return a pid; it returns a task struct
  #   task = Task.async(fn -> Servy.Tracker.get_location("bigfoot") end)

  #   snapshots = 
  #     cameras 
  #     |> Enum.map(&Task.async(fn -> VideoCam.get_snapshot(&1) end))
  #     |> Enum.map(&Task.await/1)

  #   # refactored
  #   # pid1 = Fetcher.async(fn -> VideoCam.get_snapshot("cam-1") end)
  #   # pid2 = Fetcher.async(fn -> VideoCam.get_snapshot("cam-2") end)
  #   # pid3 = Fetcher.async(fn -> VideoCam.get_snapshot("cam-3") end)
  #   # pid4 = Fetcher.async(fn -> Tracker.get_location("bigfoot") end)
  #   # snapshot1 = Fetcher.get_result(pid1)
  #   # snapshot2 = Fetcher.get_result(pid2)
  #   # snapshot3 = Fetcher.get_result(pid3)
  #   where_is_bigfoot = Task.await(task)

  #   # snapshots = [snapshot1, snapshot2, snapshot3]

  #   %{ conv | status: 200, resp_body: inspect {snapshots, where_is_bigfoot}}
  # end

  def route(%Conv{ method: "GET", path: "/snapshots" } = conv) do
    pid1 = Servy.Fetcher.async(fn -> VideoCam.get_snapshot("cam-1") end)
    pid2 = Servy.Fetcher.async(fn -> VideoCam.get_snapshot("cam-2") end)
    pid3 = Servy.Fetcher.async(fn -> VideoCam.get_snapshot("cam-3") end)

    snapshot1 = Servy.Fetcher.get_result(pid1)
    snapshot2 = Servy.Fetcher.get_result(pid2)
    snapshot3 = Servy.Fetcher.get_result(pid3)

    snapshots = [snapshot1, snapshot2, snapshot3]

    %{ conv | status: 200, resp_body: inspect snapshots}
  end

  def route(%Conv{ method: "GET", path: "/kaboom" } = conv) do
    raise "Kaboom!"
  end

  def route(%Conv{ method: "GET", path: "/hibernate/" <> time } = conv) do
    String.to_integer(time) |> :timer.sleep
    %{ conv | status: 200, resp_body: "Awake!"}
  end

  def route(%Conv{ method: "GET", path: "/wildthings" } = conv) do
    # conv = Map.put(conv, :resp_body, "Bears, Lions, Tigers")
    # the above map update can use the below as short hand syntax
    %{ conv | status: 200, resp_body: "Bears, Lions, Tigers"}
  end

  def route(%Conv{ method: "GET", path: "/api/bears" } = conv) do
    Servy.Api.BearController.index(conv)
  end

  def route(%Conv{ method: "GET", path: "/bears" } = conv) do
    BearController.index(conv)
  end

  def route(%Conv{ method: "GET", path: "/bears/" <> id } = conv) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end

  # name=Baloo&type=Brown
  def route(%Conv{ method: "POST", path: "/bears" } = conv) do
    BearController.create(conv, conv.params)
  end

  def route(%Conv{ method: "GET", path: "/about" } = conv) do
    @pages_path
      |> Path.join("about.html")
      |> File.read
      |> handle_file(conv)
  end

  def route(%Conv{ path: path } = conv) do
    %{ conv | status: 404, resp_body: "No #{path} here!" }
  end

  def handle_file({:ok, content}, conv) do 
    %{ conv | status: 200, resp_body: content}
  end

  def handle_file({:error, :onoent}, conv) do 
    %{ conv | status: 404, resp_body: "File not found!"}
  end

  def handle_file({:error, reason}, conv) do 
    %{ conv | status: 500, resp_body: "File error: #{reason}"}
  end

  # def route(%{ method: "GET", path: "/about" } = conv) do
  #   file = 
  #     Path.expand("../../pages", __DIR__)
  #       |> Path.join("about.html")

  #   case File.read(file) do
  #     {:ok, content} ->
  #       %{ conv | status: 200, resp_body: content}

  #     {:error, :enoent} ->
  #       %{ conv | status: 404, resp_body: "File not found!"}

  #     {:error, reason} ->
  #       %{ conv | status: 500, resp_body: "File error: #{reason}"}
  #   end
  # end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    Content-Type: #{conv.resp_content_type}\r
    Content-Length: #{String.length(conv.resp_body)}\r
    \r
    #{conv.resp_body}
    """
  end
end
