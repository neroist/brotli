# --- i'll just use cint directly instead of this
# type
#   BROTLI_BOOL* = int 
#     ##
#     ##  A portable `bool` replacement.
#     ##
#     ##  ::BROTLI_BOOL is a "documentation" type: actually it is `int`, but in API it
#     ##  denotes a type, whose only values are ::BROTLI_TRUE and ::BROTLI_FALSE.
#     ##
#     ##  ::BROTLI_BOOL values passed to Brotli should either be ::BROTLI_TRUE or
#     ##  ::BROTLI_FALSE, or be a result of ::TO_BROTLI_BOOL macros.
#     ##
#     ##  ::BROTLI_BOOL values returned by Brotli should not be tested for equality
#     ##  with `true`, `false`, ::BROTLI_TRUE, ::BROTLI_FALSE, but rather should be
#     ##  evaluated, for example:
#     ##  ```cpp
#     ##  if (SomeBrotliFunction(encoder, BROTLI_TRUE) &&
#     ##      !OtherBrotliFunction(decoder, BROTLI_FALSE)) {
#     ##    bool x = !!YetAnotherBrotliFunction(encoder, TO_BROLTI_BOOL(2 * 2 == 4));
#     ##    DoSomething(x);
#     ##  }
#     ##  ```
#     ##

# const
#   BROTLI_TRUE* = 1              ##  Portable `true` replacement.
#   BROTLI_FALSE* = 0             ##  Portable `false` replacement.

const
  BROTLI_UINT32_MAX* = (not 0'u32)
  BROTLI_SIZE_MAX* = (not (cast[csize_t](0)))

type
  BrotliAllocFunc* = proc (opaque: pointer; size: csize_t): pointer {.cdecl.} 
    ##
    ##  Allocating function pointer type.
    ##
    ##  :opaque: custom memory manager handle provided by client
    ##  :size: requested memory region size; can not be `0`
    ##
    ## 
    ##  :returns: `0` in the case of failure
    ##  :returns: a valid pointer to a memory region of at least `size` bytes
    ##           long otherwise
    ##

type
  BrotliFreeFunc* = proc (opaque: pointer; address: pointer) {.cdecl.} 
    ##
    ##  Deallocating function pointer type.
    ##
    ##  This function **SHOULD** do nothing if `address` is `0`.
    ##
    ##  :opaque: custom memory manager handle provided by client
    ##  :address: memory region pointer returned by [type BrotliAllocFunc], or `0`
    ##
