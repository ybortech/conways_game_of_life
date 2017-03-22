defmodule Conway.Board do
  use GenServer
  @topic "conway:lobby"
  @size 50 - 1
  @chance 0.25
  import Conway.Web.Endpoint, only: [broadcast: 3]

  def rule1(board, row, column) do
    cell_value = board
            |> Enum.at(row)
            |> Enum.at(column)

    case cell_value do
      false -> false
      true -> number_of_living_neighbors(board, row, column) > 1
    end
  end

  def number_of_living_neighbors(board, row, column) do
    scores = for x <- row - 1 .. row + 1, y <- column - 1 .. column + 1, into: [] do
      {x,y}
      cond do
        x < 0 -> 0
        y < 0 -> 0
        x > @size -> 0
        y > @size -> 0
        x == row and y == column -> 0
        true -> board |> Enum.at(x) |> Enum.at(y) |> case do
          true -> 1
          _ -> 0
        end
      end
    end
    scores |> Enum.sum
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    state = generate_inital_state()
    broadcast(@topic, "update_board", %{state: state})
    Process.send_after(self(), :step, 1_000)
    {:ok, %{state: state}}
  end

  def get_board do
    GenServer.call(__MODULE__, :get_board)
  end

  def handle_call(:get_board, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:step, %{state: nil} = state) do
    {:noreply, state}
  end

  def handle_info(:step, %{state: board}) do
    new_board = map_cells(fn({row, col})->
      cell_value = board
              |> Enum.at(row)
              |> Enum.at(col)
      living = number_of_living_neighbors(board, row, col)
      cond do
        cell_value and living < 2 -> false
        cell_value and living > 1 and living < 4 -> true
        cell_value and living > 3 -> false
        !cell_value and living == 3 -> true
        true -> cell_value
      end
    end)
    broadcast(@topic, "update_board", %{state: new_board})
    Process.send_after(self(), :step, 1_000)
    {:noreply, %{state: new_board}}
  end

  defp generate_inital_state do
    fn(_loc)->
      maybe()
    end
    |> map_cells
  end

  defp map_cells(input_fn) do
    Enum.map(0..@size, fn(row)->
      Enum.map(0..@size, fn(column)->
        input_fn.({row, column})
      end)
    end)
  end

  defp maybe do
    :rand.uniform() < @chance
  end
end
