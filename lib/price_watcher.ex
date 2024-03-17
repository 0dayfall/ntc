defmodule PriceWatcher do
  use GenServer

  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(initial_state) do
    {:ok, %{prices: [], momentum_period: 5, rmi_period: 14, rmi_values: []} |> Map.merge(initial_state)}
  end

  # This function is called to update the state with the new price
  def handle_call({:new_price, new_price}, _from, state) do
    updated_prices = [new_price | state.prices] |> Enum.take(state.rmi_period + state.momentum_period)
    updated_momentum = RMI.calculate_momentum(updated_prices, state.momentum_period)
    {updated_gains, updated_losses} = RMI.split_gains_losses(updated_momentum)
    updated_ema_gains = RMI.calculate_ema(updated_gains, state.rmi_period)
    updated_ema_losses = RMI.calculate_ema(updated_losses, state.rmi_period)
    updated_rmi_values = RMI.calculate_rmi(updated_ema_gains, updated_ema_losses)

    new_state = Map.update!(state, :prices, fn prices -> updated_prices end)
    |> Map.put(:rmi_values, updated_rmi_values)

    {:reply, :ok, new_state}
  end

  # Client API to push new price updates
  def new_price(pid, price) do
    GenServer.call(pid, {:new_price, price})
  end
end
