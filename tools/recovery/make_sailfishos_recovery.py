#!/usr/bin/env python3
"""Turn the official LineageOS recovery.img for the Galaxy S10 5G (beyondx) into the
"Sailfish OS recovery": identical kernel/dtbo/header, with only two ramdisk changes:
  1. /data in recovery.fstab -> plain ext4 without encryption (so "Format data" prepares
     the partition Sailfish OS lives on), and
  2. the recovery logo replaced (optional, --logo).
Boot image header v1, gzip-compressed newc ramdisk (as used by LineageOS for beyondx).

usage: make_sailfishos_recovery.py lineage-recovery.img out-recovery.img [--logo logo.png]
"""
import argparse, gzip, hashlib, re, struct

def parse_cpio(b):
    ents, o = [], 0
    while True:
        h = b[o:o+110]; assert h[:6] == b'070701', 'not a newc cpio'
        fl = [int(h[6+i*8:14+i*8], 16) for i in range(13)]
        name = b[o+110:o+110+fl[11]-1].decode()
        p = (o + 110 + fl[11] + 3) & ~3
        data = b[p:p+fl[6]]; o = (p + fl[6] + 3) & ~3
        ents.append([name, fl, data])
        if name == 'TRAILER!!!': return ents

def build_cpio(ents):
    out = bytearray()
    for name, fl, data in ents:
        fl = list(fl); nb = name.encode() + b'\0'; fl[6] = len(data); fl[11] = len(nb)
        out += b'070701' + ''.join('%08x' % v for v in fl).encode() + nb
        out += b'\0' * (-len(out) % 4); out += data; out += b'\0' * (-len(out) % 4)
    out += b'\0' * (-len(out) % 512)
    return bytes(out)

DATA_LINE = r'\1       /data                   ext4    noatime,nosuid,nodev,discard latemount,wait,check,quota,formattable'

def main():
    a = argparse.ArgumentParser(); a.add_argument('src'); a.add_argument('dst'); a.add_argument('--logo')
    args = a.parse_args()
    img = open(args.src, 'rb').read()
    assert img[:8] == b'ANDROID!', 'not an Android boot image'
    ks, ka, rs, ra, ss, sa, ta, ps, hv, osv = struct.unpack_from('<10I', img, 8)
    assert hv == 1 and ss == 0, f'unexpected header v{hv} / second stage'
    dtbo_size, = struct.unpack_from('<I', img, 1632)
    pg = lambda n: (n + ps - 1) // ps * ps
    k = img[ps:ps+ks]; o = ps + pg(ks); rd = img[o:o+rs]; o += pg(rs); d = img[o:o+dtbo_size]

    def img_id(ramdisk):
        h = hashlib.sha1()
        for blob in (k, ramdisk, b'', d): h.update(blob); h.update(struct.pack('<I', len(blob)))
        return h.digest()
    assert img_id(rd) == img[576:596], 'unexpected image id scheme'

    raw = gzip.decompress(rd); ents = parse_cpio(raw)
    assert build_cpio(ents) == raw, 'cpio round-trip mismatch'
    logo = open(args.logo, 'rb').read() if args.logo else None
    changed = 0
    for e in ents:
        if e[0] == 'system/etc/recovery.fstab':
            s = e[2].decode()
            s2 = re.sub(r'^(\S*userdata)\s+/data\s+f2fs\s.*$', DATA_LINE, s, flags=re.M)
            assert s2 != s, '/data f2fs line not found'; e[2] = s2.encode(); changed += 1
        elif logo and e[0] in ('res/images/logo_image.png', 'res/images/logo_image_switch.png'):
            e[2] = logo; changed += 1
    nrd = gzip.compress(build_cpio(ents), 9, mtime=0)

    hdr = bytearray(img[:ps])
    struct.pack_into('<I', hdr, 16, len(nrd))
    struct.pack_into('<Q', hdr, 1636, ps + pg(len(k)) + pg(len(nrd)))
    hdr[576:608] = img_id(nrd) + b'\0' * 12
    pad = lambda b: b + b'\0' * (pg(len(b)) - len(b))
    out = bytes(hdr) + pad(k) + pad(nrd) + pad(d)
    out += b'\0' * max(0, len(img) - len(out))
    open(args.dst, 'wb').write(out)
    print(f'{args.dst}: {len(out)} bytes, {changed} file(s) changed')

if __name__ == '__main__':
    main()
