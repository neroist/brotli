##  (Opaque) Shared Dictionary definition and utilities.

import ./types

const
  SHARED_BROTLI_MIN_DICTIONARY_WORD_LENGTH* = 4 
  SHARED_BROTLI_MAX_DICTIONARY_WORD_LENGTH* = 31
  SHARED_BROTLI_NUM_DICTIONARY_CONTEXTS* = 64
  SHARED_BROTLI_MAX_COMPOUND_DICTS* = 15

type
  BrotliSharedDictionary* = object # BrotliSharedDictionaryStruct, true defintion in common/shared_dictionary_internal.h
    ##
    ##  Opaque structure that holds shared dictionary data.
    ##
    ##  Allocated and initialized with
    ## [proc BrotliSharedDictionaryCreateInstance].
    ## 
    ##  Cleaned up and deallocated with
    ## [proc BrotliSharedDictionaryDestroyInstance].
    ##

type                          
  BrotliSharedDictionaryType* = enum
    ##  Raw LZ77 prefix dictionary.
    
    BROTLI_SHARED_DICTIONARY_RAW = 0, 
      ##
      ##  Input data type for [proc BrotliSharedDictionaryAttach].
      ##
    
    BROTLI_SHARED_DICTIONARY_SERIALIZED = 1
      ##  Serialized shared dictionary.
      ##
      ##  .. important:: DO NOT USE: methods accepting this value will fail.
      ##

proc BrotliSharedDictionaryCreateInstance*(allocFunc: BrotliAllocFunc;
    freeFunc: BrotliFreeFunc; opaque: pointer): ptr BrotliSharedDictionary {.cdecl,
    importc: "BrotliSharedDictionaryCreateInstance".}
  ##
  ##  Creates an instance of [type BrotliSharedDictionary].
  ##
  ##  Fresh instance has default word dictionary and transforms
  ##  and no LZ77 prefix dictionary.
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
  ##  :returns: `0` if instance can not be allocated or initialized
  ##  :returns: pointer to initialized [type BrotliSharedDictionary] otherwise
  ##
proc BrotliSharedDictionaryDestroyInstance*(dict: ptr BrotliSharedDictionary) {.
    cdecl, importc: "BrotliSharedDictionaryDestroyInstance".}
  ##
  ##  Deinitializes and frees [type BrotliSharedDictionary] instance.
  ##
  ##  :dict: shared dictionary instance to be cleaned up and deallocated
  ##
proc BrotliSharedDictionaryAttach*(dict: ptr BrotliSharedDictionary;
                                  `type`: BrotliSharedDictionaryType;
                                  dataSize: csize_t; data: ptr UncheckedArray[uint8]): cint {.cdecl,
    importc: "BrotliSharedDictionaryAttach".}
  ##
  ##  Attaches dictionary to a given instance of [type BrotliSharedDictionary].
  ##
  ##  Dictionary to be attached is represented in a serialized format as a region
  ##  of memory.
  ##
  ##  Provided data it partially referenced by a resulting (compound) dictionary,
  ##  and should be kept untouched, while at least one compound dictionary uses it.
  ##  This way memory overhead is kept minimal by the cost of additional resource
  ##  management.
  ##
  ##  :dict: dictionary to extend
  ##  :type: type of dictionary to attach
  ##  :data_size: size of `data`
  ##  :data: serialized dictionary of type `type`, with at least `data_size`
  ##         addressable bytes
  ## 
  ##  :returns: `1` if provided dictionary is successfully attached
  ##  :returns: `0` otherwise
  ## 
  ## .. note:: `data` **MUST** be of length `dataSize`
  ##