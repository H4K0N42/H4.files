import subprocess


current = subprocess.run(
    ["playerctl", "--player=spotify", "metadata", "--format", '{"text": "{{title}}", "alt":"{{artist}}"}'],
    text=True,
    capture_output=True
).stdout.strip()


# state = subprocess.run(
#     ["playerctl", "--player=spotify", "status"],
#     text=True,
#     capture_output=True
# ).stdout.strip()
print(f"{current}")

