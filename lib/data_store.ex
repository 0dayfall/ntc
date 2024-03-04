defmodule DataStore do
  def start_link(initial_value \\ nil) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def update_latest_data(new_data) do
    Agent.update(__MODULE__, fn _old -> new_data end)
  end

  def fetch_latest_data do
    Agent.get(__MODULE__, fn state -> state end)
  end
end
