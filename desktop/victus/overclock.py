#!/usr/bin/env python3

from pynvml import *
nvmlInit()

myGPU = nvmlDeviceGetHandleByIndex(0)

nvmlDeviceSetGpcClkVfOffset(myGPU, 220)

nvmlDeviceSetMemClkVfOffset(myGPU, 3500)
