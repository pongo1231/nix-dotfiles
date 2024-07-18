#!/usr/bin/env python3

from pynvml import *
nvmlInit()

myGPU = nvmlDeviceGetHandleByIndex(0)

nvmlDeviceSetGpcClkVfOffset(myGPU, 215)

nvmlDeviceSetMemClkVfOffset(myGPU, 3475)
