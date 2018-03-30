defmodule Servy.BearController do

  alias Servy.Wildthings
  alias Servy.Bear

  @templates_path Path.expand("../../templates", __DIR__)

  defp render(conv, template, bindings \\ []) do
    content = 
      @templates_path
      |> Path.join(template)
      |> EEx.eval_file(bindings)

    %{ conv | status: 200, resp_body: content}
  end

  def index(conv) do
    bears = 
      Wildthings.list_bears()
      |> Enum.sort(&Bear.order_asc_by_name/2)

    content = 
      @templates_path
      |> Path.join("index.eex")
      |> EEx.eval_file(bears: bears)

    render(conv, "index.eex", bears: bears)
  end

  def bear_item(bear) do
    "<li>#{bear.name} - #{bear.type}</li>"
    # this function was depricated after html templates were created
  end

  @doc "index function before there were any html templates"
  def depricated_index(conv) do
    items = 
      Wildthings.list_bears()
      # these anonymous functions were refactored using the capture operator below
      # "fn(b) -> Bear.is_grizzly(b)" becomes "&Bear.is_grizzly(&1)"
      # |> Enum.filter(fn(b) -> Bear.is_grizzly(b) end)
      # |> Enum.sort(fn(b1, b2) -> Bear.order_asc_by_name(b1, b2) end)
      # |> Enum.map(fn(b) -> bear_item(b) end)
      |> Enum.filter(&Bear.is_grizzly/1)
      |> Enum.sort(&Bear.order_asc_by_name/2)
      |> Enum.map(&bear_item/1)
      |> Enum.join

    %{ conv | status: 200, resp_body: "<ul><li>#{items}</li></ul>"}
  end

  def show(conv, %{ "id" => id}) do
    bear = Wildthings.get_bear(id)

    content = 
      @templates_path
      |> Path.join("show.eex")
      |> EEx.eval_file(bear: bear)

    render(conv, "show.eex", bear: bear)
  end

  @doc "function to create a bear"
  def create(conv, %{ "type" => type, "name" => name } = params) do
    %{ conv | status: 201, resp_body: "Create a #{type} bear named #{name}!" }
  end
end
