defmodule AuthHash do
  def get_hash(username, password, public_key_filename) do
    with {:ok, timestamp} <- {:ok, :os.system_time(:milli_seconds)},
        {:ok, timestamp_b64} <- {:ok, Base.encode64(Integer.to_string(timestamp))},
           {:ok, username_b64} <- {:ok, Base.encode64(username)},
           {:ok, password_b64} <- {:ok, Base.encode64(password)},
           {:ok, public_key} <- load_public_key(public_key_filename),
           {:ok, encrypted_hash} <- public_key_encrypt(public_key, username_b64 <> ":" <> password_b64 <> ":" <> timestamp_b64) do
        {:ok, Base.encode64(encrypted_hash)}
      else
        # Handles any error from the above steps
        {:error, reason} -> {:error, reason}
      end
  end

  defp load_public_key(filename) do
    case File.read(filename) do
      {:ok, content} ->
        {:ok, der, _} = :public_key.pem_decode(content)
        {:ok, key} = :public_key.pem_entry_decode(der)
        key

      {:error, reason} ->
        IO.puts("Could not find the file: #{filename}, #{reason}")
        System.halt()
    end
  end

  defp public_key_encrypt(public_key, data) do
    case :public_key.encrypt_public(public_key, data) do
      {:ok, encrypted_data} ->
        encrypted_data

      {:error, _reason} ->
        IO.puts("Encryption failed")
        ""
    end
  end
end
