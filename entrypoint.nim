# Minimal sBPF program in Nim
# This demonstrates a proof of concept for compiling Nim to sBPF

# Disable Nim runtime features
{.push checks: off.}
{.push boundChecks: off.}
{.push overflowChecks: off.}

# Solana syscall function pointer type
type SolLogFunc = proc(message: ptr uint8, length: uint64) {.cdecl, raises: [].}

# Solana syscall hash for sol_log_
const SOL_LOG_ADDR = 0x207559bd'u64

# Direct syscall invocation via function pointer
proc sol_log(message: ptr uint8, length: uint64) {.inline, raises: [].} =
  let syscall = cast[SolLogFunc](SOL_LOG_ADDR)
  syscall(message, length)

# We take an input pointer
# It contains the accounts, instruction data, and the program id to match
# the expected entrypoint signature
proc entrypoint(input: pointer): uint64 {.exportc, cdecl, raises: [].} =
  # Inline string data (to prevent sbpf-linker from stripping .rodata)
  const message: array[15, uint8] = [
    uint8('H'), uint8('e'), uint8('l'), uint8('l'), uint8('o'),
    uint8(' '), uint8('f'), uint8('r'), uint8('o'), uint8('m'),
    uint8(' '), uint8('N'), uint8('i'), uint8('m'), uint8('!')
  ]

  sol_log(unsafeAddr message[0], 15)

  return 0

{.pop.}
{.pop.}
{.pop.}