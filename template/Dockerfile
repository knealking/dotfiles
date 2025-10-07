# Use Ubuntu as the base image
FROM ubuntu:22.04

# Update package lists and install essential C development tools
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    gdb \
    make \
    cmake \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Create a new user 'nealking' and set up their home directory
RUN useradd -m -s /bin/zsh nealking && \
    chown -R nealking:nealking /home/nealking

# Set up a working directory and give ownership to nealking
WORKDIR /workspace
RUN chown -R nealking:nealking /workspace

# Switch to the new user
USER nealking

# Set zsh as the default shell
SHELL ["/bin/bash", "-c"]

# Command to run when container starts
CMD ["/bin/bash"]
