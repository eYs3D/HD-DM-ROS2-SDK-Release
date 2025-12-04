#!/bin/bash

# Docker build helper script for eYs3D ROS2 SDK
# Purpose: Build the Docker image with appropriate flags and tagging

set -e

# Configuration
DOCKERFILE_PATH="Dockerfile"
IMAGE_NAME="${IMAGE_NAME:-eys3d/ros2-foxy}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Verify Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    exit 1
fi

log_info "Starting Docker build process..."
log_info "Image: ${FULL_IMAGE_NAME}"
log_info "Dockerfile: ${DOCKERFILE_PATH}"
log_info "Build Context: ${BUILD_CONTEXT}"

# Build the image
log_info "Building Docker image..."
docker build \
    --file "${BUILD_CONTEXT}/${DOCKERFILE_PATH}" \
    --tag "${FULL_IMAGE_NAME}" \
    --progress=plain \
    "${BUILD_CONTEXT}"

if [ $? -eq 0 ]; then
    log_info "Docker image built successfully!"
    log_info "Image Details:"
    docker images "${IMAGE_NAME}"

    log_info ""
    log_info "Next steps:"
    log_info "1. Build the workspace: docker/run.sh colcon build --symlink-install"
    log_info "2. Run the camera node: docker/run.sh ros2 launch dm_preview apc_camera_launch.py"
    log_info "3. Or use docker-compose: docker-compose up -d && docker-compose exec ros2-foxy bash"
else
    log_error "Docker build failed!"
    exit 1
fi
