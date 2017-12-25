defmodule Groupsort do
  @moduledoc """
  Elixir module to group students efficiently, maxmizing the number of novel pairs
  by looking at a given history, and minimizing the number of repeated historical
  pairs.

  WIP - current implementation is BRUTE FORCE. It gets the best solution, but explodes
  for numbers greater than ~15 students.
  """

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
  Helper function for making sure pair fetching & creation is always consistently ordered.
  Given two IDs, gives you the tuple of those IDs, ordered, for passing around as a pair.

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
  Returns the historical pairing count for the pair of students given

  ## Examples
    iex> history = %{{1, 2} => 4, {1, 3} => 3, {2, 3} => 7}
    iex> Groupsort.get_pairing_count(history, 1, 3)
    3
    iex> Groupsort.get_pairing_count(history, 2, 3)
    7
  """
  def get_pairing_count(history, student1, student2) do
    history[{student1, student2}]
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
    group
    |> combinations(2)
    |> Enum.reduce(0, fn ([x, y], acc) -> get_pairing_count(history, x, y) + acc end)
  end

  def get_groupset_pair_count(history, groupset) do
    groupset
    |> Enum.reduce(0, fn (group, acc) -> get_group_pair_count(history, group) + acc end)
  end

  def combinations(_, 0), do: [[]]
  def combinations([], _), do: []

  def combinations([x|xs], n) do
    (for y <- combinations(xs, n - 1), do: [x|y]) ++ combinations(xs, n)
  end

  defp min_pairing_groupset(_, groupset1, []), do: groupset1

  defp min_pairing_groupset(history, groupset1, groupset2),
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
