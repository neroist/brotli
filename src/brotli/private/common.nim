## Helper module to make sure `csrc/common/*.c` is only compiled once
## as compiling it twice causes issues

const useStaticCompilation =
  not (defined(useBrotliEncDll) or defined(useBrotliDecDll) or defined(useBrotliAllDll) or defined(useBrotliDll))

when useStaticCompilation or defined(nimdoc):
  when not declared(brotliPrivCommonCompiled):
    {.compile: ("./../csrc/common/*.c", "$#.o").}

  const brotliPrivCommonCompiled* = true
    ## Marker indicating whether or not `common/*.c` has been compiled.
    ## The value doesn't matter, only the constant's declaration does.