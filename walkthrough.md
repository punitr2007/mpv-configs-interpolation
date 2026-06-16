# Real-Time Frame Interpolation Playback Tool Walkthrough

I have built and configured a real-time frame interpolation tool using **mpv**, **VapourSynth**, and the Vulkan-optimized **RIFE-ncnn-Vulkan** plugin.

Here is a summary of what was completed:

---

## 1. System Packages & Setup
1. **Installed VapourSynth Plugins**:
   - `vapoursynth-plugin-rife-ncnn-vulkan`: Standard ncnn Vulkan plugin for RIFE models.
   - `vapoursynth-plugin-misc-git`: For scene change detection (`misc.SCDetect`), avoiding ghosting across cuts.
2. **Environment Integration**:
   - Created symbolic links for `librife.so` and the `models` folder to `/usr/lib/python3.14/site-packages/vapoursynth/plugins/` so that VapourSynth autoloads the RIFE filter natively under Python 3.14.
3. **VapourSynth R76 / CachyOS Python Initialization Fix**:
   - Created the configuration file [vapoursynth.toml](file:///home/punit/.config/vapoursynth/vapoursynth.toml).
   - *Rationale*: VapourSynth R76 requires explicit mapping files to bind VSScript shared libraries to the Python runtime. Since `mpv` links to `/usr/lib/libvapoursynth-script.so.0` rather than the Python site-packages library, adding these mapping keys resolves the `[vapoursynth] Could not initialize VapourSynth scripting` error.

---

## 2. Configuration & Control Scripts
I created the following configuration files in your `~/.config/mpv/` directory:

- [mpv.conf](file:///home/punit/.config/mpv/mpv.conf): Configures `mpv` to enable NVIDIA hardware decoding (`nvdec`), frame presentation matching (`display-resample`), and pitch-corrected audio.
- [rife_interp.vpy](file:///home/punit/.config/mpv/rife_interp.vpy): VapourSynth script that handles scene detection, format conversion, and runs the RIFE interpolation filter. It dynamically reads user preferences from the local settings JSON.
- [rife_settings.json](file:///home/punit/.config/mpv/rife_settings.json): Stores your active configuration, letting you tweak performance and quality parameters at runtime.
- [rife_toggle.lua](file:///home/punit/.config/mpv/scripts/rife_toggle.lua): Implements an interactive **On-Screen Display (OSD) Settings Menu** and binds shortcuts.

---

## 3. How to Use & Control

To play any video file and test the tool, run `mpv` normally:
```bash
mpv /path/to/your/video.mp4
```

### Hotkeys:
*   `Ctrl+I`: **Toggle Interpolation** instantly on/off during playback.
*   `Ctrl+M`: **Open the Settings Menu** overlay.

### Settings Menu Navigation:
*   `Up` / `Down` Arrow Keys: Move selection cursor (`▶`).
*   `Left` / `Right` Arrow Keys: Change option value.
*   `Enter`: Save settings and reload the VapourSynth filter instantly (no player restart required).
*   `Esc`: Close the menu overlay.

---

## 4. Menu Options & Rationale

| Menu Option | Choices | Description |
|---|---|---|
| **Status** | `ON` / `OFF` | Toggles the active filter state. |
| **Model** | `v2.3 (Fast)`<br>`v3.9 (Fast)`<br>`v4.6`<br>`v4.12-lite`<br>`v4.22-lite`<br>`v4.26 (Latest)` | Choose between lightweight models (v2.3/v3.9) to guarantee 48fps/60fps playback speed, or heavier models (v4.6/v4.26) for maximum visual quality. |
| **GPU Device** | `NVIDIA (GPU 1)` / `AMD (GPU 0)` | Select index `1` for high-performance NVIDIA hardware acceleration, or index `0` for the integrated AMD GPU. |
| **GPU Threads** | `1`, `2`, `4` | Concurrency thread count. `2` is recommended. Set to `1` if you notice any driver stability/device lost errors. |
| **Scene Detect** | `On` / `Off` | Toggles scene change protection (prevents blending artifacts across cuts). |
| **Framerate** | `2x` / `4x` | Target framerate multiplier. |
