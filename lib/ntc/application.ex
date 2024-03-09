defmodule Ntc.Application do
  use Application

  def start(_type, _args) do
    username = System.get_env("NORDNET_USERNAME")
    password = System.get_env("NORDNET_PASSWORD")
    pem_file = System.get_env("NORDNET_PEM_FILE")

    children = []

    case AuthHash.get_hash(username, password, pem_file) do
      {:error, _} ->
        System.halt(1)

      encoded_hash ->
        login_with_hash(encoded_hash)
        [{JsonTcpClient, [encoded_hash]}]
    end

    opts = [strategy: :one_for_one, name: Ntc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp login_with_hash(hash) do
    # Dummy function for login logic
    # Replace this with actual logic to perform login, possibly returning :ok or :error
    # depending on whether the login was successful
    IO.puts("Performing login with hash: #{Base.encode64(hash)}")
    :ok
  end
end
