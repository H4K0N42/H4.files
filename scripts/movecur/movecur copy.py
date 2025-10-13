import subprocess
import time

EDGE_M = 1920
EDGE_P = 2560

P_M = 1/EDGE_P*EDGE_M
M_P = 1/EDGE_M*EDGE_P


def move(x, y):
    subprocess.run(['hyprctl', 'dispatch', 'movecursor', str(x), str(y)])

def get():
    result = subprocess.run(['hyprctl', 'cursorpos'], capture_output=True, text=True).stdout
    x, y = result.split(",")
    x, y = int(x), int(y)
    return x, y

y_ = 0

while True:
    time.sleep(0.1)
    
    x, y = get()
    
    if y_ > 0 >= y:
        x_ = int(x*P_M)
        print(f"x: {x} -> x: {x_} @ {y}")
        move(x_, y)
        
    if y_ < -1 <= y:
        x_ = int(x*M_P)
        print(f"x: {x} -> x: {x_} @ {y}")
        move(x_, y)
    
    y_ = y