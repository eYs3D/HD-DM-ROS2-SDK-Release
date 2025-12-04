# Dockerfile for eYs3D ROS2 SDK
# Target: ROS2 Foxy on Ubuntu 20.04
# Supports aarch64 (Jetson) and x86_64 architectures
#
# Build: docker build -t eys3d/ros2-foxy:latest .
# Run:   ./docker/run.sh

FROM ubuntu:20.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=foxy
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install essential tools and locales first
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    curl \
    gnupg2 \
    lsb-release \
    ca-certificates \
    software-properties-common \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Add ROS2 GPG key and repository
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu focal main" > /etc/apt/sources.list.d/ros2.list

# Install ROS2 Foxy desktop and all required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # ROS2 Foxy Desktop (includes rviz2, rqt, demos)
    ros-foxy-desktop \
    # Additional ROS2 packages required by dm_preview
    ros-foxy-rclcpp \
    ros-foxy-rclcpp-components \
    ros-foxy-sensor-msgs \
    ros-foxy-std-msgs \
    ros-foxy-cv-bridge \
    ros-foxy-image-transport \
    ros-foxy-tf2 \
    ros-foxy-tf2-ros \
    ros-foxy-tf2-geometry-msgs \
    ros-foxy-launch-ros \
    ros-foxy-stereo-msgs \
    ros-foxy-geometry-msgs \
    # Build tools
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-argcomplete \
    build-essential \
    cmake \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install additional dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # OpenCV (required for cv_bridge and image processing)
    libopencv-dev \
    python3-opencv \
    # X11 display support for RViz
    libx11-6 \
    libxext6 \
    libxrender1 \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    # USB device access for camera
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    usbutils \
    # Development tools
    vim \
    nano \
    wget \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init && rosdep update --rosdistro foxy

# Create non-root user for running the application
RUN useradd -m -s /bin/bash -G video,plugdev ros

# Create workspace directory
RUN mkdir -p /home/ros/workspace && \
    chown -R ros:ros /home/ros

# Set up ROS2 environment in bashrc
RUN echo 'source /opt/ros/foxy/setup.bash' >> /home/ros/.bashrc && \
    echo 'if [ -f /home/ros/workspace/install/setup.bash ]; then source /home/ros/workspace/install/setup.bash; fi' >> /home/ros/.bashrc && \
    echo 'export ROS_DOMAIN_ID=0' >> /home/ros/.bashrc

# Set environment variables for runtime
ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp
ENV ROS_DOMAIN_ID=0

# Switch to non-root user
USER ros
WORKDIR /home/ros/workspace

# Default command: start bash shell with ROS2 environment sourced
CMD ["/bin/bash"]
