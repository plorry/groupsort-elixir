defmodule Groupsort do
  # group_history - map: tuple of 2 ints -> int
  # student - int (id)
  # group_config - tuple of ints
  def get_pairing_count(history, student1, student2) do
    history[{student1, student2}]
  end
  
  @doc """
  Takes a history map and increments the count at the given pair key.
  If no such historical count exists, a new count is started at 1.

  ## Examples
    iex> h = %{{1, 2} => 1}
    %{{1, 2} => 1}
    iex> Groupsort.add_pair(h, {1, 2})
    %{{1, 2} => 2}

    iex> h = %{{1, 2} => 1}
    %{{1, 2} => 1}
    iex> Groupsort.add_pair(h, {2, 3})
    %{{1, 2} => 1, {2, 3} => 1}
  """
  def add_pair(history, pair) do
    case history do
      %{^pair => c} -> %{history | pair => c + 1}
      _ -> Map.merge(history, %{pair => 1})
    end
  end

  @doc """
  Takes two students and returns a pair tuple, ordered
  from lower to higher ID value

  ## Examples
    iex> Groupsort.make_pair(2, 3)
    {2, 3}
    
    iex> Groupsort.make_pair(3, 2)
    {2, 3}
  """
  def make_pair(student1, student2) do
    {min(student1, student2), max(student1, student2)}
  end
  
  @doc """
  Takes a history and a group of IDs, and returns the sum of the historical
  pairing count for each unique pair in the group
  
  ## Examples
    iex> h = %{{1, 2} => 3, {2, 3} => 1, {1, 3} => 2}
    iex> Groupsort.get_group_pair_count(h, [1, 2, 3])
    6
    iex> Groupsort.get_group_pair_count(h, [1, 2])
    3
  """
  def get_group_pair_count(history, group) do
    Enum.reduce(combinations(group, 2), 0, fn ([x, y], acc) -> get_pairing_count(history, x, y) + acc end)
  end

  def get_groupset_pair_count(history, groupset) do
    Enum.reduce(groupset, 0, fn (group, acc) -> get_group_pair_count(history, group) + acc end)
  end

  def combinations(_, 0), do: [[]]
  def combinations([], _), do: []

  def combinations([x|xs], n) do
    (for y <- combinations(xs, n - 1), do: [x|y]) ++ combinations(xs, n)
  end
  
  @doc """
  Returns the group with the lowest pairing count between 2 given groups according to the history

  ## Examples
    iex> h = %{{1, 2} => 1, {1, 3} => 2, {1, 4} => 2, {2, 3} => 2, {2, 4} => 2, {3, 4} => 1}
    iex> Groupsort.min_pairing_group(h, [1, 2], [1, 3])
    [1, 2]
    iex> Groupsort.min_pairing_group(h, [1, 2, 3, 4], [])
    [1, 2, 3, 4]
  """
  def min_pairing_group(_, group1, []), do: group1

  def min_pairing_group(history, group1, group2),
    do: Enum.min_by([group1, group2], &(get_group_pair_count(history, &1)))

  @doc """
  Returns the groupset with the lower pairing count, according to a given history
  
  ## Examples
    iex> h = %{{1, 2} => 1, {1, 3} => 2, {1, 4} => 2, {2, 3} => 2, {2, 4} => 2, {3, 4} => 1}
    iex> Groupsort.min_pairing_groupset(h, [[1, 2], [3, 4]], [[1, 3], [2, 4]])
    [[1, 2], [3, 4]]
  """
  def min_pairing_groupset(_, groupset1, []), do: groupset1

  def min_pairing_groupset(history, groupset1, groupset2),
    do: Enum.min_by([groupset1, groupset2], &(get_groupset_pair_count(history, &1)))

  def sort(history, student_list, group_config, groupset \\ [])
  def sort(history, student_list, [_|[]], groupset), do: [student_list | groupset]

  def sort(history, student_list, [group_size|group_config], groupset) do
    (for group <- combinations(student_list, group_size),
      do: sort(history, student_list -- group, group_config, [group | groupset])
    )
    |> Enum.reduce([], &(min_pairing_groupset(history, &1, &2)))
  end
end
