##
##  API for Brotli compression.
##

const useBrotliEncDll* = 
  defined(useBrotliEncDll) or defined(useBrotliAllDll) or defined(useBrotliDll)

when useBrotliEncDll:
  const brotliEncDll* {.strdefine.} =
    when defined(windows): "brotlienc.dll"
    elif defined(macos):   "(lib|)brotlienc.dynlib"
    else:                  "(lib|)brotlienc.so(.0|)"
  
  {.pragma: brotliEnc, dynlib: brotliEncDll.}
else:
  import std/os
  const currentSourceDir = currentSourcePath.parentDir()

  {.passC: "-I" & currentSourceDir / "csrc/include".}  
  {.compile: ("./csrc/enc/*.c", "$#.o").}

  {.pragma: brotliEnc.}

import ./shared_dictionary
import ./private/common
import ./types

const
  BROTLI_MIN_WINDOW_BITS* = 10 
    ##  Minimal value for `BROTLI_PARAM_LGWIN` parameter.

  BROTLI_MAX_WINDOW_BITS* = 24 
    ##
    ##  Maximal value for `BROTLI_PARAM_LGWIN` parameter.
    ##
    ##  .. note:: equal to `BROTLI_MAX_DISTANCE_BITS`.
    ##

  BROTLI_LARGE_MAX_WINDOW_BITS* = 30 
    ##
    ##  Maximal value for `BROTLI_PARAM_LGWIN` parameter
    ##  in "Large Window Brotli" (32-bit).
    ##

  BROTLI_MIN_INPUT_BLOCK_BITS* = 16 
    ##  Minimal value for `BROTLI_PARAM_LGBLOCK` parameter.

  BROTLI_MAX_INPUT_BLOCK_BITS* = 24
    ##  Maximal value for `BROTLI_PARAM_LGBLOCK` parameter.

  BROTLI_MIN_QUALITY* = 0 
    ##  Minimal value for `BROTLI_PARAM_QUALITY` parameter.

  BROTLI_MAX_QUALITY* = 11
    ##  Maximal value for `BROTLI_PARAM_QUALITY` parameter.

type    
  BrotliEncoderMode* = enum
    ##  Options for `BROTLI_PARAM_MODE` parameter.
    
    BrotliModeGeneric = 0,
      ##
      ##  Default compression mode.
      ##
      ##  In this mode compressor does not know anything in advance about the
      ##  properties of the input.
      ##
    
    BrotliModeText = 1,
      ##  Compression mode for UTF-8 formatted text input. 
    
    BrotliModeFont = 2
      ##  Compression mode used in WOFF 2.0.

const
  BROTLI_DEFAULT_QUALITY* = 11
    ##  Default value for `BROTLI_PARAM_QUALITY` parameter.

  BROTLI_DEFAULT_WINDOW* = 22
    ##  Default value for `BROTLI_PARAM_LGWIN` parameter.

  BROTLI_DEFAULT_MODE* = BrotliModeGeneric
    ##  Default value for `BROTLI_PARAM_MODE` parameter.

type
  BrotliEncoderOperation* = enum 
    ##  Operations that can be performed by streaming encoder.

    BROTLI_OPERATION_PROCESS = 0, 
      ##
      ##  Process input.
      ##
      ##  Encoder may postpone producing output, until it has processed enough input.
      ##

    BROTLI_OPERATION_FLUSH = 1,
      ##
      ##  Produce output for all processed input.
      ##
      ##  Actual flush is performed when input stream is depleted and there is enough
      ##  space in output stream. This means that client should repeat
      ##  `BROTLI_OPERATION_FLUSH` operation until `available_in` becomes `0`, and
      ##  [proc BrotliEncoderHasMoreOutput] returns `0`. If output is acquired
      ##  via [proc BrotliEncoderTakeOutput], then operation should be repeated after
      ##  output buffer is drained.
      ##
      ##  .. warning:: Until flush is complete, client **SHOULD NOT** swap,
      ##               reduce or extend input stream.
      ##
      ##  When flush is complete, output data will be sufficient for decoder to
      ##  reproduce all the given input.
      ##

    BROTLI_OPERATION_FINISH = 2,
      ##
      ##  Finalize the stream.
      ##
      ##  Actual finalization is performed when input stream is depleted and there is
      ##  enough space in output stream. This means that client should repeat
      ##  `BROTLI_OPERATION_FINISH` operation until `available_in` becomes `0`, and
      ##  [proc BrotliEncoderHasMoreOutput] returns `0`. If output is acquired
      ##  via [proc BrotliEncoderTakeOutput], then operation should be repeated after
      ##  output buffer is drained.
      ##
      ##  .. warning:: Until finalization is complete, client **SHOULD NOT** swap,
      ##               reduce or extend input stream.
      ##
      ##  Helper function [proc BrotliEncoderIsFinished] checks if stream is finalized and
      ##  output fully dumped.
      ##
      ##  Adding more input data to finalized stream is impossible.
      ##

    BROTLI_OPERATION_EMIT_METADATA = 3
      ##
      ##  Emit metadata block to stream.
      ##
      ##  Metadata is opaque to Brotli: neither encoder, nor decoder processes this
      ##  data or relies on it. It may be used to pass some extra information from
      ##  encoder client to decoder client without interfering with main data stream.
      ##
      ##  .. note:: Encoder may emit empty metadata blocks internally, to pad encoded
      ##            stream to byte boundary.
      ##
      ##  .. warning:: Until emitting metadata is complete client **SHOULD NOT** swap,
      ##               reduce or extend input stream.
      ##
      ##  .. warning:: The whole content of input buffer is considered to be the content
      ##               of metadata block. Do @b NOT @e append metadata to input stream,
      ##               before it is depleted with other operations.
      ##
      ##  Stream is soft-flushed before metadata block is emitted. Metadata block
      ##  **MUST** be no longer than than 16MiB.
      ##

  BrotliEncoderParameter* = enum
    ##  Options to be used with [proc BrotliEncoderSetParameter].

    BROTLI_PARAM_MODE = 0,
      ##
      ##  Tune encoder for specific input.
      ##
      ##  [enum BrotliEncoderMode] enumerates all available values.
      ##

    BROTLI_PARAM_QUALITY = 1,
      ## 
      ##  The main compression speed-density lever.
      ##
      ##  The higher the quality, the slower the compression. Range is
      ##  from [const BROTLI_MIN_QUALITY] to [const BROTLI_MAX_QUALITY].
      ##

    BROTLI_PARAM_LGWIN = 2, 
      ## 
      ##  Recommended sliding LZ77 window size.
      ##
      ##  Encoder may reduce this value, e.g. if input is much smaller than
      ##  window size.
      ##
      ##  Window size is `(1 << value) - 16`.
      ##
      ##  Range is from [const BROTLI_MIN_WINDOW_BITS] to [const BROTLI_MAX_WINDOW_BITS].
      ##

    BROTLI_PARAM_LGBLOCK = 3, 
      ##
      ##  Recommended input block size.
      ##
      ##  Encoder may reduce this value, e.g. if input is much smaller than input
      ##  block size.
      ##
      ##  Range is from [const BROTLI_MIN_INPUT_BLOCK_BITS] to
      ##  [const BROTLI_MAX_INPUT_BLOCK_BITS].
      ##
      ##  .. note:: Bigger input block size allows better compression, but consumes more
      ##            memory.
      ##            The rough formula of memory used for temporary input
      ##            storage is `3 << lgBlock`.
      ##

    BROTLI_PARAM_DISABLE_LITERAL_CONTEXT_MODELING = 4, 
      ##
      ##  Flag that affects usage of "literal context modeling" format feature.
      ##
      ##  This flag is a "decoding-speed vs compression ratio" trade-off.
      ##

    BROTLI_PARAM_SIZE_HINT = 5, 
      ##
      ##  Estimated total input size for all
      ##  [proc BrotliEncoderCompressStream] calls.
      ##
      ##  The default value is `0`, which means that the total input size is unknown.
      ##

    BROTLI_PARAM_LARGE_WINDOW = 6, 
      ##
      ##  Flag that determines if "Large Window Brotli" is used.
      ##

    BROTLI_PARAM_NPOSTFIX = 7, 
      ##
      ##  Recommended number of postfix bits (NPOSTFIX).
      ##
      ##  Encoder may change this value.
      ##
      ##  Range is from 0 to [const BROTLI_MAX_NPOSTFIX]. <!-- defined in common/constants.h-->
      ##

    BROTLI_PARAM_NDIRECT = 8,
      ##
      ##  Recommended number of direct distance codes (NDIRECT).
      ##
      ##  Encoder may change this value.
      ##
      ##  Range is from 0 to (15 << NPOSTFIX) in steps of (1 << NPOSTFIX).
      ##

    BROTLI_PARAM_STREAM_OFFSET = 9
      ##
      ##  Number of bytes of input stream already processed by a different instance.
      ##
      ##  .. note:: It is important to configure all the encoder instances with same
      ##            parameters (except this one) in order to allow all the encoded parts
      ##            obey the same restrictions implied by header.
      ##
      ##  If offset is not 0, then stream header is omitted.
      ##  In any case output start is byte aligned, so for proper streams stitching
      ##  "predecessor" stream must be flushed.
      ##
      ##  Range is not artificially limited, but all the values greater or equal to
      ##  maximal window size have the same effect. Values greater than 2^30 are not
      ##  allowed.
      ##


  BrotliEncoderState* = object # brotliEncoderStateStruct, true definition in enc/state.h
    ##
    ##  Opaque structure that holds encoder state.
    ##
    ##  Allocated and initialized with [proc BrotliEncoderCreateInstance].
    ##  Cleaned up and deallocated with [proc BrotliEncoderDestroyInstance].
    ##

proc BrotliEncoderSetParameter*(state: ptr BrotliEncoderState;
                               param: BrotliEncoderParameter; value: uint32): cint {.
    cdecl, importc: "BrotliEncoderSetParameter", brotliEnc.}
  ##
  ##  Sets the specified parameter to the given encoder instance.
  ##
  ##  :state: encoder instance
  ##  :param: parameter to set
  ##  :value: new parameter value
  ## 
  ##  :returns: `0` if parameter is unrecognized, or value is invalid
  ##  :returns: `0` if value of parameter can not be changed at current
  ##            encoder state (e.g. when encoding is started, window size might be
  ##            already encoded and therefore it is impossible to change it)
  ##  :returns: `1` if value is accepted
  ## 
  ##  .. warning:: invalid values might be accepted in case they would not break
  ##           encoding process.
  ##
proc BrotliEncoderCreateInstance*(allocFunc: BrotliAllocFunc;
                                 freeFunc: BrotliFreeFunc; opaque: pointer): ptr BrotliEncoderState {.
    cdecl, importc: "BrotliEncoderCreateInstance", brotliEnc.}
  ##
  ##  Creates an instance of [type BrotliEncoderState] and initializes it.
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
  ##  :returns: pointer to initialized [type BrotliEncoderState] otherwise
  ##
proc BrotliEncoderDestroyInstance*(state: ptr BrotliEncoderState) {.cdecl,
    importc: "BrotliEncoderDestroyInstance", brotliEnc.}
  ##
  ##  Deinitializes and frees [type BrotliEncoderState] instance.
  ##
  ##  :state: decoder instance to be cleaned up and deallocated
  ##

type
  BrotliEncoderPreparedDictionary* = object # brotliEncoderPreparedDictionaryStruct
    ##  Opaque type for pointer to different possible internal structures containing
    ##  dictionary prepared for the encoder

proc BrotliEncoderPrepareDictionary*(`type`: BrotliSharedDictionaryType;
                                    dataSize: csize_t; data: ptr UncheckedArray[uint8]; 
                                    quality: cint = BROTLI_MAX_QUALITY;
                                    allocFunc: BrotliAllocFunc;
                                    freeFunc: BrotliFreeFunc; opaque: pointer): ptr BrotliEncoderPreparedDictionary {.
    cdecl, importc: "BrotliEncoderPrepareDictionary", brotliEnc.}
  ##
  ##  Prepares a shared dictionary from the given file format for the encoder.
  ##
  ##  `allocFunc` and `freeFunc` **MUST** be both zero or both non-zero. In the
  ##  case they are both zero, default memory allocators are used. `opaque` is
  ##  passed to `allocFunc` and `freeFunc` when they are called. `freeFunc`
  ##  has to return without doing anything when asked to free a NULL pointer.
  ##
  ##  :type: type of dictionary stored in data
  ##  :data_size: size of `data` buffer
  ##  :data: pointer to the dictionary data
  ##  :quality: the maximum Brotli quality to prepare the dictionary for,
  ##            use [const BROTLI_MAX_QUALITY] by default
  ##  :allocFunc: custom memory allocation function
  ##  :freeFunc: custom memory free function
  ##  :opaque: custom memory manager handle
  ##
proc BrotliEncoderDestroyPreparedDictionary*(
    dictionary: ptr BrotliEncoderPreparedDictionary) {.cdecl,
    importc: "BrotliEncoderDestroyPreparedDictionary", brotliEnc.}
proc BrotliEncoderAttachPreparedDictionary*(state: ptr BrotliEncoderState;
    dictionary: ptr BrotliEncoderPreparedDictionary): cint {.cdecl,
    importc: "BrotliEncoderAttachPreparedDictionary", brotliEnc.}
  ##
  ##  Attaches a prepared dictionary of any type to the encoder. Can be used
  ##  multiple times to attach multiple dictionaries. The dictionary type was
  ##  determined by BrotliEncoderPrepareDictionary. Multiple raw prefix
  ##  dictionaries and/or max 1 serialized dictionary with custom words can be
  ##  attached.
  ##
  ##  :returns: `0` in case of error
  ##  :returns: `1` otherwise
  ##
proc BrotliEncoderMaxCompressedSize*(inputSize: csize_t): csize_t {.cdecl,
    importc: "BrotliEncoderMaxCompressedSize", brotliEnc.}
  ##
  ##  Calculates the output size bound for the given `inputSize`.
  ##
  ##  .. warning:: Result is only valid if quality is at least `2` and, in
  ##               case [proc BrotliEncoderCompressStream] was used, no flushes
  ##               (`BROTLI_OPERATION_FLUSH`) were performed.
  ##
  ##  :input_size: size of projected input
  ## 
  ##  :returns: `0` if result does not fit `size_t`
  ##

proc BrotliEncoderCompress*(quality: cint = BROTLI_DEFAULT_QUALITY; lgwin: cint = BROTLI_DEFAULT_WINDOW;
                           mode: BrotliEncoderMode = BROTLI_DEFAULT_MODE; inputSize: csize_t;
                           inputBuffer: ptr UncheckedArray[uint8]; encodedSize: ptr csize_t;
                           encodedBuffer: ptr UncheckedArray[uint8]): cint {.cdecl,
    importc: "BrotliEncoderCompress", brotliEnc.}
  ##
  ##  Performs one-shot memory-to-memory compression.
  ##
  ##  Compresses the data in `input_buffer` into `encoded_buffer`, and sets
  ##  `encoded_size[]` to the compressed length.
  ##
  ##  .. note:: If `BrotliEncoderMaxCompressedSize(input_size)` returns non-zero
  ##            value, then output is guaranteed to be no longer than that.
  ##
  ##  .. note:: If `lgwin` is greater than [const BROTLI_MAX_WINDOW_BITS] then resulting
  ##            stream might be incompatible with RFC 7932; to decode such streams,
  ##            decoder should be configured with
  ##            `BROTLI_DECODER_PARAM_LARGE_WINDOW = 1`
  ##
  ##  :quality: quality parameter value, e.g. `BROTLI_DEFAULT_QUALITY`
  ##  :lgwin: lgwin parameter value, e.g. `BROTLI_DEFAULT_WINDOW`
  ##  :mode: mode parameter value, e.g. `BROTLI_DEFAULT_MODE`
  ##  :input_size: size of `input_buffer`
  ##  :input_buffer: input data buffer with at least `input_size`
  ##         addressable bytes
  ##  :encoded_size: `[in, out]` 
  ##                 **in**: size of `encoded_buffer`;
  ##                 **out**: length of compressed data written to `encoded_buffer`, or `0` if compression fails
  ##  :encoded_buffer: compressed data destination buffer
  ## 
  ##  :returns: `0` in case of compression error
  ##  :returns: `0` if output buffer is too small
  ##  :returns: `1` otherwise
  ##
proc BrotliEncoderCompressStream*(state: ptr BrotliEncoderState;
                                 op: BrotliEncoderOperation;
                                 availableIn: ptr csize_t; nextIn: ptr ptr uint8;
                                 availableOut: ptr csize_t;
                                 nextOut: ptr ptr uint8; totalOut: ptr csize_t): cint {.
    cdecl, importc: "BrotliEncoderCompressStream", brotliEnc.}
  ##
  ##  Compresses input stream to output stream.
  ##
  ##  The values `available_in[]` and `available_out[]` must specify the number of
  ##  bytes addressable at `next_in[]` and `next_out[]` respectively.
  ##  When `available_out[]` is `0`, `next_out` is allowed to be `nil`.
  ##
  ##  After each call, `available_in[]` will be decremented by the amount of input
  ##  bytes consumed, and the `next_in[]` pointer will be incremented by that
  ##  amount. Similarly, `available_out[]` will be decremented by the amount of
  ##  output bytes written, and the `next_out[]` pointer will be incremented by
  ##  that amount.
  ##
  ##  `total_out`, if it is not a null-pointer, will be set to the number
  ##  of bytes compressed since the last `state` initialization.
  ##
  ##  Internally workflow consists of 3 tasks:
  ##   - (optionally) copy input data to internal buffer
  ##   - actually compress data and (optionally) store it to internal buffer
  ##   - (optionally) copy compressed bytes from internal buffer to output stream
  ##
  ##  Whenever all 3 tasks can't move forward anymore, or error occurs, this
  ##  method returns the control flow to caller.
  ##
  ##  `op` is used to perform flush, finish the stream, or inject metadata block.
  ##  See [enum BrotliEncoderOperation] for more information.
  ##
  ##  Flushing the stream means forcing encoding of all input passed to encoder and
  ##  completing the current output block, so it could be fully decoded by stream
  ##  decoder. To perform flush set `op` to `BROTLI_OPERATION_FLUSH`.
  ##  Under some circumstances (e.g. lack of output stream capacity) this operation
  ##  would require several calls to [proc BrotliEncoderCompressStream]. The method must
  ##  be called again until both input stream is depleted and encoder has no more
  ##  output (see [proc BrotliEncoderHasMoreOutput]) after the method is called.
  ##
  ##  Finishing the stream means encoding of all input passed to encoder and
  ##  adding specific "final" marks, so stream decoder could determine that stream
  ##  is complete. To perform finish set `op` to `BROTLI_OPERATION_FINISH`.
  ##  Under some circumstances (e.g. lack of output stream capacity) this operation
  ##  would require several calls to [proc BrotliEncoderCompressStream]. The method must
  ##  be called again until both input stream is depleted and encoder has no more
  ##  output (see [proc BrotliEncoderHasMoreOutput]) after the method is called.
  ##
  ##  .. warning:: When flushing and finishing, `op` should not change until operation
  ##               is complete; input stream should not be swapped, reduced or
  ##               extended as well.
  ##
  ##  :state: encoder instance
  ##  :op: requested operation
  ##  :available_in: `[in, out]`
  ##                 **in**: amount of available input;
  ##                 **out**: amount of unused input
  ##  :next_in: `[in, out]`
  ##            pointer to the next input byte
  ##  :available_out: `[in, out]` 
  ##                  **in**: length of output buffer;
  ##                  **out**: remaining size of output buffer
  ##  :next_out: `[in, out]` 
  ##             compressed output buffer cursor; can be `nil`
  ##             if `available_out` is `0`
  ##  :total_out: `[out]`
  ##              number of bytes produced so far; can be `nil`
  ## 
  ##  :returns: `0` if there was an error
  ##  :returns: `1` otherwise
  ##
proc BrotliEncoderIsFinished*(state: ptr BrotliEncoderState): cint {.cdecl,
    importc: "BrotliEncoderIsFinished", brotliEnc.}
  ##
  ##  Checks if encoder instance reached the final state.
  ##
  ##  :state: encoder instance
  ## 
  ##  :returns: `1` if encoder is in a state where it reached the end of
  ##            the input and produced all of the output
  ##  :returns: `0` otherwise
  ##
proc BrotliEncoderHasMoreOutput*(state: ptr BrotliEncoderState): cint {.cdecl,
    importc: "BrotliEncoderHasMoreOutput", brotliEnc.}
  ##
  ##  Checks if encoder has more output.
  ##
  ##  :state: encoder instance
  ## 
  ##  :returns: `1`, if encoder has some unconsumed output
  ##  :returns: `0` otherwise
  ##
proc BrotliEncoderTakeOutput*(state: ptr BrotliEncoderState; size: ptr csize_t): ptr uint8 {.
    cdecl, importc: "BrotliEncoderTakeOutput", brotliEnc.}
  ##
  ##  Acquires pointer to internal output buffer.
  ##
  ##  This method is used to make language bindings easier and more efficient:
  ##   - push data to [proc BrotliEncoderCompressStream],
  ##     until [proc BrotliEncoderHasMoreOutput] returns `1`
  ##   - use [proc BrotliEncoderTakeOutput] to peek bytes and copy to language-specific
  ##     entity
  ##
  ##  Also this could be useful if there is an output stream that is able to
  ##  consume all the provided data (e.g. when data is saved to file system).
  ##
  ##  .. attention:: After every call to [proc BrotliEncoderTakeOutput] `size[]` bytes of
  ##                 output are considered consumed for all consecutive calls to the
  ##                 instance methods; returned pointer becomes invalidated as well.
  ##
  ##  .. note:: Encoder output is not guaranteed to be contiguous. This means that
  ##            after the size-unrestricted call to [proc BrotliEncoderTakeOutput],
  ##            immediate next call to [proc BrotliEncoderTakeOutput] may return more data.
  ##
  ##  :state: encoder instance
  ##  :size: `[in, out]`
  ##          **in**: number of bytes caller is ready to take, `0` if
  ##          any amount could be handled; 
  ##          **out**: amount of data pointed by returned pointer and
  ##          considered consumed; 
  ##          out value is never greater than in value, unless it is `0`
  ## 
  ##  :returns: pointer to output data
  ##
proc BrotliEncoderEstimatePeakMemoryUsage*(quality: cint; lgwin: cint;
    inputSize: csize_t): csize_t {.cdecl,
                                importc: "BrotliEncoderEstimatePeakMemoryUsage", brotliEnc.}
  ##  Returns the estimated peak memory usage (in bytes) of the BrotliCompress()
  ##  function, not counting the memory needed for the input and output.
proc BrotliEncoderGetPreparedDictionarySize*(
    dictionary: ptr BrotliEncoderPreparedDictionary): csize_t {.cdecl,
    importc: "BrotliEncoderGetPreparedDictionarySize", brotliEnc.}
  ##  Returns `0` if dictionary is not valid; otherwise returns allocation size.
proc BrotliEncoderVersion*(): uint32 {.cdecl, importc: "BrotliEncoderVersion", brotliEnc.}
  ##
  ##  Gets an encoder library version.
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
