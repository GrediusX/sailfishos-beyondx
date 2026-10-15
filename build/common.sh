# Shared settings for the WSL build scripts. Sourced, not run.
export SCAFFOLD=${SCAFFOLD:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
export LOGDIR=$SCAFFOLD/logs
export VENDOR=samsung DEVICE=beyondx HABUILD_DEVICE=beyondx PORT_ARCH=aarch64
export ANDROID_ROOT=$HOME/hadk23
export RELEASE=5.1.0.11
export PATH=$HOME/bin:$PATH
export USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache CCACHE_DIR=$HOME/.ccache
mkdir -p "$LOGDIR"
status() { echo "$(date '+%F %T') $*" | tee -a "$LOGDIR/STATUS.txt"; }
