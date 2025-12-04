# ROS2 Humble Installation Guide

This guide covers installing ROS2 Humble on Ubuntu 22.04 (JetPack 6) for the eYs3D ROS2 SDK.

## Prerequisites

- Ubuntu 22.04 (Jammy)
- USB 3.0 port for camera

## 1. Install ROS2 Humble

```bash
# Download and install ROS2 apt source package
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
sudo dpkg -i /tmp/ros2-apt-source.deb

# Update and install ROS2 Humble desktop
sudo apt update
sudo apt install -y ros-humble-desktop
```

### If you have GPG key conflicts

If you see errors about conflicting `Signed-By` values, remove the old ROS2 sources:

```bash
sudo rm /etc/apt/sources.list.d/ros2.list
sudo rm -f /usr/share/keyrings/ros-archive-keyring.gpg
sudo apt update
```

## 2. Install Additional Dependencies

```bash
sudo apt install -y ros-humble-stereo-msgs
```

## 3. Disable pyenv (if installed)

If you have pyenv installed, it conflicts with ROS2 build tools. Comment out these lines in `~/.bashrc`:

```bash
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init --path)"
# eval "$(pyenv init -)"
```

Then open a new terminal or logout/login.

## 4. Build the Workspace

```bash
cd ~/HD-DM-ROS2-SDK-Release

# Clean previous builds (important if previously built with Foxy)
rm -rf build/ install/ log/

# Source ROS2 Humble
source /opt/ros/humble/setup.bash

# Build
colcon build --symlink-install

# Source the workspace
source install/setup.bash
```

## 5. Run the Camera Node

```bash
# Make sure to source both ROS2 and workspace
source /opt/ros/humble/setup.bash
source install/setup.bash

# Launch with RViz
ros2 launch dm_preview apc_camera_launch.py

# Or run node only
ros2 run dm_preview apc_camera_node
```

## 6. Verify Camera is Working

```bash
# Check topics are publishing
ros2 topic list

# Check publish rate
ros2 topic hz /apc/left/image_color

# Expected topics:
# /apc/left/image_color
# /apc/depth/image_raw
# /apc/points/data_raw
# /apc/imu/data_raw
```

## Troubleshooting

### Camera not detected

- Ensure camera is connected to USB 3.0 port (USB 2.0 will not work properly)
- Check USB permissions: `ls -la /dev/video*`

### Build fails with "No module named 'catkin_pkg'"

This means pyenv is intercepting Python. See Step 3 above to disable pyenv.

### Build fails with missing package

Install the missing ROS2 package:
```bash
sudo apt install ros-humble-<package-name>
```

## Migration Notes

This repository was migrated from ROS2 Foxy to Humble. Key changes:
- `set_on_parameters_set_callback()` → `add_on_set_parameters_callback()`
- `tf2_geometry_msgs/tf2_geometry_msgs.h` → `.hpp`

See commit `[Migrate] Update API for ROS2 Humble compatibility` for details.
