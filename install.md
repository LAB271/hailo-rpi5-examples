# Hailo RPi5 Examples Installation Guide

## Prerequisites

- Raspberry Pi 5
- Updated Raspberry Pi OS
- Internet connection

## Basic Installation

### 1. Update System Packages

```bash
# Update package list
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Install wmctrl to control windows in the GUI
sudo apt install wmctrl

```

### 2. Install System Dependencies

```bash
# Install Raspberry Pi kernel headers
sudo apt-get install raspberrypi-kernel-headers

# Install Hailo runtime and tools
sudo apt install hailo-all

# Reboot to complete installation
sudo reboot
```

### 3. Verify Hailo Installation

After reboot, verify the Hailo-8L device is detected:

```bash
hailortcli fw-control identify
```

### 4. Install Camera Support

```bash
# Install RPi camera applications
sudo apt install rpicam-apps

# Test camera (optional)
rpicam-hello -t 10s
```

### 5. Clone and Setup Examples Repository

```bash
# Clone the repository
git clone https://github.com/hailo-ai/hailo-rpi5-examples.git

# Enter the directory
cd hailo-rpi5-examples

# Run the installation script
./install.sh

# Setup the environment
source setup_env.sh
```

## Advanced Setup: RTSP Stream Support

### 1. Install Dependencies

```bash
# Install v4l2loopback and ffmpeg
sudo apt install v4l2loopback-dkms ffmpeg
```

### 2. Create Virtual Video Device

```bash
# Load v4l2loopback module
sudo modprobe v4l2loopback video_nr=1 card_label="RTSPCam" exclusive_caps=1
```

### 3. Stream RTSP to Virtual Device

Basic streaming command:

```bash
ffmpeg -rtsp_transport tcp -i "rtsp://username:password@ip_address/path" -f v4l2 -pix_fmt yuv420p -vf scale=640:480 /dev/video1
```

With horizontal flip:

```bash
ffmpeg -rtsp_transport tcp -i "rtsp://username:password@ip_address/path" -f v4l2 -pix_fmt yuv420p -vf "scale=640:480,hflip" /dev/video1
```

### 4. Create Systemd Service for Automatic RTSP Streaming

#### Create the streaming script

```bash
sudo nano /usr/local/bin/rtsp-to-v4l2.sh
```

```bash
#!/bin/bash

# Load v4l2loopback if not already loaded
modprobe v4l2loopback video_nr=1 card_label="RTSPCam" exclusive_caps=1

# Run ffmpeg to mirror and scale RTSP stream to /dev/video1
ffmpeg -rtsp_transport tcp -i "rtsp://PPE:7Vs4DzkxjbGyNe7@10.32.8.50/Streaming/channels/101" \
-f v4l2 -pix_fmt yuv420p -vf "scale=640:480,hflip" /dev/video1

```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/rtsp-to-v4l2.sh
```

#### Create systemd service

```bash
sudo nano /etc/systemd/system/rtsp-to-v4l2.service
```

```bash
[Unit]
Description=RTSP to V4L2 loopback via FFmpeg
After=network.target
Requires=network.target

[Service]
ExecStart=/usr/local/bin/rtsp-to-v4l2.sh
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target

```

```bash
[Unit]
Description=Run GUI startup.sh after rtsp-to-v4l2
After=rtsp-to-v4l2.service graphical.target
Requires=rtsp-to-v4l2.service

[Service]
Type=simple
ExecStart=/home/admin/startup.sh
User=admin
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/admin/.Xauthority
WorkingDirectory=/home/admin
Environment=HOME=/home/admin
Restart=on-failure

[Install]
WantedBy=graphical.target


```

```bash
#!/bin/bash
cd ~/hailo-rpi5-examples
source setup_env.sh

# Start wmctrl in parallel na 2 seconden
(
  sleep 10
  wmctrl -r "Detection" -b add,maximized_vert,maximized_horz
) &

# Start Python-script op de voorgrond
python basic_pipelines/detection_simple.py \
  --input /dev/video1 \
  --labels-json resources/ppe-labels.json \
  --hef-path resources/ppe-model.hef


```

#### Enable and start the service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable rtsp-to-v4l2.service

# Start the service
sudo systemctl start rtsp-to-v4l2.service

# Check service status
sudo systemctl status rtsp-to-v4l2.service
```

## Testing the Installation

### Basic Detection Example

```bash
# Using default camera
python basic_pipelines/detection_simple.py

# Using RTSP virtual device
python basic_pipelines/detection_simple.py --input /dev/video1
```

### Other Examples

```bash
# Pose estimation
python basic_pipelines/pose_estimation.py

# Detection with options
python basic_pipelines/detection.py --help

# Detection with PPE and custom model
python basic_pipelines/detection_simple.py --input /dev/video1 --labels-json resources/ppe-labels.json --hef-path resources/ppe-model.hef
```

## Troubleshooting

1. If the virtual video device is in use:
   ```bash
   sudo fuser -k /dev/video1
   ```

2. If systemd service fails to start:
   ```bash
   sudo systemctl status rtsp-to-v4l2.service
   journalctl -u rtsp-to-v4l2.service -f
   ```

3. Verify v4l2loopback module is loaded:
   ```bash
   lsmod | grep v4l2loopback
   ```