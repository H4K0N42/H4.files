#!/bin/bash
nix-collect-garbage -d
nix-store --optimise