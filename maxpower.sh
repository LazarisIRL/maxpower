#!/bin/bash

#optionally set the time to run. 300s by default
T=${1:-300}
[[ $T =~ ^[0-9]+$ ]] || { echo "Usage: $0 [seconds]"; exit 1; }
#directory where the gpu-burn program can be found. Looks in the same directory by default
GPU_BURN_DIR=${GPU_BURN_DIR:-$(dirname "$(realpath "$0")")/gpu-burn}
#quick check if gpu-burn is not present
[[ -x $GPU_BURN_DIR/gpu_burn ]] || { echo "gpu_burn not found in $GPU_BURN_DIR. Move it there or run: sudo GPU_BURN_DIR=/path/to/gpu-burn $0"; exit 1; }
RAPL=/sys/class/powercap/intel-rapl:0/energy_uj
LOG=$(mktemp)

#ctrl+c to stop
trap 'rm -f "$LOG"; trap - TERM; kill 0' INT TERM

# CPU + RAM load:
#   --cpu 0                 one worker per CPU thread (0 = all of them)
#   --cpu-method matrixprod each worker does floating-point matrix multiplication
#   --vm 1 --vm-bytes 25%   one extra worker that keeps writing to and reading back 25% of RAM
#   --timeout               stop after T seconds
#   --metrics-brief         print a bogo-ops/s throughput table when it finishes
# The trailing & runs it in the background so the GPU load can start at the same time.
stress-ng --cpu 0 --cpu-method matrixprod --vm 1 --vm-bytes 25% --timeout "${T}s" --metrics-brief &

# GPU load.
# NOTE: will only work for nvidia GPUs
(cd "$GPU_BURN_DIR" && ./gpu_burn "$T" > "$LOG" 2>&1) &

# CPU power comes from RAPL
# Reading it needs root, so without "sudo" this is empty and CPU power shows "n/a".
e0=$(cat "$RAPL" 2>/dev/null)

# Print a line every 5 seconds until T seconds have passed
for (( s = 5; s <= T; s += 5 )); do
	sleep 5
	e1=$(cat "$RAPL" 2>/dev/null)

# Read the power usage and convert to watts
	cpu="n/a"; [[ -n $e0 ]] && (( e1 >= e0 )) && cpu="$(( (e1 - e0) / 5000000 ))W"
	e0=$e1
	# GPU power and temperature come from nvidia-smi directly
	echo "${s}s  CPU ${cpu}  GPU $(nvidia-smi --query-gpu=power.draw,temperature.gpu --format=csv,noheader)°C"
done
wait

echo
# Convert the log to a more readable format
echo "GPU: $(tr '\r' '\n' < "$LOG" | grep -o '[0-9]* Gflop/s' | tail -1), $(grep -oE 'GPU 0: (OK|FAULTY)' "$LOG")"
rm -f "$LOG"
