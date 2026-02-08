# UniRig RunPod Setup (T66 Pipeline)

One-command setup for [UniRig](https://github.com/VAST-AI-Research/UniRig) auto-rigging on RunPod GPU pods.

## Quick Start

### 1. Create RunPod Pod
- **Template:** `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- **GPU:** A40 or better (48GB VRAM recommended)
- **Volume:** Mount at `/workspace`

### 2. Run Setup (one command)
```bash
git clone https://github.com/Tribulation66/Unirig.git /workspace/Unirig-setup && bash /workspace/Unirig-setup/setup_unirig.sh
```

Takes ~3-5 minutes. Clones official UniRig, installs all dependencies with pinned versions, verifies everything.

### 3. Rig a Model
```bash
cd /workspace/UniRig
export PYOPENGL_PLATFORM=egl

# Generate skeleton
bash launch/inference/generate_skeleton.sh \
  --input examples/your_model.glb \
  --output examples/your_model_skeleton.fbx

# Generate skin weights
bash launch/inference/generate_skin.sh \
  --input examples/your_model_skeleton.fbx \
  --output examples/your_model_rigged.fbx
```

## Pinned Versions

| Package | Version | Source |
|---------|---------|--------|
| torch | 2.4.1+cu124 | PyTorch official |
| flash_attn | 2.6.3+cu124torch2.4 | mjun0812 prebuilt wheel |
| spconv | cu120 | PyPI |
| torch_scatter | pt24cu124 | PyG wheels |
| torch_cluster | pt24cu124 | PyG wheels |
| bpy | 4.2 | PyPI |
| numpy | 1.26.4 | PyPI |
| PyOpenGL | 3.1.7 | PyPI |

## Notes
- Output must be `.fbx` (not `.glb`)
- Uses constraints file to prevent torch upgrades from transitive dependencies
- First run downloads ~6GB of model checkpoints from HuggingFace (cached in `/root/.cache`)
- `export PYOPENGL_PLATFORM=egl` is required before the skinning step
