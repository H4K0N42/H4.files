#!/bin/bash

# Replace this with your actual mic source name
MIC_SOURCE="easyeffects_source"

# Load the null sink (virtual sink for soundboard)
pactl load-module module-null-sink sink_name=SoundboardSink sink_properties=device.description=SoundboardSink

# Load loopback from your microphone to the virtual sink
pactl load-module module-loopback source=$MIC_SOURCE sink=SoundboardSink

# You can add other commands below if you want to route more sources

pactl load-module module-remap-source master=SoundboardSink.monitor source_name=SoundboardSource
