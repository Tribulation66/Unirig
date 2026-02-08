#!/bin/bash
# =============================================================================
# UniRig Setup Script for RunPod
# Template: runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
# One command: bash /workspace/Unirig-setup/setup_unirig.sh
# =============================================================================
set -e

echo "=========================================="
echo "  UniRig Setup for RunPod (Python 3.11)"
echo "=========================================="

# --- Step 0: Validate environment ---
echo ""
echo "[0/7] Validating environment..."
PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '3\.\d+')

if [[ "$PYTHON_VERSION" != "3.11" ]]; then
    echo "ERROR: Python 3.11 required, found Python $PYTHON_VERSION"
    echo "Use template: runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04"
    exit 1
fi
echo "  Python: $PYTHON_VERSION ✓"

# --- Step 1: Clone UniRig ---
echo ""
echo "[1/7] Cloning UniRig repository..."
if [ ! -d "/workspace/UniRig" ]; then
    git clone https://github.com/VAST-AI-Research/UniRig.git /workspace/UniRig
    echo "  Cloned ✓"
else
    echo "  Already exists, skipping ✓"
fi
cd /workspace/UniRig

# --- Step 2: Install system dependencies ---
echo ""
echo "[2/7] Installing system libraries..."
apt-get update -qq
apt-get install -y -qq libxrender1 libxi6 libxkbcommon0 libsm6 libxext6 \
    libgl1-mesa-glx libxxf86vm1 libxfixes3 libegl1-mesa-dev libgles2-mesa-dev \
    libosmesa6-dev > /dev/null 2>&1
echo "  System libraries ✓"

# --- Step 3: Pin torch 2.4.1 ---
echo ""
echo "[3/7] Pinning torch 2.4.1+cu124..."
CURRENT_TORCH=$(python3 -c "import torch; print(torch.__version__)" 2>/dev/null || echo "none")
if [[ "$CURRENT_TORCH" != "2.4.1+cu124" ]]; then
    pip install torch==2.4.1+cu124 torchvision==0.19.1+cu124 torchaudio==2.4.1+cu124 \
        --index-url https://download.pytorch.org/whl/cu124 -q
    echo "  Installed torch 2.4.1+cu124 ✓"
else
    echo "  Already correct ✓"
fi

# --- Step 4: Install requirements (torch-safe) ---
echo ""
echo "[4/7] Installing requirements..."
cat > /tmp/constraints.txt << 'EOF'
torch==2.4.1+cu124
torchvision==0.19.1+cu124
torchaudio==2.4.1+cu124
numpy==1.26.4
EOF

cp requirements.txt /tmp/requirements_safe.txt
sed -i '/flash_attn/d' /tmp/requirements_safe.txt

pip install -r /tmp/requirements_safe.txt \
    -c /tmp/constraints.txt \
    --ignore-installed blinker -q 2>&1 | tail -5
echo "  Requirements ✓"

# --- Step 5: Install prebuilt wheels ---
echo ""
echo "[5/7] Installing prebuilt wheels..."

pip install https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/download/v0.0.8/flash_attn-2.6.3+cu124torch2.4-cp311-cp311-linux_x86_64.whl \
    --no-deps -q
echo "  flash_attn ✓"

pip install spconv-cu120 -q
echo "  spconv ✓"

pip install torch_scatter torch_cluster \
    -f https://data.pyg.org/whl/torch-2.4.0+cu124.html -q
echo "  torch_scatter + torch_cluster ✓"

pip install PyOpenGL==3.1.7 PyOpenGL-accelerate==3.1.7 -q 2>/dev/null || true
echo "  PyOpenGL ✓"

# --- Step 6: Pin numpy ---
echo ""
echo "[6/7] Pinning numpy..."
pip install numpy==1.26.4 -q
echo "  numpy 1.26.4 ✓"

# --- Step 7: Verify ---
echo ""
echo "[7/7] Verifying imports..."
export PYOPENGL_PLATFORM=egl
python3 -c '
import torch
assert torch.__version__ == "2.4.1+cu124", f"torch wrong: {torch.__version__}"
import spconv
import torch_scatter
import torch_cluster
import flash_attn
import bpy
print("  torch:", torch.__version__, "✓")
print("  spconv ✓")
print("  torch_scatter ✓")
print("  torch_cluster ✓")
print("  flash_attn ✓")
print("  bpy ✓")
'

echo ""
echo "=========================================="
echo "  ✅ UniRig is ready!"
echo "=========================================="
echo ""
echo "Usage:"
echo "  cd /workspace/UniRig"
echo "  export PYOPENGL_PLATFORM=egl"
echo ""
echo "  # Step 1: Generate skeleton"
echo "  bash launch/inference/generate_skeleton.sh \\"
echo "    --input examples/YOUR_MODEL.glb \\"
echo "    --output examples/YOUR_MODEL_skeleton.fbx"
echo ""
echo "  # Step 2: Generate skin weights"
echo "  bash launch/inference/generate_skin.sh \\"
echo "    --input examples/YOUR_MODEL_skeleton.fbx \\"
echo "    --output examples/YOUR_MODEL_rigged.fbx"
echo ""
