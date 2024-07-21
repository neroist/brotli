# Package

version       = "0.1.0"
author        = "neroist"
description   = "Nim Brotli wrapper"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"


# Tasks

task docs, "Build documentation":
  selfExec"doc src/brotli"
