##
##  API for Brotli decompression.
##

const useBrotliDecDll* = 
  defined(useBrotliDecDll) or defined(useBrotliAllDll) or defined(useBrotliDll)

when useBrotliDecDll:
  const brotliDecDll* {.strdefine.} =
    when defined(windows): "brotlidec.dll"
    elif defined(macos):   "(lib|)brotlidec.dynlib"
    else:                  "(lib|)brotlidec.so(.0|)"
  
  {.pragma: brotliDec, dynlib: brotliDecDll.}
else:
  import std/os
  const currentSourceDir = currentSourcePath.parentDir()

  {.passC: "-I" & currentSourceDir / "csrc/include".}
  {.compile: ("./csrc/common/*.c", "$#.o").}
  {.compile: ("./csrc/dec/*.c", "$#.o").}

  {.pragma: brotliDec.}

import ./shared_dictionary
import ./types

type
  BrotliDecoderState* = object # brotliDecoderStateStruct, true def in dec/state.h
    ##
    ##  Opaque structure that holds decoder state.
    ##
    ##  Allocated and initialized with [proc BrotliDecoderCreateInstance].
    ## 
    ##  Cleaned up and deallocated with [proc BrotliDecoderDestroyInstance].
    ##
  BrotliDecoderResult* = enum 
    ##
    ##  Result type for [proc BrotliDecoderDecompress] and
    ##  [proc BrotliDecoderDecompressStream] functions.
    ##

    BROTLI_DECODER_RESULT_ERROR = 0,
      ##  Decoding error, e.g. corrupted input or memory allocation problem.

    BROTLI_DECODER_RESULT_SUCCESS = 1,
      ##  Decoding successfully completed.

    BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT = 2,
      ##  Partially done; should be called again with more input.

    BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT = 3
      ##  Partially done; should be called again with more output.

  BrotliDecoderErrorCode* = enum 
    ##
    ##  Error code for detailed logging / production debugging.
    ##
    ##  See [proc BrotliDecoderGetErrorCode] and [const BROTLI_LAST_ERROR_CODE].
    ##
    BROTLI_DECODER_ERROR_UNREACHABLE = -31, ##  "Impossible" states
    BROTLI_DECODER_ERROR_ALLOC_BLOCK_TYPE_TREES = -30, ##  -28..-29 codes are reserved for dynamic ring-buffer allocation
    BROTLI_DECODER_ERROR_ALLOC_RING_BUFFER_2 = -27,
    BROTLI_DECODER_ERROR_ALLOC_RING_BUFFER_1 = -26,
    BROTLI_DECODER_ERROR_ALLOC_CONTEXT_MAP = -25, ##  -23..-24 codes are reserved for distinct tree groups
    BROTLI_DECODER_ERROR_ALLOC_TREE_GROUPS = -22, ##  Literal, insert and distance trees together
    BROTLI_DECODER_ERROR_ALLOC_CONTEXT_MODES = -21, ##  Memory allocation problems
    BROTLI_DECODER_ERROR_INVALID_ARGUMENTS = -20,
    BROTLI_DECODER_ERROR_DICTIONARY_NOT_SET = -19,
    BROTLI_DECODER_ERROR_COMPOUND_DICTIONARY = -18, ##  -17 code is reserved
    BROTLI_DECODER_ERROR_FORMAT_DISTANCE = -16,
    BROTLI_DECODER_ERROR_FORMAT_PADDING_2 = -15,
    BROTLI_DECODER_ERROR_FORMAT_PADDING_1 = -14,
    BROTLI_DECODER_ERROR_FORMAT_WINDOW_BITS = -13,
    BROTLI_DECODER_ERROR_FORMAT_DICTIONARY = -12,
    BROTLI_DECODER_ERROR_FORMAT_TRANSFORM = -11,
    BROTLI_DECODER_ERROR_FORMAT_BLOCK_LENGTH_2 = -10,
    BROTLI_DECODER_ERROR_FORMAT_BLOCK_LENGTH_1 = -9,
    BROTLI_DECODER_ERROR_FORMAT_CONTEXT_MAP_REPEAT = -8,
    BROTLI_DECODER_ERROR_FORMAT_HUFFMAN_SPACE = -7,
    BROTLI_DECODER_ERROR_FORMAT_CL_SPACE = -6,
    BROTLI_DECODER_ERROR_FORMAT_SIMPLE_HUFFMAN_SAME = -5,
    BROTLI_DECODER_ERROR_FORMAT_SIMPLE_HUFFMAN_ALPHABET = -4,
    BROTLI_DECODER_ERROR_FORMAT_EXUBERANT_META_NIBBLE = -3,
    BROTLI_DECODER_ERROR_FORMAT_RESERVED = -2,
    BROTLI_DECODER_ERROR_FORMAT_EXUBERANT_NIBBLE = -1,
    BROTLI_DECODER_NO_ERROR = 0, ##  Same as BrotliDecoderResult values
    BROTLI_DECODER_SUCCESS = 1,
    BROTLI_DECODER_NEEDS_MORE_INPUT = 2,
    BROTLI_DECODER_NEEDS_MORE_OUTPUT = 3 ##  Errors caused by invalid input


const
  BROTLI_LAST_ERROR_CODE* = low(BrotliDecoderErrorCode) # BROTLI_DECODER_ERROR_UNREACHABLE
    ##
    ##  The value of the last error code, negative integer.
    ##
    ##  All other error code values are in the range from
    ##  [const BROTLI_LAST_ERROR_CODE]
    ##  to `-1`. There are also 4 other possible non-error codes `0 .. 3` in
    ##  [enum BrotliDecoderErrorCode].
    ##

type 
  BrotliDecoderParameter* = enum
    ##  Options to be used with [proc BrotliDecoderSetParameter].
    
    BROTLI_DECODER_PARAM_DISABLE_RING_BUFFER_REALLOCATION = 0, 
      ##
      ##  Disable "canny" ring buffer allocation strategy.
      ##
      ##  Ring buffer is allocated according to window size, despite the real size of
      ##  the content.
      ##

    BROTLI_DECODER_PARAM_LARGE_WINDOW = 1
      ##
      ##  Flag that determines if "Large Window Brotli" is used.
      ##


proc BrotliDecoderSetParameter*(state: ptr BrotliDecoderState;
                               param: BrotliDecoderParameter; value: uint32): cint {.
    cdecl, importc: "BrotliDecoderSetParameter", brotliDec.}
  ##
  ##  Sets the specified parameter to the given decoder instance.
  ##
  ##  :state: decoder instance
  ##  :param: parameter to set
  ##  :value: new parameter value
  ## 
  ##  :returns: `0` if parameter is unrecognized, or value is invalid
  ##  :returns: `1` if value is accepted
  ##
proc BrotliDecoderAttachDictionary*(state: ptr BrotliDecoderState;
                                   `type`: BrotliSharedDictionaryType;
                                   dataSize: csize_t; data: ptr UncheckedArray[uint8]): cint {.cdecl,
    importc: "BrotliDecoderAttachDictionary", brotliDec.}
  ##
  ##  Adds LZ77 prefix dictionary, adds or replaces built-in static dictionary and
  ##  transforms.
  ##
  ##  Attached dictionary ownership is not transferred.
  ##  Data provided to this method should be kept accessible until
  ##  decoding is finished and decoder instance is destroyed.
  ##
  ##  .. note:: Dictionaries can NOT be attached after actual decoding is started.
  ##
  ##  :state: decoder instance
  ##  :type: dictionary data format
  ##  :data_size: length of memory region pointed by `data`
  ##  :data: dictionary data in format corresponding to `type`
  ## 
  ##  :returns: `0` if dictionary is corrupted,
  ##            or dictionary count limit is reached
  ##  :returns: `1` if dictionary is accepted / attached
  ##
proc BrotliDecoderCreateInstance*(allocFunc: BrotliAllocFunc = nil;
                                 freeFunc: BrotliFreeFunc = nil; opaque: pointer = nil): ptr BrotliDecoderState {.
    cdecl, importc: "BrotliDecoderCreateInstance", brotliDec.}
  ##
  ##  Creates an instance of [type BrotliDecoderState] and initializes it.
  ##
  ##  The instance can be used once for decoding and should then be destroyed with
  ##  [proc BrotliDecoderDestroyInstance], it cannot be reused for a new decoding
  ##  session.
  ##
  ##  `allocFunc` and `freeFunc` **MUST** be both zero or both non-zero. In the
  ##  case they are both zero, default memory allocators are used. `opaque` is
  ##  passed to `allocFunc` and `freeFunc` when they are called. `freeFunc`
  ##  has to return without doing anything when asked to free a NULL pointer.
  ##
  ##  :allocFunc: custom memory allocation function
  ##  :freeFunc: custom memory free function
  ##  :opaque: custom memory manager handle
  ## 
  ##  :returns: `nil` if instance can not be allocated or initialized
  ##  :returns: pointer to initialized [type BrotliDecoderState] otherwise
  ##
proc BrotliDecoderDestroyInstance*(state: ptr BrotliDecoderState) {.cdecl,
    importc: "BrotliDecoderDestroyInstance", brotliDec.}
  ##
  ##  Deinitializes and frees [type BrotliDecoderState] instance.
  ##
  ##  :state: decoder instance to be cleaned up and deallocated
  ##
proc BrotliDecoderDecompress*(encodedSize: csize_t;
                             encodedBuffer: ptr UncheckedArray[uint8];
                             decodedSize: ptr csize_t;
                             decodedBuffer: ptr UncheckedArray[uint8]): BrotliDecoderResult {.cdecl,
    importc: "BrotliDecoderDecompress", brotliDec.}
  ##
  ##  Performs one-shot memory-to-memory decompression.
  ##
  ##  Decompresses the data in `encodedBuffer` into `decodedBuffer`, and sets
  ##  `decodedSize[]` to the decompressed length.
  ##
  ##  :encodedSize: size of `encodedBuffer`
  ##  :encodedBuffer: compressed data buffer with at least `encodedSize`
  ##                   addressable bytes
  ##  :decodedSize: `[in, out]`
  ##                **in**: size of `decodedBuffer`;
  ##                **out**: length of decompressed data written to `decodedBuffer`
  ##  :decodedBuffer: decompressed data destination buffer
  ## 
  ##  :returns: `BROTLI_DECODER_RESULT_ERROR` if input is corrupted, memory
  ##           allocation failed, or `decodedBuffer` is not large enough;
  ##  :returns: `BROTLI_DECODER_RESULT_SUCCESS` otherwise
  ##
proc BrotliDecoderDecompressStream*(state: ptr BrotliDecoderState;
                                   availableIn: ptr csize_t;
                                   nextIn: ptr ptr UncheckedArray[uint8];
                                   availableOut: ptr csize_t;
                                   nextOut: ptr ptr UncheckedArray[uint8];
                                   totalOut: ptr csize_t): BrotliDecoderResult {.
    cdecl, importc: "BrotliDecoderDecompressStream", brotliDec.}
  ##
  ##  Decompresses the input stream to the output stream.
  ##
  ##  The values `availableIn[]` and `availableOut[]` must specify the number of
  ##  bytes addressable at `nextIn[]` and `nextOut[]` respectively.
  ##  When `availableOut[]` is `0`, `nextOut` is allowed to be `nil`.
  ##
  ##  After each call, `availableIn[]` will be decremented by the amount of input
  ##  bytes consumed, and the `nextIn[]` pointer will be incremented by that
  ##  amount. Similarly, `availableOut[]` will be decremented by the amount of
  ##  output bytes written, and the `nextOut[]` pointer will be incremented by
  ##  that amount.
  ##
  ##  `totalOut`, if it is not a null-pointer, will be set to the number
  ##  of bytes decompressed since the last `state` initialization.
  ##
  ##  .. note:: Input is never overconsumed, so `nextIn` and `availableIn` could be
  ##            passed to the next consumer after decoding is complete.
  ##
  ##  :state: decoder instance
  ##  :availableIn: `[in, out]`
  ##                 **in**: amount of available input;
  ##                 **out**: amount of unused input
  ##  :nextIn: `[in, out]`
  ##            pointer to the next compressed byte
  ##  :availableOut: `[in, out]`
  ##                  **in**: length of output buffer;
  ##                  **out**: remaining size of output buffer
  ##  :nextOut: `[in, out]`
  ##             output buffer cursor; can be `nil` if `availableOut` is `0`
  ##  :totalOut: `[out]`
  ##              number of bytes decompressed so far; can be `nil`
  ## 
  ##  :returns: `BROTLI_DECODER_RESULT_ERROR` if input is corrupted, memory
  ##            allocation failed, arguments were invalid, etc.;
  ##            use [proc BrotliDecoderGetErrorCode] to get detailed error code
  ##  :returns: `BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT` decoding is blocked until
  ##            more input data is provided
  ##  :returns: `BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT` decoding is blocked until
  ##            more output space is provided
  ##  :returns: `BROTLI_DECODER_RESULT_SUCCESS` decoding is finished, no more
  ##            input might be consumed and no more output will be produced
  ##
proc BrotliDecoderHasMoreOutput*(state: ptr BrotliDecoderState): cint {.cdecl,
    importc: "BrotliDecoderHasMoreOutput", brotliDec.}
  ##
  ##  Checks if decoder has more output.
  ##
  ##  :state: decoder instance
  ## 
  ##  :returns: `1`, if decoder has some unconsumed output
  ##  :returns: `0` otherwise
  ##
proc BrotliDecoderTakeOutput*(state: ptr BrotliDecoderState; size: ptr csize_t): ptr UncheckedArray[uint8] {.
    cdecl, importc: "BrotliDecoderTakeOutput", brotliDec.}
  ##
  ##  Acquires pointer to internal output buffer.
  ##
  ##  This method is used to make language bindings easier and more efficient:
  ##    - push data to [proc BrotliDecoderDecompressStream],
  ##      until `BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT` is reported
  ##    - use [proc BrotliDecoderTakeOutput] to peek bytes and copy to language-specific
  ##      entity
  ##
  ##  Also this could be useful if there is an output stream that is able to
  ##  consume all the provided data (e.g. when data is saved to file system).
  ##
  ##  .. attention:: After every call to [proc BrotliDecoderTakeOutput] `size[]` bytes of
  ##                 output are considered consumed for all consecutive calls to the
  ##                 instance methods; returned pointer becomes invalidated as well.
  ##
  ##  .. note:: Decoder output is not guaranteed to be contiguous. This means that
  ##            after the size-unrestricted call to [proc BrotliDecoderTakeOutput],
  ##            immediate next call to [proc BrotliDecoderTakeOutput] may return more data.
  ##
  ##  :state: decoder instance
  ##  :size: `[in, out]`
  ##         **in**: number of bytes caller is ready to take, `0` if
  ##                 any amount could be handled;
  ##         **out**: amount of data pointed by returned pointer and
  ##                  considered consumed;
  ##                  out value is never greater than in value, unless it is `0`
  ## 
  ##  :returns: pointer to output data
  ##
proc BrotliDecoderIsUsed*(state: ptr BrotliDecoderState): cint {.cdecl,
    importc: "BrotliDecoderIsUsed", brotliDec.}
  ##
  ##  Checks if instance has already consumed input.
  ##
  ##  Instance that returns `0` is considered "fresh" and could be
  ##  reused.
  ##
  ##  :state: decoder instance
  ## 
  ##  :returns: `1` if decoder has already used some input bytes
  ##  :returns: `0` otherwise
  ##
proc BrotliDecoderIsFinished*(state: ptr BrotliDecoderState): cint {.cdecl,
    importc: "BrotliDecoderIsFinished", brotliDec.}
  ##
  ##  Checks if decoder instance reached the final state.
  ##
  ##  :state: decoder instance
  ## 
  ##  :returns: `1` if decoder is in a state where it reached the end of
  ##           the input and produced all of the output
  ##  :returns: `0` otherwise
  ##
proc BrotliDecoderGetErrorCode*(state: ptr BrotliDecoderState): BrotliDecoderErrorCode {.
    cdecl, importc: "BrotliDecoderGetErrorCode", brotliDec.}
  ##
  ##  Acquires a detailed error code.
  ##
  ##  Should be used only after [proc BrotliDecoderDecompressStream] returns
  ##  `BROTLI_DECODER_RESULT_ERROR`.
  ##
  ##  See also: [proc BrotliDecoderErrorString]
  ##
  ##  :state: decoder instance
  ##  :returns: last saved error code
  ##
proc BrotliDecoderErrorString*(c: BrotliDecoderErrorCode): cstring {.cdecl,
    importc: "BrotliDecoderErrorString", brotliDec.}
  ##
  ##  Converts error code to a c-string.
  ##
proc BrotliDecoderVersion*(): uint32 {.cdecl, importc: "BrotliDecoderVersion".}
  ##
  ##  Gets a decoder library version.
  ##
  ##  Look at `BROTLI_MAKE_HEX_VERSION` for more information.
  ## 
  ##  .. note:: `BROTLI_MAKE_HEX_VERSION` is defined as such:
  ##    ```c
  ##    /* 
  ##       Compose 3 components into a single number. 
  ##       In a hexadecimal representation B and C 
  ##       components occupy exactly 3 digits. 
  ##    */
  ##    #define BROTLI_MAKE_HEX_VERSION(A, B, C) ((A << 24) | (B << 12) | C)
  ##    ```
  ## 

type
  BrotliDecoderMetadataStartFunc* = proc (opaque: pointer; size: csize_t) {.cdecl.} 
    ##
    ## Callback to fire on metadata block start.
    ##
    ## After this callback is fired, if `size` is not `0`, it is followed by
    ## [type BrotliDecoderMetadataChunkFunc] as more
    ## metadata block contents become accessible.
    ##
    ## :opaque: callback handle
    ## :size: size of metadata block
    ##

  BrotliDecoderMetadataChunkFunc* = proc (opaque: pointer; data: ptr uint8;
                                       size: csize_t) {.cdecl.}
    ##
    ##  Callback to fire on metadata block chunk becomes available.
    ##
    ##  This function can be invoked multiple times per metadata block; block should
    ##  be considered finished when sum of `size` matches the announced metadata
    ##  block size. Chunks contents pointed by `data` are transient and shouln not
    ##  be accessed after leaving the callback.
    ##
    ##  :opaque: callback handle
    ##  :data: pointer to metadata contents
    ##  :size: size of metadata block chunk, at least `1`
    ##

proc BrotliDecoderSetMetadataCallbacks*(state: ptr BrotliDecoderState; startFunc: BrotliDecoderMetadataStartFunc;
    chunkFunc: BrotliDecoderMetadataChunkFunc; opaque: pointer) {.cdecl,
    importc: "BrotliDecoderSetMetadataCallbacks", brotliDec.}
  ##
  ##  Sets callback for receiving metadata blocks.
  ##
  ##  :state: decoder instance
  ##  :startFunc: callback on metadata block start
  ##  :chunkFunc: callback on metadata block chunk
  ##  :opaque: callback handle
  ## 