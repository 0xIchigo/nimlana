# Panic override for sBPF (no-std environment)
# Disable all panic handling since we're in a constrained environment

{.push stackTrace: off.}

proc rawoutput(s: string) = discard

# Just halt execution
proc panic(s: string) {.noreturn.} =
  while true: discard

{.pop.}
