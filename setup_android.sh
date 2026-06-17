#!/bin/bash
# VapourSynth & RIFE ncnn-Vulkan Automated Installer for Termux (Ubuntu Container)
set -e

echo "========================================================"
echo " Starting VapourSynth + RIFE Automated Installer"
echo "========================================================"

echo "[1/5] Updating package databases..."
apt update && apt upgrade -y

echo "[2/5] Installing software-properties-common & adding Universe..."
apt install software-properties-common -y
add-apt-repository universe -y
apt update

echo "[3/5] Installing core dependencies (mpv, python, compilers)..."
apt install -y mpv vapoursynth python3-pip git cmake g++ meson ninja-build libvulkan-dev

echo "[4/5] Cloning and compiling VapourSynth-RIFE-ncnn-Vulkan..."
if [ ! -d "VapourSynth-RIFE-ncnn-Vulkan" ]; then
    git clone --recursive https://github.com/styler00dollar/VapourSynth-RIFE-ncnn-Vulkan.git
fi
cd VapourSynth-RIFE-ncnn-Vulkan
# Clear any prior build configurations
rm -rf build
meson setup build --buildtype=release -Duse_system_ncnn=false
meson compile -C build
meson install -C build
cd ..

echo "[5/5] Detecting Python version and creating plugin symlinks..."
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo " -> Detected Python Version: $PYTHON_VERSION"

# Locate site-packages / dist-packages directory
SITE_PACKAGES=""
if [ -d "/usr/lib/python${PYTHON_VERSION}/site-packages/vapoursynth" ]; then
    SITE_PACKAGES="/usr/lib/python${PYTHON_VERSION}/site-packages/vapoursynth"
elif [ -d "/usr/lib/python3/dist-packages/vapoursynth" ]; then
    SITE_PACKAGES="/usr/lib/python3/dist-packages/vapoursynth"
else
    # Fallback to creating standard path
    SITE_PACKAGES="/usr/lib/python${PYTHON_VERSION}/site-packages/vapoursynth"
fi

mkdir -p "$SITE_PACKAGES/plugins"
ln -sf /usr/lib/vapoursynth/librife.so "$SITE_PACKAGES/plugins/librife.so"
ln -sf /usr/lib/vapoursynth/models "$SITE_PACKAGES/plugins/models"

echo "[6/5] Generating VapourSynth library mapping config (vapoursynth.toml)..."
mkdir -p ~/.config/vapoursynth
LIBPYTHON=$(find /usr/lib -name "libpython${PYTHON_VERSION}*.so*" | head -n 1)

if [ -z "$LIBPYTHON" ]; then
    echo " -> [Warning] libpython shared library not found in /usr/lib. Searching globally..."
    LIBPYTHON=$(find / -name "libpython${PYTHON_VERSION}*.so*" 2>/dev/null | head -n 1)
fi

echo " -> Found python library at: $LIBPYTHON"

cat <<EOF > ~/.config/vapoursynth/vapoursynth.toml
"/usr/lib/python${PYTHON_VERSION}/site-packages/vapoursynth/libvsscript.so" = ["/usr/bin/python3","$LIBPYTHON"]
"/usr/lib/libvapoursynth-script.so.0" = ["/usr/bin/python3","$LIBPYTHON"]
"/usr/lib/libvapoursynth-script.so" = ["/usr/bin/python3","$LIBPYTHON"]
EOF

echo "========================================================"
echo " Setup Completed Successfully!"
echo "========================================================"
echo "Next Steps:"
echo "1. Create the mpv configuration directories inside your container:"
echo "   mkdir -p ~/.config/mpv/scripts/"
echo ""
echo "2. Copy the config files from your SmartPlayer directory into the container:"
echo "   cp mpv.conf ~/.config/mpv/mpv.conf"
echo "   cp rife_interp.vpy ~/.config/mpv/rife_interp.vpy"
echo "   cp rife_settings.json ~/.config/mpv/rife_settings.json"
echo "   cp scripts/rife_toggle.lua ~/.config/mpv/scripts/rife_toggle.lua"
echo ""
echo "3. Run 'termux-x11 :1 &' in Termux, open the Termux-X11 app, and launch mpv:"
echo "   export DISPLAY=:1"
echo "   mpv --vo=gpu --gpu-context=x11vk \"video.mp4\""
echo "========================================================"
