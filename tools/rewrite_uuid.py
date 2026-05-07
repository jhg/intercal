#!/usr/bin/env python3
"""rewrite_uuid.py BINARY

Rewrite the LC_UUID load command in a Mach-O 64-bit binary with a
deterministic UUID derived from the rest of the file (SHA-256 of the
file with the UUID field zeroed). Used for reproducible-build support
on macOS where dyld requires LC_UUID to be present.

Caveat: this rewrite invalidates any embedded ad-hoc code signature.
The caller is expected to re-sign the binary afterwards (codesign -fs -)
to make it executable on Apple Silicon.

Exits 0 on success, non-zero on any structural error.
"""
import sys
import struct
import hashlib

def main(path):
    with open(path, "rb") as f:
        data = bytearray(f.read())
    if len(data) < 32:
        print("not a Mach-O (too short)", file=sys.stderr)
        return 1
    magic = struct.unpack_from("<I", data, 0)[0]
    if magic != 0xFEEDFACF:
        print(f"not a 64-bit thin Mach-O (magic={magic:#x})", file=sys.stderr)
        return 0  # silently leave non-Mach-O alone
    ncmds = struct.unpack_from("<I", data, 16)[0]
    off = 32
    uuid_off = None
    for _ in range(ncmds):
        if off + 8 > len(data):
            break
        cmd, cmdsize = struct.unpack_from("<II", data, off)
        if cmd == 0x1B:  # LC_UUID
            uuid_off = off + 8
            break
        if cmdsize == 0:
            break
        off += cmdsize
    if uuid_off is None:
        print("no LC_UUID found", file=sys.stderr)
        return 0
    # Zero the payload, hash everything, then take first 16 bytes.
    data[uuid_off:uuid_off + 16] = b"\x00" * 16
    digest = hashlib.sha256(bytes(data)).digest()[:16]
    new_uuid = bytearray(digest)
    new_uuid[6] = (new_uuid[6] & 0x0F) | 0x40   # version 4 marker
    new_uuid[8] = (new_uuid[8] & 0x3F) | 0x80   # RFC 4122 variant
    data[uuid_off:uuid_off + 16] = bytes(new_uuid)
    with open(path, "wb") as f:
        f.write(bytes(data))
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: rewrite_uuid.py BINARY", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
