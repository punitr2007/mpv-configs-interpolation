# Real-Time Frame Interpolation Playback Tool for mpv

This repository contains the configuration files and scripts to enable real-time 2x frame interpolation in `mpv` using VapourSynth and the ncnn-Vulkan RIFE engine. It is optimized for hybrid-graphics laptops (e.g., AMD iGPU + NVIDIA RTX 3050).

---

## 1. Files in this Repository

Copy these files to your `mpv` configuration directory:
*   `mpv.conf` -> `mpv.conf`
*   `rife_interp.vpy` -> `rife_interp.vpy`
*   `rife_settings.json` -> `rife_settings.json`
*   `scripts/rife_toggle.lua` -> `scripts/rife_toggle.lua`

---

## 2. Platform Installation Guides

### Option A: Linux (Arch / CachyOS)

1.  **Install core packages and AUR plugins**:
    ```bash
    sudo pacman -S mpv vapoursynth ncnn
    yay -S vapoursynth-plugin-rife-ncnn-vulkan vapoursynth-plugin-misc-git
    ```

2.  **Symlink VapourSynth Plugins (Python 3.14+)**:
    ```bash
    sudo ln -sf /usr/lib/vapoursynth/librife.so /usr/lib/python3.14/site-packages/vapoursynth/plugins/librife.so
    sudo ln -sf /usr/lib/vapoursynth/models /usr/lib/python3.14/site-packages/vapoursynth/plugins/models
    ```

3.  **VapourSynth Python Initialization Fix**:
    Run `vapoursynth config` to write the base file, then edit `/home/USERNAME/.config/vapoursynth/vapoursynth.toml` to add system library path mappings:
    ```toml
    "/usr/lib/python3.14/site-packages/vapoursynth/libvsscript.so" = ["/usr/bin/python","/usr/lib/libpython3.14.so.1.0"]
    "/usr/lib/libvapoursynth-script.so.0" = ["/usr/bin/python","/usr/lib/libpython3.14.so.1.0"]
    "/usr/lib/libvapoursynth-script.so" = ["/usr/bin/python","/usr/lib/libpython3.14.so.1.0"]
    ```

---

### Option B: Android (via Termux Linux)

1.  **Install Termux & Termux-X11**:
    *   Install **Termux** (get the APK from F-Droid or GitHub).
    *   Install **Termux-X11** (available on GitHub under `termux/termux-x11`).

2.  **Install Ubuntu container in Termux**:
    ```bash
    pkg update && pkg upgrade -y
    pkg install proot-distro -y
    proot-distro install ubuntu
    proot-distro login ubuntu
    ```

3.  **Install GPU Drivers (Mesa Turnip + Zink) inside Ubuntu**:
    ```bash
    apt update && apt upgrade -y
    apt install mesa-vulkan-drivers vulkan-tools -y
    ```

4.  **Install mpv, VapourSynth, & compile the RIFE plugin**:
    ```bash
    # Enable universe repository
    apt install software-properties-common -y
    add-apt-repository universe
    apt update

    # Install compilers and tools
    apt install mpv vapoursynth python3-pip git cmake g++ meson ninja-build -y

    # Compile RIFE ncnn-Vulkan
    git clone --recursive https://github.com/styler00dollar/VapourSynth-RIFE-ncnn-Vulkan.git
    cd VapourSynth-RIFE-ncnn-Vulkan
    meson setup build --buildtype=release -Duse_system_ncnn=false
    meson compile -C build
    meson install -C build
    ```

5.  **Copy configurations**:
    Copy these configuration files into the container's `/root/.config/mpv/` directory.

6.  **Run the player**:
    Start Termux-X11 on your phone, then run:
    ```bash
    termux-x11 :1 &
    export DISPLAY=:1
    mpv --vo=gpu --gpu-context=x11vk "video.mp4"
    ```

---

### Option C: Windows Setup

1.  **Install Python & VapourSynth**:
    *   Install **Python 3.12 or 3.11** from `python.org` (make sure to check "Add Python to PATH").
    *   Install **VapourSynth** (.exe installer) from `vapoursynth.com`.

2.  **Install RIFE ncnn-Vulkan plugin**:
    *   Download the Windows release zip from [VapourSynth-RIFE-ncnn-Vulkan Releases](https://github.com/styler00dollar/VapourSynth-RIFE-ncnn-Vulkan/releases).
    *   Copy `rife.dll` and the `models` folder to `C:\Program Files\VapourSynth\plugins\` (or `%APPDATA%\VapourSynth\plugins\`).

3.  **Set up mpv**:
    *   Download the portable windows build of `mpv` from `mpv.io` and extract it.

4.  **Copy configurations**:
    *   Press `Win+R`, type `%APPDATA%` and open the `mpv` folder.
    *   Copy `mpv.conf`, `rife_interp.vpy`, `rife_settings.json`, and `scripts/rife_toggle.lua` into `%APPDATA%\mpv\`.

---

## 3. How to Play & Control

Open your video file using `mpv`:
*   **Linux/Android**: `mpv video.mp4`
*   **Windows**: Drag & drop video file onto `mpv.exe`

### Control Hotkeys:
*   `Ctrl+I`: **Toggle Frame Interpolation** instantly on/off.
*   `Ctrl+M`: **Open the Interactive Settings Menu** overlay.
    *   Use `Up/Down` arrow keys to navigate the menu options.
    *   Use `Left/Right` arrow keys to change the value (e.g. adjust thread counts or choose models).
    *   Press `Enter` to save settings and reload the filter graph immediately.
    *   Press `Esc` to close the overlay.
