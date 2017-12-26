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
    iex> Groupsort.add_pair(h, {1, 2})
    %{{1, 2} => 2}
    iex> Groupsort.add_pair(h, {2, 3})
    %{{1, 2} => 1, {2, 3} => 1}
  """
  def add_pair(history, pair) do
    Map.put(history, pair, get_pairing_count(history, pair) + 1)
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
    Enum.min_max([student1, student2])
  end

  @doc """
  Returns the historical pairing count for the pair of students given
  or zero in the case that there is no entry for the pair in the history.

  ## Examples
    iex> history = %{{1, 2} => 4, {1, 3} => 3, {2, 3} => 7}
    iex> Groupsort.get_pairing_count(history, {1, 3})
    3
    iex> Groupsort.get_pairing_count(history, {1, 5})
    0
  """
  def get_pairing_count(history, pair) do
    history[pair] || 0
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
    |> Enum.reduce(0, &(get_pairing_count(history, List.to_tuple(&1)) + &2))
  end

  def get_groupset_pair_count(history, groupset) do
    groupset
    |> Enum.reduce(0, &(get_group_pair_count(history, &1) + &2))
  end

  @doc """
  Gives a list of the unique combinations of size n of a given list.
  Courtesy -> https://stackoverflow.com/a/30587756
  Probably makes sense to extract into its own module eventually.
  
  ## Examples
    iex> Groupsort.combinations([1, 2, 3], 2)
    [[1, 2], [1, 3], [2, 3]]
  """
  def combinations(_, 0), do: [[]]
  def combinations([], _), do: []

  def combinations([x|xs], n) do
    (for y <- combinations(xs, n - 1), do: [x|y]) ++ combinations(xs, n)
  end

  @doc """
  Groupsort.sort is the primary method of this module. Given a history of student pairings,
  a student_list (list of IDs), and a desired group_config, this function will return a
  groupset (ie. a list of groups) matching the group_config, with the minimum number of
  repeated pairs from the given history.

  ## Examples
    iex> history = %{{1, 2} => 4, {1, 3} => 3, {1, 4} => 0, {2, 3} => 0, {2, 4} => 2, {3, 4} => 1}
    iex> student_list = [1, 2, 3, 4]
    iex> Groupsort.sort(history, student_list, [2, 2])
    [[2, 3], [1, 4]]

  In the above example, we have 4 students, and we want to create a groupset that consists
  of two groups of two (the sum of our group_config values must naturally total the count
  of students).
  From our history, we can see that students 1 and 4 have never been paired together. Likewise,
  students 2 and 3 have never been paired. Every other possible pair has some non-zero count.
  Therefore, our ideal final pairing is 1 and 4, and 2 and 3. Two groups of two, minimizing the
  pairing overlap.
  """
  def sort(history, student_list, group_config, groupset \\ [])
  def sort(_, student_list, [_|[]], groupset), do: [student_list | groupset]

  def sort(history, student_list, [group_size | group_config], groupset) do
    student_list
    |> combinations(group_size)
    |> Stream.map(&(sort(history, student_list -- &1, group_config, [&1 | groupset])))
    |> Enum.min_by(&(get_groupset_pair_count(history, &1)))
  end
end
