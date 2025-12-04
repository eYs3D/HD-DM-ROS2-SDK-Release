# Docker Setup for eYs3D ROS2 SDK

This directory contains Docker configuration and helper scripts for running the eYs3D ROS2 SDK on JetPack 6 systems with ROS2 Foxy support.

## Overview

- **Problem Solved**: JetPack 6.2.1 ships with ROS2 Jazzy, but the eYs3D SDK requires ROS2 Foxy (Ubuntu 20.04)
- **Solution**: Docker container with Ubuntu 20.04 and ROS2 Foxy
- **Supported Platforms**: aarch64 (Jetson) and x86_64 architectures
- **Base Image**: Ubuntu 20.04 (official)

## Quick Start

### Prerequisites

- **USB3 Port Required**: The eYs3D depth camera must be connected to a USB 3.0 port for proper operation. USB 2.0 ports will not provide sufficient bandwidth.
- X11 display server running on host
- Docker installed and running

### 1. Build the Docker Image

```bash
cd /home/eys3d/HD-DM-ROS2-SDK-Release
./docker/build.sh
```

This builds a Docker image with:
- Ubuntu 20.04 base image
- ROS2 Foxy (desktop variant)
- All required dependencies from `package.xml`
- X11 support for RViz visualization
- USB device access for camera hardware
- OpenCV and cv_bridge libraries

**Build Time**: 10-20 minutes (depends on internet speed and system performance)

### 2. Run the Container

#### Option A: Interactive Shell (Recommended for Development)

```bash
# Allow X11 connections from Docker
xhost +local:docker

# Start interactive container
docker run -it --rm \
  --privileged \
  --network host \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v /dev/bus/usb:/dev/bus/usb \
  -v $(pwd):/home/ros/workspace:rw \
  -w /home/ros/workspace \
  --user root \
  eys3d/ros2-foxy:latest \
  bash
```

This starts an interactive bash shell with:
- Source code mounted at `/home/ros/workspace`
- X11 display forwarding configured
- USB devices accessible (privileged mode)
- ROS2 Foxy environment pre-configured
- Host network mode for ROS2 communication
- Root user for proper permissions on eYs3D config directory

Inside the container:
```bash
# Source ROS2 environment
source /opt/ros/foxy/setup.bash
source install/setup.bash

# Run the camera node with RViz
ros2 launch dm_preview apc_camera_launch.py

# Or run just the camera node
ros2 run dm_preview apc_camera_node

# Run the listener node (in another terminal)
ros2 run dm_preview apc_camera_listener_node

# Check topic publish rate
ros2 topic hz /apc/left/image_color

# List all topics
ros2 topic list -v
```

#### Option B: Single Command Execution

```bash
./docker/run.sh colcon build --symlink-install
./docker/run.sh ros2 launch dm_preview apc_camera_launch.py
```

#### Option C: Docker Compose

```bash
# Start the container in background
docker-compose up -d

# Access the container
docker-compose exec ros2-foxy bash

# Stop the container
docker-compose down
```

## Script Details

### `build.sh`

Builds the Docker image from the Dockerfile with proper error handling and logging.

**Features**:
- Automatic Docker installation verification
- Image naming and tagging support
- Progress reporting and error handling
- Post-build summary with next steps

**Usage**:
```bash
# Default behavior
./docker/build.sh

# Custom image name and tag
IMAGE_NAME=mycompany/eys3d IMAGE_TAG=v1.0 ./docker/build.sh

# Specify different build context
BUILD_CONTEXT=/path/to/repo ./docker/build.sh
```

### `run.sh`

Runs the Docker container with all necessary configurations for development and testing.

**Features**:
- Automatic image existence verification
- X11 display forwarding for RViz
- USB device mounting for camera access
- Volume mounts for source code and logs
- Host network mode for optimal ROS2 communication
- Support for command execution or interactive shell
- Detailed logging and debug information

**Usage**:
```bash
# Interactive shell
./docker/run.sh

# Run specific command
./docker/run.sh colcon build --symlink-install

# Run with custom image name
IMAGE_NAME=custom/image ./docker/run.sh

# Multiple commands
./docker/run.sh "source /opt/ros/foxy/setup.bash && colcon build --symlink-install"
```

## Docker Configuration

### Dockerfile Components

**Multi-stage Build**:
- Stage 1 (builder): Minimal build environment setup
- Stage 2 (runtime): Optimized runtime with only necessary packages

**Key Features**:
- Non-root user (`ros`) for security
- ROS2 Foxy from official ROS repositories
- All dependencies from `package.xml`:
  - rclcpp, rclcpp_components
  - sensor_msgs, std_msgs
  - tf2, tf2_ros
  - image_transport, cv_bridge
  - OpenCV (libopencv-dev)
  - rviz2
  - launch_ros
- X11 display support for GUI applications
- USB device access configuration
- Pre-sourced ROS2 environment in `.bashrc`
- Automatic workspace detection and sourcing

### docker-compose.yml Configuration

**Services**:
- `ros2-foxy`: Main ROS2 development container

**Key Settings**:
- `network_mode: host`: Optimal for ROS2 DDS communication
- `stdin_open: true` & `tty: true`: Interactive terminal support
- Volume mounts:
  - Source code: `./` → `/home/ros/workspace` (read-write)
  - X11: `/tmp/.X11-unix` (for RViz)
  - Logs: Named volume for persistence
- Device access:
  - `/dev/bus/usb`: USB camera access
  - `/dev/video0`, `/dev/video1`: Video devices
- Resource limits:
  - CPU: 2-4 cores
  - Memory: 2-4 GB
- Environment variables:
  - ROS2 distribution and domain ID
  - X11 configuration

## Requirements

### Host System
- Docker installed and running
- Sufficient disk space: 5-10 GB (includes image and workspace)
- USB camera connected to host (will be forwarded to container)
- X11 server running (for RViz visualization)

### Permission Requirements
- User must be in `docker` group (to run without sudo)
- USB device access may require appropriate udev rules or elevated privileges

### Network
- Host network access from container (required for ROS2 communication)

## Troubleshooting

### X11 Display Not Working

**Problem**: "Cannot connect to X server" or RViz doesn't open

**Solutions**:
```bash
# Check DISPLAY variable
echo $DISPLAY

# If empty, set it manually
export DISPLAY=:0

# Allow docker containers to connect to X server
xhost +local:docker

# Verify with simple X11 app
./docker/run.sh xclock
```

### USB Device Not Detected

**Problem**: Camera not visible in container

**Solutions**:
```bash
# Check USB devices on host
lsusb

# Inside container, verify USB mount
ls -la /dev/bus/usb/

# Run with explicit device permissions
# Edit docker/run.sh or docker-compose.yml to add --privileged flag if necessary
```

**Note**: The `eYs3D wrapper` library compatibility with JetPack 6 kernel has NOT been verified. You may need to rebuild or obtain updated libraries.

### Container Fails to Start

**Problem**: "Docker image not found"

**Solution**:
```bash
# Build the image first
./docker/build.sh

# Verify image exists
docker images | grep eys3d
```

### Permission Denied Errors

**Problem**: "permission denied while trying to connect to Docker daemon"

**Solution**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply new group without logout
newgrp docker

# Verify
docker ps
```

### Low Disk Space

**Problem**: Build fails with "no space left on device"

**Solution**:
```bash
# Check disk space
df -h

# Clean up unused Docker resources
docker system prune -a

# Remove unused images/containers
docker rmi <image_id>
```

## Building and Deployment Workflow

### Development Workflow

```bash
# 1. Build Docker image (one-time)
./docker/build.sh

# 2. Start interactive development shell
./docker/run.sh

# 3. Inside container:
colcon build --symlink-install
source install/setup.bash
ros2 launch dm_preview apc_camera_launch.py
```

### Automated Build Workflow

```bash
# Use docker-compose for automated setup
docker-compose up -d

# Access container for commands
docker-compose exec ros2-foxy colcon build --symlink-install
docker-compose exec ros2-foxy ros2 launch dm_preview apc_camera_launch.py
```

### CI/CD Integration

For GitHub Actions or other CI/CD systems:

```bash
# Build the image
./docker/build.sh

# Build inside container
./docker/run.sh "colcon build --symlink-install"

# Run tests
./docker/run.sh "colcon test"
```

## Image Specifications

- **Base Image**: ubuntu:20.04 (aarch64/x86_64 compatible)
- **Image Size**: ~2-3 GB (optimized with multi-stage build)
- **ROS Version**: Foxy (LTS)
- **Python Version**: 3.8+
- **Non-root User**: `ros` (UID 1000)
- **Default Shell**: bash with pre-sourced ROS2 environment

## Environment Variables

Inside the container:

```bash
ROS_DISTRO=foxy
RMW_IMPLEMENTATION=rmw_fastrtps_cpp
ROS_DOMAIN_ID=0
COLCON_DEFAULTS_BUILD_SPACE_HIDDEN=1
```

Customize via:

```bash
# In docker/run.sh
RUN_COMMAND="${RUN_COMMAND} -e MY_VAR=value"

# Or in docker-compose.yml
environment:
  - MY_VAR=value
```

## Performance Tuning

### Increase Resource Allocation

Edit `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      cpus: '6'
      memory: 8G
```

Or use environment variables:
```bash
DOCKER_MEMORY=4g ./docker/run.sh
```

### Optimize Build Performance

```bash
# Use symlink install for faster development iteration
colcon build --symlink-install

# Build only modified packages
colcon build --packages-select dm_preview

# Use build cache
docker build --cache-from eys3d/ros2-foxy:latest ...
```

## Known Issues

1. **eYs3D Wrapper Library Compatibility**: The prebuilt libraries in `dm_preview/eYs3D_wrapper/lib/` were built for specific kernel versions. Compatibility with JetPack 6 kernel has NOT been verified.

2. **X11 Forwarding on SSH**: If accessing the host via SSH, X11 forwarding must be enabled:
   ```bash
   ssh -X user@host
   ```

3. **USB Permissions**: Some systems may require elevated privileges or udev rule configuration for USB access. See troubleshooting section.

## Security Considerations

- Container runs as non-root user (`ros`) for better security
- USB device access is explicitly configured (not full privileged mode)
- X11 socket mounted read-write for display forwarding
- Network uses host mode (required for ROS2 DDS, consider security implications)

## Additional Resources

- [ROS2 Foxy Documentation](https://docs.ros.org/en/foxy/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [eYs3D SDK Documentation](https://github.com/eYs3D/HD-DM-ROS2-SDK-Release)

## Support

For issues related to:
- **Docker setup**: Check troubleshooting section above
- **ROS2 Foxy**: See ROS2 documentation
- **eYs3D SDK**: See main repository README and CLAUDE.md
