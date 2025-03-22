#!/usr/bin/env -S nix shell --impure --expr "(builtins.getFlake \"nixpkgs\").legacyPackages.\${builtins.currentSystem}.python3.withPackages (p: [ p.pynvml ])" --command sudo python3

from pynvml import *
nvmlInit()

myGPU = nvmlDeviceGetHandleByIndex(0)

nvmlDeviceSetGpcClkVfOffset(myGPU, 200)

nvmlDeviceSetMemClkVfOffset(myGPU, 3500)
