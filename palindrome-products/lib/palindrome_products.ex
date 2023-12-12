defmodule PalindromeProducts do
  @doc """
  Generates all palindrome products from an optionally given min factor (or 1) to a given max factor.
  """
  @spec generate(non_neg_integer, non_neg_integer) :: map
  def generate(max_factor, min_factor \\ 1)

  def generate(max_factor, min_factor) when max_factor < min_factor,
    do: {:error, "max_factor < min_factor"}

  def generate(max_factor, min_factor) do
    min_prod = min_factor ** 2
    max_prod = max_factor ** 2

    map = min_prod
    |> Integer.digits()
    |> split_digits
    |> palindromate
    |> roll_to_first_palindrome(min_prod)
    |> split_to_digits
    |> get_palindromes_inc_stream(max_prod |> Integer.digits())
    |> Enum.find(fn palindrome ->
      IO.inspect(palindrome, label: "find palindrome")
      case products(palindrome, {max_factor, min_factor}) do
        [] ->
          IO.puts("[] -> false")
          false
        product_list -> IO.inspect(product_list, label: "product_list")
      end
    end)
    |> dbg
    # |> gen_palindromes(max_prod |> Integer.digits(), [])
    # |> List.first
    # |> products({max_factor, min_factor})

    # |> Enum.map(&Tuple.to_list/1)
    # palindrome = map |> List.first() |> Enum.product
    # %{palindrome => map}
  end

  def roll_to_first_palindrome(split, min_prod),
    do:
      unless(split |> split_to_integer >= min_prod,
        do: split |> inc |> roll_to_first_palindrome(min_prod),
        else: split
      )

  defp split_digits(digits) do
    {left_side, right_side} = digits |> Enum.split((length(digits) / 2) |> floor)
    {center, right_side} = right_side |> Enum.split(length(right_side) - length(left_side))
    {left_side, center, right_side}
  end

  defp palindromate({left_side, center, _right_side}),
    do: {left_side, center, left_side |> Enum.reverse()}

  def split_to_integer(split), do: split |> split_to_digits |> Integer.undigits()
  defp split_to_digits(split), do: split |> Tuple.to_list() |> List.flatten()

  def inc({left_side, center, right_side}) do
    {val, carry} =
      List.foldr(left_side ++ center, {[], 1}, fn elem, {list, carry} ->
        {[rem(elem + carry, 10) | list], div(elem + carry, 10)}
      end)

    if(carry > 0, do: [carry | val] ++ right_side, else: val ++ right_side)
    |> split_digits
    |> palindromate
  end

  def dec({left_side, center, right_side}) do
    {val, _borrow} =
      List.foldr(left_side ++ center, {[], 1}, fn elem, {list, borrow} ->
        if elem >= borrow do
          {[elem - borrow | list], 0}
        else
          {[10 + elem - borrow | list], 1}
        end
      end)
    nval = val ++ List.duplicate(9, length right_side)
    if(hd(nval) == 0, do: tl(nval), else: nval)
    |> split_digits
    |> palindromate
  end

  def get_palindromes_inc_stream(first_palindrome_digits, max), do:
    Stream.unfold(first_palindrome_digits, &
      case inc_palindrome(&1, max) do
        nil -> nil
        new_palindrome -> {&1, new_palindrome}
      end)

  def inc_palindrome(digits, max) when length(digits) > length(max), do: nil
  def inc_palindrome(digits, max) when length(digits) == length(max) and digits > max, do: nil
  def inc_palindrome(digits, _max), do: digits |> split_digits |> inc |> split_to_digits

  def products(digits, {max_factor, min_factor}) do
    palindrome = digits |> Integer.undigits()
    # [h | t] = factorize(palindrome)
    # prodprod(palindrome, {[h], t}, {max_factor, min_factor}, []) |> List.flatten |> Enum.sort |> Enum.dedup |> dbg
    prodprod(palindrome, {[1], factorize(palindrome)}, {max_factor, min_factor}, [])
    |> List.flatten()
    |> Enum.map(&order_pair/1)
    |> Enum.sort()
    |> Enum.dedup()
  end

  defp order_pair({a, b}) when a > b, do: {b, a}
  defp order_pair({a, b}), do: {a, b}

  def prodprod(_palindrome, {_factors1, []}, {_max_factor, _min_factor}, acc), do: acc

  def prodprod(palindrome, {factors1, factors2}, {max_factor, min_factor}, acc) do
    prod1 = factors1 |> Enum.product()
    prod2 = factors2 |> Enum.product()
    IO.inspect(factors1, label: "factors1")
    IO.inspect(factors2, label: "factors2")
    IO.puts("prod1:#{prod1} prod2:#{prod2} max_factor:#{max_factor} min_factor:#{min_factor}")

    cond do
      prod1 in min_factor..max_factor and prod2 in min_factor..max_factor ->
        IO.puts("ADD")

        factors2
        |> Enum.uniq()
        |> Enum.map(
          &prodprod(palindrome, {[&1 | factors1], factors2 -- [&1]}, {max_factor, min_factor}, [
            {prod1, prod2} | acc
          ])
        )

      prod1 <= max_factor ->
        IO.puts("NEXT")

        factors2
        |> Enum.uniq()
        |> Enum.map(
          &prodprod(
            palindrome,
            {[&1 | factors1], factors2 -- [&1]},
            {max_factor, min_factor},
            acc
          )
        )

      prod1 > max_factor ->
        IO.puts("FINISH")
        acc
    end
  end

  def factorize(1), do: [1]
  def factorize(num), do: factorize(num, 2, [1])
  def factorize(num, num, acc), do: [num | acc]

  def factorize(num, 2, acc) do
    if(rem(num, 2) == 0) do
      factorize(div(num, 2), 2, [2 | acc])
    else
      factorize(num, 3, acc)
    end
  end

  def factorize(num, dividend, acc) do
    if(rem(num, dividend) == 0) do
      factorize(div(num, dividend), dividend, [dividend | acc])
    else
      factorize(num, dividend + 2, acc)
    end
  end

  # def gen_all_products_with_factors(max_factor, min_factor) do
  #   for f1 <- min_factor..max_factor, f2 <- f1..max_factor do
  #     {f1, f2, f1 * f2}
  #   end
  #   |> Enum.sort(fn {_,_,prod1}, {_,_,prod2} -> prod1 < prod2 end)
  # end
end
