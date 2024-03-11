defmodule RMI do
  def calculate(prices, momentum_period, rmi_period) do
    # Calculate momentum
    momentum = calculate_momentum(prices, momentum_period)

    # Split into gains (U) and losses (D)
    {gains, losses} = Enum.map(momentum, fn(x) -> if x > 0, do: {x, 0}, else: {0, abs(x)} end)
                        |> Enum.unzip()

    # Calculate EMAs of gains and losses
    ema_gains = calculate_ema(gains, rmi_period)
    ema_losses = calculate_ema(losses, rmi_period)

    # Calculate RMI
    Enum.zip(ema_gains, ema_losses)
    |> Enum.map(fn {u, d} -> (u / (u + d)) * 100 end)
  end

  defp calculate_momentum(prices, period) do
    Enum.zip(prices, Enum.drop(prices, period))
    |> Enum.map(fn {later, earlier} -> later - earlier end)
  end

  defp calculate_ema(values, period) do
    multiplier = 2.0 / (period + 1)
    Enum.reduce(values, [], fn value, acc ->
      case acc do
        [] -> [value]  # First value is just the same as the price
        [prev_ema | _] = _acc ->
          [prev_ema + multiplier * (value - prev_ema) | acc]
      end
    end)
    |> Enum.reverse()
  end
end
