import std/sysrand

import unittest
import brotli

const
  data = "lazy test daaaaaataaaaaaa ssddddvfggggfdks meow :3c"
  compressed =
    "\x1b2\x00\xf8\xc5\xf2\x96\xea\x85\xaei\xed\xe6\xbc\x80\x09g\x0c\xd8\x80\x13I\xc2\x01y\xb0\x81\xf0B \x9d\x0d\xfe\x17S\x11\x9b\x81-O\xb4\x1f\xea\xc6\xac\xeb\"\xa7\x02"

suite "encoding":
  test "simple test":
    let compressed = compressBrotli(data)
    check compressed == compressed

suite "decoding":
  test "simple test":
    let decompressed = decompressBrotli(compressed)
    check decompressed == data

  test "reallocation":
    let
      bytes = urandom(100 * 1024)
      compressed = compressBrotli(bytes)
      decompressed = decompressBrotli(compressed)

    check decompressed == bytes
