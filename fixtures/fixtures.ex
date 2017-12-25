import Groupsort

defmodule Fixtures do
  @student_list [1, 2, 3, 4, 5, 6, 7, 8]

  @history Enum.reduce(
    combinations(@student_list, 2),
    %{},
    fn ([x, y], acc) -> Map.merge(acc, %{{x, y} => Enum.random(0..3)}) end
  )

  def history, do: @history
  def student_list, do: @student_list
end
