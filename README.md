# maxpower
Have you ever wanted to test your UPS or power delivery systems by forcing your computer to draw the maximum amount of power possible?

No?

Well this script will do exactly that.
It will also print out CPU temperatures and power usage, and GPU power usage, which is nice.

## WARNING

This script is basically a stress tester for your system. It will put full load on your CPU, RAM and GPU. Use it at your own risk.

## Requirements

CPU power readout should work for any CPU from Intel made after 2011 or so. 

- **NVidia GPU** with the driver installed (nvidia-smi must work)
- **[stress-ng](https://github.com/ColinIanKing/stress-ng)**: CPU and RAM load
  `sudo apt install stress-ng`
- **[gpu-burn](https://github.com/wilicc/gpu-burn)**: GPU load, built from source. This needs:
  - CUDA toolkit: `sudo apt install nvidia-cuda-toolkit`
  - Build tools: `sudo apt install build-essential git`
  - The correct `COMPUTE` value for your GPU when running `make`
    (e.g. `61` for GTX 10-series; see [NVIDIA's compute capability list](https://developer.nvidia.com/cuda-gpus))
    
## Installation 

```bash
git clone https://github.com/LazarisIRL/maxpower
cd maxpower
git clone https://github.com/wilicc/gpu-burn
(cd gpu-burn && make COMPUTE=61)   # 61 = GTX 10-series
sudo ./maxpower.sh 300`
```
## Usage 

Must be run with ```sudo``` or it will not print out CPU power use (RAPL is a kernel level feature which requires ```sudo```)
