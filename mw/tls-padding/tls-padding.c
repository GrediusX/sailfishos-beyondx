/*
 * libhybris-tls-padding: reserve the beginning of glibc's static TLS block.
 * Android bionic keeps fixed TLS slots right after the thread pointer (arm64
 * tpidr_el0[0..7]; TLS_SLOT_OPENGL=2 / OPENGL_API=5 on Android 16, 3/4 on older
 * bases). libEGL and vendor GL drivers (Mali) write them on every eglMakeCurrent.
 * Under glibc those bytes are the first module's static TLS -> corrupts e.g. Qt's
 * per-thread data ("Cannot make QOpenGLContext current in a different thread").
 * Preloaded into a process whose executable has no PT_TLS, this block is placed
 * first (TP+16, 8-byte aligned) and absorbs those writes.
 * Build: clang --target=aarch64-linux-gnu -O2 -fPIC -shared -nostdlib -fuse-ld=lld \
 *        -Wl,-soname,libhybris-tls-padding.so -o libhybris-tls-padding.so tls-padding.c
 */
__attribute__((tls_model("initial-exec"), used, visibility("default"), aligned(8)))
__thread char hybris_bionic_tls_slot_padding[256];

__attribute__((visibility("default")))
void *hybris_tls_padding_address(void) { return hybris_bionic_tls_slot_padding; }
