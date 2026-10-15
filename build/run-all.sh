#!/bin/bash
# Run setup -> sync -> build in order. Usage (in WSL):  bash $SCAFFOLD/build/run-all.sh
D="$(dirname "$(realpath "$0")")"
bash "$D/00-setup-host.sh" && bash "$D/01-sync.sh" && bash "$D/02-build-hal.sh"
