
import os
import sys
import time
import socket

INSTANCE_SIG = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
SOCKET_PATH = f"/run/user/1000/hypr/{INSTANCE_SIG}/.socket.sock"


def send_command(cmd: str) -> str:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCKET_PATH)
        s.sendall(cmd.encode())
        return s.recv(4096).decode().strip()

def warp(state: bool):
    if state:
        #send_command("dispatch focuscurrentorlast")
        send_command(f"dispatch focuswindow address:0x{window}")
        if opt_warp == False: send_command("keyword cursor:no_warps false")
    else:
        send_command("keyword cursor:no_warps true")
        send_command("dispatch focuswindow class:(vesktop)")

def reset():
    warp(False)
    send_command("dispatch sendshortcut CTRL SHIFT, M, class:vesktop")
    warp(True)
    time.sleep(1)
    warp(False)
    send_command("dispatch sendshortcut CTRL SHIFT, D, class:vesktop")
    warp(True)
    time.sleep(1)
    warp(False)
    send_command("dispatch sendshortcut CTRL SHIFT, M, class:vesktop")
    warp(True)
    time.sleep(1)
    return 0

def togglemute(state):
    warp(False)
    send_command("dispatch sendshortcut CTRL SHIFT, M, class:vesktop")
    warp(True)
    if state == 0: return 1
    if state == 1: return 0
    if state == 2: return 0
    if state == 3: return 0

def toggledeaf(state):
    warp(False)
    send_command("dispatch sendshortcut CTRL SHIFT, D, class:vesktop")
    warp(True)
    if state == 0: return 2
    if state == 1: return 3
    if state == 2: return 0
    if state == 3: return 1

opt_warp = bool(int(send_command("getoption cursor:no_warps").split(" ")[1].split("\n")[0]))
window = send_command("activewindow").split(" ")[1]

# States:
# 0: Unmuted
# 1: Muted
# 2: Deaf
# 3: Mute + Deaf

try:
    with open("./state") as f:
        state = int(f.read())
except: 
    try:
        if sys.argv[1]: pass
    except: sys.exit()
    state = reset()

state_ = state

try:
    if sys.argv[1].lower() == "mute":
        state = togglemute(state)
    if sys.argv[1].lower() == "deaf":
        state = toggledeaf(state)
except: 
    try: os.remove("./state")
    except: pass
    sys.exit(0)


if state == 0: 
    os.system("ln -sf ./dc_icons/deafen_0.png top.png")
    os.system("ln -sf ./dc_icons/mute_0.png bottom.png")

if state == 1:
    os.system("ln -sf ./dc_icons/deafen_0.png top.png")
    os.system("ln -sf ./dc_icons/mute_1.png bottom.png")

if state >= 2:
    os.system("ln -sf ./dc_icons/deafen_1.png top.png")
    os.system("ln -sf ./dc_icons/mute_1.png bottom.png")

print(f"Changed state: {state_} -> {state}")


with open("./state", "w") as f:
    f.write(f"{state}") 
    
    
#reset()
