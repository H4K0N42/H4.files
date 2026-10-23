#!/usr/bin/env bash
# Start Discord, make sure it actually comes up, then start OpenDeck.
#
# OpenDeck is a flatpak: a discord-ipc-N socket is bind-mounted into its sandbox
# only if it already exists when OpenDeck starts (and only that inode — a
# Discord restart needs an OpenDeck restart too). Discord takes the first free
# N in 0..9, so pass whichever sockets exist explicitly.

socks() {
  compgen -G "$XDG_RUNTIME_DIR/discord-ipc-[0-9]"
}

wait_for_sock() {
  for _ in $(seq "$1"); do
    socks >/dev/null && return 0
    sleep 1
  done
  return 1
}

discord &

# Discord sometimes hangs at login without ever opening; kill and retry.
if ! wait_for_sock 45; then
  pkill -f Discord-wrapped
  sleep 2
  discord &
  wait_for_sock 60
fi

args=()
for s in $(socks); do
  args+=("--filesystem=xdg-run/${s##*/}")
done

flatpak run "${args[@]}" me.amankhanna.opendeck --hide
