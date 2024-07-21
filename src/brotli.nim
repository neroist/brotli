import ./brotli/encode
import ./brotli/decode

type
  BrotliError* = object of CatchableError
    ## Raised if an operation fails.

const
  KB = 1024
  MB = 1024 * 1024
  # from _brotli python wrapper
  defaultAllocationPlan* = [
    32*KB, 64*KB, 256*KB, 1*MB, 4*MB, 8*MB, 16*MB, 16*MB,
    32*MB, 32*MB, 32*MB, 32*MB, 64*MB, 64*MB, 128*MB, 128*MB,
    256*MB
  ]
    ## According to the block sizes defined by defaultAllocationPlan, the whole
    ## allocated size growth step is:
    ## 
    ## ```
    ## 1   32 KB       +32 KB
    ## 2   96 KB       +64 KB
    ## 3   352 KB      +256 KB
    ## 4   1.34 MB     +1 MB
    ## 5   5.34 MB     +4 MB
    ## 6   13.34 MB    +8 MB
    ## 7   29.34 MB    +16 MB
    ## 8   45.34 MB    +16 MB
    ## 9   77.34 MB    +32 MB
    ## 10  109.34 MB   +32 MB
    ## 11  141.34 MB   +32 MB
    ## 12  173.34 MB   +32 MB
    ## 13  237.34 MB   +64 MB
    ## 14  301.34 MB   +64 MB
    ## 15  429.34 MB   +128 MB
    ## 16  557.34 MB   +128 MB
    ## 17  813.34 MB   +256 MB
    ## 18  1069.34 MB  +256 MB
    ## 19  1325.34 MB  +256 MB
    ## 20  1581.34 MB  +256 MB
    ## 21  1837.34 MB  +256 MB
    ## 22  2093.34 MB  +256 MB
    ## ...
    ## ```

# TODO use BrotliEncoderCompressStream instead of BrotliEncoderCompress
# TODO this allows for finer tuning of the compression
proc compressBrotli*(src: pointer, len: int, mode: BrotliEncoderMode = BrotliModeGeneric, quality: int = BROTLI_DEFAULT_QUALITY, lgwin: int = BROTLI_DEFAULT_WINDOW): string {.raises: [BrotliError].} =
  ## Compresses data from `src`, with the length `len` and return the
  ## compressed data as a string
  ## 
  ## :src: The data to decompress
  ## :len: The length of the data in `src`
  ## :mode: Allows for fine-tuning of the Brotli encoder for specific input.
  ##        See documentation of
  ##        [enum BrotliEncoderMode](./brotli/encode.html#BrotliEncoderMode)
  ## :quality: The quality of the compression. The higher the quality, the
  ##           slower the compression. Clamped to the range of
  ##           `2..BROTLI_MAX_QUALITY`
  ## :lgwin: Brotli encoder sliding LZ77 window size. Clamped to
  ##         `BROTLI_MIN_WINDOW_BITS..BROTLI_MAX_WINDOW_BITS`
  ## 
  ## See also:
  ##   * [const BROTLI_MAX_QUALITY](./brotli/encode.html#BROTLI_MAX_QUALITY)
  ##   * [const BROTLI_MIN_WINDOW_BITS](./brotli/encode.html#BROTLI_MIN_WINDOW_BITS)
  ##   * [const BROTLI_MAX_WINDOW_BITS](./brotli/encode.html#BROTLI_MAX_WINDOW_BITS)
  
  var
    # TODO `BrotliEncoderMaxCompressedSize` is not reliable when quality < 2
    outpSize = BrotliEncoderMaxCompressedSize(csize_t len)
  
  result = newString(outpSize)
  
  let success = 
    BrotliEncoderCompress(
      quality = cint quality.clamp(2, BROTLI_MAX_QUALITY),
      lgwin = cint lgwin.clamp(BROTLI_MIN_WINDOW_BITS, BROTLI_MAX_WINDOW_BITS),
      mode = mode,
      inputSize = csize_t len, inputBuffer = cast[ptr UncheckedArray[uint8]](src),
      encodedSize = addr outpSize, encodedBuffer = cast[ptr UncheckedArray[uint8]](addr result[0])
    )
  defer: result.setLen(outpSize)
  
  if success != 1:
    raise newException(BrotliError, "Failed to compress input")

proc compressBrotli*(src: string, mode: BrotliEncoderMode = BrotliModeText, quality: int = BROTLI_DEFAULT_QUALITY, lgwin: cint = BROTLI_DEFAULT_WINDOW): string {.raises: [BrotliError].} =
  ## Compresses data from `src` and returns the Compressed data as a string.
  ## 
  ## See [proc compressBrotli(pointer, int, BrotliEncoderMode, int, int)] for
  ## descriptions of the other parameters
  compressBrotli(cstring src, src.len, mode, quality, lgwin)

proc compressBrotli*(src: seq[byte], mode: BrotliEncoderMode = BrotliModeGeneric, quality: int = BROTLI_DEFAULT_QUALITY, lgwin: cint = BROTLI_DEFAULT_WINDOW): seq[byte] {.raises: [BrotliError].} =
  ## Compresses data from `src` and returns the Compressed data as a string.
  ## 
  ## See [proc compressBrotli(pointer, int, BrotliEncoderMode, int, int)] for
  ## descriptions of the other parameters
  cast[seq[byte]](compressBrotli(cstring cast[string](src), src.len, mode, quality, lgwin))

proc decompressBrotli*(src: pointer, len: int, allocationPlan: openArray[int] = defaultAllocationPlan, stateParams: set[BrotliDecoderParameter] = {}): string {.raises: [BrotliError].} =
  ## Decompresses data from `src` with length `len` and return the uncompressed
  ## data as a string.
  ## 
  ## :src: The data to decompress
  ## :len: The length of the data in `src`
  ## :allocationPlan: This parameter describes how the output buffer will be
  ##                  allocated & extended. The output buffer will be
  ##                  initially allocated with `allocationPlan[0]` bytes. If
  ##                  the output buffer needs to be extended,
  ##                  `allocationPlan[idx + 1]` more bytes will be allocated.
  ##                  See documentation for [const defaultAllocationPlan]
  ## :stateParams: Which parameters to send to Brotli decoder. See
  ##               documentation for [enum BrotliDecoderParameter](./brotli/decode.html#BrotliDecoderParameter).
  ##               An exception will be raised if setting the parameters fails.
  result = newString(allocationPlan[0])

  var state = BrotliDecoderCreateInstance()
  defer: BrotliDecoderDestroyInstance(state)

  if state.isNil():
    raise newException(BrotliError, "Could not initialize Brotli decoder state")

  for param in stateParams:
    let setResult = BrotliDecoderSetParameter(state, param, 1)

    if setResult != 1:
      BrotliDecoderDestroyInstance(state)
      raise newException(BrotliError, "Could not set parameter " & $param)

  var
    decoderResult: BrotliDecoderResult
    allocPlanStep: int
    
    availableIn = csize_t len
    nextIn = cast[uint](src) # uint here so modifying is easier (no long ass cast stmts)
    availableOut = csize_t result.len
    nextOut = cast[uint](addr result[0]) # ditto

    totalOut: csize_t
  
  while true:
    decoderResult = BrotliDecoderDecompressStream(
      state,

      availableIn = addr availableIn,
      nextIn = cast[ptr ptr UncheckedArray[uint8]](addr nextIn),
      availableOut = addr availableOut,
      nextOut = cast[ptr ptr UncheckedArray[uint8]](addr nextOut),
      totalOut = addr totalOut
    )

    case decoderResult:
      of BROTLI_DECODER_RESULT_SUCCESS:
        # --- the decoder has succeeded in decompressing the data, we can break the loop now

        # result length probably isn't accurate, so we need to set it to
        # the actual number of bytes written by the decoder
        result.setLen(totalOut)
        break
      of BROTLI_DECODER_RESULT_ERROR:
        # --- some error, throw an exception

        # since we're stopping execution of the function here (`raise`),
        # we need to remember to deallocate the decoder state
        BrotliDecoderDestroyInstance(state)

        let err = BrotliDecoderGetErrorCode(state)
        raise newException(BrotliError, "Error decompressing input: " & $BrotliDecoderErrorString(err))
      of BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT:
        # --- the decoder needs more memory for output

        # increment plan step for allocation
        if allocPlanStep < allocationPlan.len:
          inc allocPlanStep

        # increase the result capacity
        result.setLen(result.len + allocationPlan[allocPlanStep])
        
        # since we have more space, we need to let the decompresser know that
        # so we increment the `availableOut` variable, which indicates the
        # remaining size of output buffer
        inc availableOut, allocationPlan[allocPlanStep]
        
        # and update the `nextOut` cursor, so the decompresser knows where to look
        nextOut = cast[uint](addr result[result.len - allocationPlan[allocPlanStep]])
      of BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT:
        # --- decoder needs more input
        
        # ...but the `src` pointer isn't ours
        # throw an error in this case

        BrotliDecoderDestroyInstance(state)
        raise newException(BrotliError, "Error decompressing input: Needs more input data, or `len` parameter inaccurate")

proc decompressBrotli*(src: string, allocationPlan: openArray[int] = defaultAllocationPlan, stateParams: set[BrotliDecoderParameter] = {}): string {.raises: [BrotliError].} =
  ## Decompresses data from `src` and return the uncompressed data as a string.
  ## 
  ## See [proc decompressBrotli(pointer, int, openArray[int], set[BrotliDecoderParameter])] for
  ## descriptions of the other parameters
  decompressBrotli(cstring src, src.len, allocationPlan, stateParams)

proc decompressBrotli*(src: seq[byte], allocationPlan: openArray[int] = defaultAllocationPlan, stateParams: set[BrotliDecoderParameter] = {}): seq[byte] {.raises: [BrotliError].} =
  ## Decompresses data from `src` and return the uncompressed data as a `seq[byte]`.
  ## 
  ## See [proc decompressBrotli(pointer, int, openArray[int], set[BrotliDecoderParameter])] for
  ## descriptions of the other parameters
  cast[seq[byte]](decompressBrotli(cstring cast[string](src), src.len, allocationPlan, stateParams))
