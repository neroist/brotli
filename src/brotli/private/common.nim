## Helper module to make sure `csrc/common/*.c` is only compiled once
## as compiling it twice causes issues

when not declared(brotliPrivCommonCompiled):
  {.compile: ("./../csrc/common/*.c", "$#.o").}

const brotliPrivCommonCompiled* = true
  ## Marker indicating whether or not `common/*.c` has been compiled.
  ## The value doesn't matter, only the constant's declaration does.