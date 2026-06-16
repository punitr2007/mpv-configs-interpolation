import vapoursynth as vs
import json
import os

core = vs.core

# 1. Default Parameters
model = 9           # RIFE v3.9
factor_num = 2      # 2x multiplier
factor_den = 1
gpu_id = 1          # NVIDIA GPU
gpu_thread = 2      # 2 threads
sc = True           # Scene-change detection on
downscale_width = 1280 # Default downscale to 720p equivalent width

# 2. Load Settings from JSON Config
try:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    settings_path = os.path.join(script_dir, "rife_settings.json")
    if os.path.exists(settings_path):
        with open(settings_path, "r") as f:
            data = json.load(f)
            model = data.get("model", model)
            factor_num = data.get("factor_num", factor_num)
            factor_den = data.get("factor_den", factor_den)
            gpu_id = data.get("gpu_id", gpu_id)
            gpu_thread = data.get("gpu_thread", gpu_thread)
            sc = data.get("sc", sc)
            downscale_width = data.get("downscale_width", downscale_width)
except Exception:
    pass

# 3. Standalone Testing Mock
if "video_in" not in globals():
    video_in = core.std.BlankClip(
        format=vs.YUV420P8,
        width=1920,
        height=1080,
        fpsnum=24000,
        fpsden=1001,
        length=1000
    )

clip = video_in
original_w = clip.width
original_h = clip.height

# 4. Scene Change Detection (Done on original clip/resolution)
has_sc = False
if sc:
    try:
        if hasattr(core, "misc") and hasattr(core.misc, "SCDetect"):
            clip = core.misc.SCDetect(clip)
            has_sc = True
    except Exception:
        pass

# 5. Format Conversion & Downscaling
# Check if downscaling is requested and applicable
if downscale_width > 0 and downscale_width < original_w:
    # Round downscaled height to nearest even integer (mandatory for YUV420 subsampling)
    target_w = int(downscale_width)
    target_h = int(original_h * (target_w / original_w))
    target_h = (target_h // 2) * 2
    
    # Convert and downscale to RGBS
    clip = core.resize.Bicubic(clip, width=target_w, height=target_h, format=vs.RGBS, matrix_in_s="709")
else:
    # Standard convert to RGBS
    clip = core.resize.Bicubic(clip, format=vs.RGBS, matrix_in_s="709")

# 6. RIFE Frame Interpolation
clip = core.rife.RIFE(
    clip,
    model=model,
    factor_num=factor_num,
    factor_den=factor_den,
    sc=has_sc,
    gpu_id=gpu_id,
    gpu_thread=gpu_thread
)

# 7. Upscale & Convert back to original resolution and format
clip = core.resize.Bicubic(clip, width=original_w, height=original_h, format=vs.YUV420P8, matrix_s="709")

clip.set_output()
