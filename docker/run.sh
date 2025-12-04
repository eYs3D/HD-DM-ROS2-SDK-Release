#!/bin/bash

# Docker run helper script for eYs3D ROS2 SDK
# Purpose: Run the Docker container with proper X11, USB, and volume configuration

set -e

# Configuration
IMAGE_NAME="${IMAGE_NAME:-eys3d/ros2-foxy}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
CONTAINER_NAME="${CONTAINER_NAME:-eys3d-ros2-foxy-dev}"

# Get the directory where this script is located (project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if image exists
if ! docker image inspect "${FULL_IMAGE_NAME}" > /dev/null 2>&1; then
    log_error "Docker image '${FULL_IMAGE_NAME}' not found"
    log_info "Run './docker/build.sh' to build the image first"
    exit 1
fi

# Prepare X11 access for GUI applications
if [ -z "$DISPLAY" ]; then
    log_warn "DISPLAY is not set. GUI applications (RViz) may not work"
else
    log_info "X11 Display: $DISPLAY"
    # Ensure X11 socket is accessible
    if [ ! -e /tmp/.X11-unix ]; then
        log_warn "/tmp/.X11-unix does not exist. X11 forwarding may not work"
    fi
    # Try to set XAUTHORITY
    if [ -z "$XAUTHORITY" ]; then
        export XAUTHORITY=$HOME/.Xauthority
        log_debug "Set XAUTHORITY=$XAUTHORITY"
    fi
fi

# Build docker run command
log_info "Preparing container environment..."

RUN_COMMAND="docker run"

# Interactive terminal
RUN_COMMAND="${RUN_COMMAND} -it"

# Container naming
RUN_COMMAND="${RUN_COMMAND} --name ${CONTAINER_NAME}"

# Network - use host network for best ROS2 communication
RUN_COMMAND="${RUN_COMMAND} --network host"

# Environment variables
RUN_COMMAND="${RUN_COMMAND} -e ROS_DISTRO=foxy"
RUN_COMMAND="${RUN_COMMAND} -e RMW_IMPLEMENTATION=rmw_fastrtps_cpp"
RUN_COMMAND="${RUN_COMMAND} -e ROS_DOMAIN_ID=0"

# X11 Display forwarding
if [ -n "$DISPLAY" ]; then
    RUN_COMMAND="${RUN_COMMAND} -e DISPLAY=${DISPLAY}"
    RUN_COMMAND="${RUN_COMMAND} -e QT_X11_NO_MITSHM=1"
    RUN_COMMAND="${RUN_COMMAND} -v /tmp/.X11-unix:/tmp/.X11-unix:rw"

    if [ -f "$XAUTHORITY" ]; then
        RUN_COMMAND="${RUN_COMMAND} -v ${XAUTHORITY}:/home/ros/.Xauthority:ro"
    fi
fi

# Volume mounts
RUN_COMMAND="${RUN_COMMAND} -v ${SCRIPT_DIR}:/home/ros/workspace:rw"
RUN_COMMAND="${RUN_COMMAND} -v ros-eys3d-logs:/home/ros/.ros/log"

# USB device access
RUN_COMMAND="${RUN_COMMAND} -v /dev/bus/usb:/dev/bus/usb:rw"

# Video devices (if available)
if [ -e /dev/video0 ]; then
    RUN_COMMAND="${RUN_COMMAND} -v /dev/video0:/dev/video0:rw"
fi
if [ -e /dev/video1 ]; then
    RUN_COMMAND="${RUN_COMMAND} -v /dev/video1:/dev/video1:rw"
fi

# Working directory
RUN_COMMAND="${RUN_COMMAND} -w /home/ros/workspace"

# Image name
RUN_COMMAND="${RUN_COMMAND} ${FULL_IMAGE_NAME}"

# Command to run in container
if [ $# -gt 0 ]; then
    # If arguments provided, use them as command
    RUN_COMMAND="${RUN_COMMAND} bash -c '$@'"
    log_info "Running command in container: $@"
else
    # Otherwise, drop to interactive bash
    log_info "Starting interactive bash shell in container"
    log_info "Source ROS2: source /opt/ros/foxy/setup.bash"
    log_info "Build workspace: colcon build --symlink-install"
    log_info "Run camera node: ros2 launch dm_preview apc_camera_launch.py"
fi

log_debug "Docker command: ${RUN_COMMAND}"
log_info "Starting container '${CONTAINER_NAME}'..."

# Execute the docker run command
eval "${RUN_COMMAND}"
