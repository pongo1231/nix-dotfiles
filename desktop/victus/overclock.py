#!/usr/bin/env python3

from pynvml import *
nvmlInit()

# This sets the GPU to adjust - if this gives you errors or you have multiple GPUs, set to 1 or try other values
myGPU = nvmlDeviceGetHandleByIndex(0)

# The GPU frequency offset value should replace "80" in the line below.
nvmlDeviceSetGpcClkVfOffset(myGPU, 230)
# safe: 230

# The Mem frequency Offset should be **multiplied by 2** to replace the "2500" below
# for example, an offset of 500 in GWE means inserting a value of 1000 in the next line
nvmlDeviceSetMemClkVfOffset(myGPU, 3800)
# safe: 3800
