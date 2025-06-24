#!/bin/bash
cd ~/hailo-rpi5-examples
source setup_env.sh

# Start wmctrl in parallel na 2 seconden
(
  sleep 2
  wmctrl -r "Detection" -b add,maximized_vert,maximized_horz
) &

# Start Python-script op de voorgrond
python basic_pipelines/detection_simple.py \
  --input /dev/video1 \
  --labels-json resources/ppe-labels.json \
  --hef-path resources/ppe-model.hef
