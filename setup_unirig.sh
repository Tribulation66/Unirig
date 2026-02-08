#!/bin/bash
set -e
echo "=== Setting up UniRig ==="

# Clone UniRig if not present
if [ ! -d "/workspace/UniRig" ]; then
    cd /workspace
    git clone https://github.com/VAST-AI-Research/UniRig.git
fi
cd /workspace/UniRig

# Install requirements (skip flash_attn and bpy)
sed -i '/flash_attn/d' requirements.txt
sed -i '/bpy/d' requirements.txt
pip install -r requirements.txt --ignore-installed blinker

# Flash attention prebuilt wheel (no compile)
pip install flash-attn --no-deps --find-links https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/expanded_assets/v0.7.15 --prefer-binary

# spconv
pip install spconv-cu120

# torch_scatter + torch_cluster from prebuilt wheels
pip install https://github.com/Tribulation66/Unirig/raw/main/torch_scatter-2.1.2-cp310-cp310-linux_x86_64.whl
pip install https://github.com/Tribulation66/Unirig/raw/main/torch_cluster-1.6.3-cp310-cp310-linux_x86_64.whl

# Pin numpy
pip install numpy==1.26.4

# Verify
echo "=== Testing imports ==="
python -c 'import torch; import spconv; import torch_scatter; import torch_cluster; import flash_attn; print("All good!")'
echo "=== UniRig setup complete ==="
