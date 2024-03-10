import socket
import json
import threading
import time

# Credentials for login
VALID_USERNAME = "testuser"
VALID_PASSWORD = "testpassword"

def send_heartbeat(client_socket):
    while client_socket.fileno() != -1:  # Check if the socket is still open
        try:
            client_socket.sendall(json.dumps({"type": "heartbeat", "data": {"message": "Alive"}}).encode('utf-8'))
            time.sleep(5)  # Wait for 5 seconds before sending the next heartbeat
        except Exception as e:
            print(f"Error sending heartbeat: {e}")
            break  # Exit the loop if there's an error (e.g., client disconnected)

def handle_client(client_socket):
    # Wait for the login message
    login_data = client_socket.recv(1024).decode('utf-8')
    try:
        login_message = json.loads(login_data)
        username = login_message.get("data", {}).get("username")
        password = login_message.get("data", {}).get("password")

        # Check credentials
        if login_message.get("type") == "login" and username == VALID_USERNAME and password == VALID_PASSWORD:
            # Send login acknowledgement
            client_socket.sendall(json.dumps({"type": "login_ack", "data": {"message": "Login successful"}}).encode('utf-8'))
            # Start sending heartbeats
            heartbeat_thread = threading.Thread(target=send_heartbeat, args=(client_socket,))
            heartbeat_thread.start()
        else:
            # Send login failure message and close connection
            client_socket.sendall(json.dumps({"type": "login_fail", "data": {"message": "Invalid credentials"}}).encode('utf-8'))
            client_socket.close()
            return
    except json.JSONDecodeError:
        # Handle bad JSON
        client_socket.sendall(json.dumps({"type": "error", "data": {"message": "Invalid JSON"}}).encode('utf-8'))
        client_socket.close()
        return

    # Client is now logged in; handle further communications here
    while True:
        data = client_socket.recv(1024).decode('utf-8').strip()
        if data:
            print(f"Received from client: {data}")
            # Here you can decode and respond to other types of messages
        else:
            break  # Client disconnected

    client_socket.close()

def start_server():
    host = ''  # Listen on all network interfaces
    port = 1234

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen()

    print(f"Server listening on port {port}")

    try:
        while True:
            client_socket, addr = server_socket.accept()
            print(f"Accepted connection from {addr}")
            client_thread = threading.Thread(target=handle_client, args=(client_socket,))
            client_thread.start()
    finally:
        server_socket.close()

if __name__ == '__main__':
    start_server()
