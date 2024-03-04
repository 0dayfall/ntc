defmodule JsonTcpClient do
  use GenServer
  @reconnect_delay 5000  # Time in milliseconds to wait before attempting to reconnect

  # Start the GenServer
  def start_link(host, port) do
    GenServer.start_link(__MODULE__, {host, port}, name: __MODULE__)
  end

  # Initialize and connect to the server
  def init({host, port}) do
    {:ok, socket} =
      :gen_tcp.connect(String.to_charlist(host), port,
        active: :once,
        packet: :line,
        mode: :binary
      )

    {:ok, %{socket: socket}}
  end

  def handle_info({:tcp, _socket, data}, %{socket: socket} = state) do
    case Jason.decode(data) do
      {:ok, %{"type" => message_type, "data" => message_data}} ->
        # Process the message based on its type
        case message_type do
          "heartbeat" ->
            # Process heartbeat message
            IO.puts("Received heartbeat")

          "price" ->
            # Here you would use the structure of PublicPrice to extract data
            # For example:
            bid = Map.get(message_data, "bid")
            IO.puts("Received price data: #{inspect(bid)}")

          "trade" ->
            # Here you would use the structure of PublicTrade to extract data
            # Example:
            price = Map.get(message_data, "price")
            IO.puts("Received trade data: #{inspect(price)}")

            "depth" ->
              # Example for processing depth data
              bid1 = Map.get(message_data, "bid1")
              ask1 = Map.get(message_data, "ask1")
              IO.puts("Received depth data: bid1=#{inspect(bid1)}, ask1=#{inspect(ask1)}")

            "indicator" ->
              # Example for processing indicator data
              high = Map.get(message_data, "high")
              low = Map.get(message_data, "low")
              IO.puts("Received indicator data: high=#{inspect(high)}, low=#{inspect(low)}")

            "news" ->
              # Example for processing news data
              headline = Map.get(message_data, "headline")
              datetime = Map.get(message_data, "datetime")
              IO.puts("Received news: [#{datetime}] #{headline}")

            "trading_status" ->
              # Example for processing trading status data
              status = Map.get(message_data, "status")
              halted = Map.get(message_data, "halted")
              IO.puts("Received trading status: status=#{inspect(status)}, halted=#{inspect(halted)}")

          _ ->
            IO.puts("Unknown message type received")
        end

        {:noreply, state}

      {:error, _error} ->
        IO.puts("Error decoding JSON data")
        {:noreply, state}
    end

    :inet.setopts(socket, active: :once)
  end

  # Handle the TCP connection closing
  def handle_info({:tcp_closed, _socket}, state) do
    IO.puts("TCP connection closed by the server, attempting to reconnect...")
    # Schedule reconnection attempt after a delay
    Process.send_after(self(), :reconnect, @reconnect_delay)
    # Update state to reflect that the connection is closed
    {:noreply, %{state | socket: nil}}
  end

  # Handle reconnection
  def handle_info(:reconnect, %{host: host, port: port} = state) do
    case :gen_tcp.connect(String.to_charlist(host), port,
           active: :once,
           packet: :line,
           mode: :binary
         ) do
      {:ok, socket} ->
        IO.puts("Reconnected to TCP server.")
        {:noreply, %{state | socket: socket}}

      {:error, reason} ->
        IO.puts("Failed to reconnect: #{inspect(reason)}")
        # Retry connecting after a delay
        Process.send_after(self(), :reconnect, @reconnect_delay)
        {:noreply, state}
    end
  end

  # Handling TCP connection closed and error
  # Implement your handle_info definitions for :tcp_closed and :tcp_error here
end
