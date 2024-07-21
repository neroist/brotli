# brotli

Nim wrapper for Brotli compression library

## Usage

By default, this library will compile the C source code statically. `-d:useBrotliDll`
and `-d:useBrotliAllDll` will make the library use the `brotlienc` and `brotlidec`
libraries. Use `-d:useBrotliEncDll` or `-d:useBrotliDecDll` to use a specific DLL.

See [`tests/test1.nim`](tests/test1.nim) for some very simple usage examples.
