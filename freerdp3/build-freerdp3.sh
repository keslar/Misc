#!/bin/bash
set -e

# FreeRDP3 X11 Build Script for Ubuntu Jammy (22.04)
# Based on: https://github.com/FreeRDP/FreeRDP/wiki/Compilation

echo "======================================"
echo "FreeRDP3 X11 Build Script"
echo "Ubuntu Jammy (22.04)"
echo "======================================"

# Set build directory
BUILD_DIR="$HOME/freerdp-build"
INSTALL_PREFIX="/usr/local"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo ""
echo "Step 1: Installing dependencies..."
echo "======================================"
sudo apt-get update
sudo apt-get install -y \
    ninja-build \
    build-essential \
    git-core \
    cmake \
    pkg-config \
    libssl-dev \
    libxkbfile-dev \
    libx11-dev \
    libxrandr-dev \
    libxi-dev \
    libxrender-dev \
    libxext-dev \
    libxinerama-dev \
    libxfixes-dev \
    libxcursor-dev \
    libxv-dev \
    libxdamage-dev \
    libxtst-dev \
    libcups2-dev \
    libpcsclite-dev \
    libasound2-dev \
    libpulse-dev \
    libusb-1.0-0-dev \
    uuid-dev \
    libfuse3-dev \
    libswscale-dev \
    libcairo2-dev \
    libavutil-dev \
    libavcodec-dev \
    libswresample-dev \
    liburiparser-dev \
    libkrb5-dev \
    libsystemd-dev \
    libcjson-dev \
    libpkcs11-helper1-dev \
    libgsm1-dev \
    libopus-dev \
    libmp3lame-dev \
    libsoxr-dev \
    libpam0g-dev

# Try to install Wayland dependencies (optional, won't fail if not available)
sudo apt-get install -y \
    libwayland-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    wayland-protocols || echo "Wayland packages not available, will build without Wayland support"

echo ""
echo "Step 2: Cloning FreeRDP repository..."
echo "======================================"

# Configure git for better timeout handling
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

if [ -d "freerdp" ]; then
    echo "FreeRDP directory exists. Cleaning and updating..."
    cd freerdp
    git fetch --all || {
        echo "Fetch failed, trying to re-clone..."
        cd ..
        rm -rf freerdp
    }
    if [ -d ".git" ]; then
        git reset --hard origin/master
        cd ..
    fi
fi

if [ ! -d "freerdp" ]; then
    echo "Cloning with retry logic..."
    MAX_RETRIES=3
    RETRY_COUNT=0
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        echo "Attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES..."
        
        if git clone --depth 1 https://github.com/freerdp/freerdp.git; then
            echo "Clone successful!"
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo "Clone failed. Waiting 10 seconds before retry..."
                sleep 10
            else
                echo "ERROR: Failed to clone repository after $MAX_RETRIES attempts"
                echo "Please check your internet connection and try again"
                exit 1
            fi
        fi
    done
fi

echo ""
echo "Step 3: Configuring FreeRDP build with CMake..."
echo "======================================"

# Check if Wayland dependencies are available
if pkg-config --exists xkbcommon wayland-client 2>/dev/null; then
    echo "Wayland support: ENABLED"
    WAYLAND_OPTION="-DWITH_WAYLAND=ON"
else
    echo "Wayland support: DISABLED (dependencies not found)"
    WAYLAND_OPTION="-DWITH_WAYLAND=OFF"
fi

cmake -GNinja \
    -B "$BUILD_DIR/freerdp-build" \
    -S "$BUILD_DIR/freerdp" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DWITH_X11=ON \
    -DWITH_XINERAMA=ON \
    -DWITH_XEXT=ON \
    -DWITH_XCURSOR=ON \
    -DWITH_XV=ON \
    -DWITH_XI=ON \
    -DWITH_XRENDER=ON \
    -DWITH_XRANDR=ON \
    -DWITH_XFIXES=ON \
    -DWITH_CUPS=ON \
    -DWITH_PCSC=ON \
    -DWITH_PULSE=ON \
    -DWITH_ALSA=ON \
    -DWITH_FFMPEG=ON \
    -DWITH_SWSCALE=ON \
    -DWITH_DSP_FFMPEG=ON \
    -DWITH_FUSE=ON \
    -DWITH_KRB5=ON \
    $WAYLAND_OPTION \
    -DWITH_SERVER=ON \
    -DWITH_SAMPLE=ON \
    -DCHANNEL_URBDRC=ON \
    -DBUILD_TESTING=OFF

echo ""
echo "Step 4: Building FreeRDP..."
echo "======================================"
cmake --build "$BUILD_DIR/freerdp-build" -j$(nproc)

echo ""
echo "Step 5: Installing FreeRDP..."
echo "======================================"
sudo cmake --install "$BUILD_DIR/freerdp-build"

echo ""
echo "Step 6: Updating library cache..."
echo "======================================"
sudo ldconfig

echo ""
echo "======================================"
echo "Build completed successfully!"
echo "======================================"
echo "FreeRDP3 has been installed to: $INSTALL_PREFIX"
echo "You can now run: xfreerdp3 /help"
echo "Build directory: $BUILD_DIR"
echo ""
