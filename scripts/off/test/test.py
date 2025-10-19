import os
import time
import socket

EDGE_M = 1920
EDGE_P = 2560

P_M = 1/EDGE_P*EDGE_M
M_P = 1/EDGE_M*EDGE_P

INSTANCE_SIG = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
SOCKET_PATH = f"/run/user/1000/hypr/{INSTANCE_SIG}/.socket.sock"


def send_command(cmd: str) -> str:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCKET_PATH)
        s.sendall(cmd.encode())
        return s.recv(4096).decode().strip()


def get() -> tuple[int, int]:
    """Get cursor position via IPC (correct method)"""
    response = send_command("cursorpos")
    x, y = response.split(",")
    return int(x), int(y)

def move(x: int, y: int):
    send_command(f"dispatch movecursor {x} {y}")


# def get():
#     result = subprocess.run(['hyprctl', 'cursorpos'], capture_output=True, text=True).stdout
#     x, y = result.split(",")
#     x, y = int(x), int(y)
#     return x, y
# 
# def move(x, y):
#     subprocess.run(['hyprctl', 'dispatch', 'movecursor', str(x), str(y)])




y_ = 0
while True:
    for i in range(0, 360, 5):
        send_command(f'keyword general:col.active_border rgba(0096ffee) rgba(9600ffee) {i}deg')
        print(i)
        time.sleep(.01)