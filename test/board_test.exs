defmodule Conway.BoardTest do
  use ExUnit.Case, async: true
  @board_size 50
  test "starts with an inital state" do
    %{state: [row | _rest]=board} = Conway.Board.get_board
    assert Enum.count(row) == @board_size
    assert Enum.count(board) == @board_size
  end

  @board [
    [true, false, true],
    [true, false, true],
    [true, false, true]
  ]

  test "rule 1" do
    assert Conway.Board.rule1(@board, 0, 0) == false
    assert Conway.Board.rule1(@board, 0, 1) == false
  end
end
