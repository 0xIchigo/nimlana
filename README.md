# Solana BPF Programs with Nim + `sbpf-linker`

Nimlana is a minimal template for building Solana BPF programs using Nim and [`sbpf-linker`](https://github.com/blueshift-gg/sbpf-linker).

This is unaudited and experimental code, as well as my first time using Nim, so you're an absolute nimrod if you use this in prod. This is meant as a proof of concept for educational purposes only.

Shoutout to the chads at [Blueshift](https://blueshift.gg/), especially [Claire](https://x.com/clairefxyz) for writing `sbpf-linker`. This was heavily inspired by [Clana](https://github.com/Rhovian/clana), since Nim can compile to C.

## Prerequisites

```bash
# Install Nim (macOS)
brew install nim

# Install LLVM/Clang
brew install llvm

# Install Rust nightly (required for sbpf-linker)
rustup install nightly

# Install sbpf-linker with LLVM prefix
LLVM_SYS_211_PREFIX=/opt/homebrew/opt/llvm cargo +nightly install sbpf-linker

# Create LLVM symlink (required for sbpf-linker to find LLVM)
mkdir -p ~/.cargo/lib
ln -sf /opt/homebrew/opt/llvm/lib/libLLVM.dylib ~/.cargo/lib/libLLVM.dylib
```

## Quick Start

```bash
# Build and test everything
make test

# Or step by step:
./build.sh                    # Build the program
cargo +nightly test           # Run tests
```

This generates:
1. `nimcache/entrypoint.nim.c` - Transpiled C code
2. `entrypoint.bc` - LLVM bitcode
3. `build/program.so` - Final Solana program

## Testing

```bash
# Run tests with output
cargo test -- --nocapture

# Or use make
make test
```

## Why This Works

TLDR Nim can be compiled to C, and C can be lowered to LLVM IR, which can be used to generate sBPF bytecode.

### 1. Direct Syscalls via Function Pointers

We're going to use function pointers to call syscalls directly

```nim
# Solana syscall function pointer type
type SolLogFunc = proc(message: ptr uint8, length: uint64) {.cdecl.}

# Cast syscall address to function pointer
const SOL_LOG_ADDR = 0x207559bd'u64
let syscall = cast[SolLogFunc](SOL_LOG_ADDR)
syscall(message, length)
```

The constant `0x207559bd` is the MurmurHash3 of `sol_log_` that the SVM resolves at runtime.

### 2. Zero Runtime Mode

Nim's runtime is completely disabled for sBPF compatibility:

```nim
{.push checks: off.}
{.push boundChecks: off.}
{.push overflowChecks: off.}

# Compile with --mm:none to eliminate garbage collector
```

### 3. Inline String Data

To prevent `sbpf-linker` from stripping `.rodata`, we inline strings as byte arrays:

```nim
var hello_msg: array[15, uint8] = [
  uint8('H'), uint8('e'), uint8('l'), uint8('l'), uint8('o'), ...
]
```

### 4. Build Pipeline

Nimlana uses a three-stage compilation process:

```bash
# Stage 1: Nim → C (transpilation)
nim c --mm:none --noMain --compileOnly entrypoint.nim

# Stage 2: C → LLVM bitcode (targeting BPF)
clang -target bpfel -O2 -emit-llvm -c -o entrypoint.bc nimcache/entrypoint.nim.c

# Stage 3: LLVM bitcode → Solana program
sbpf-linker --cpu v3 --export entrypoint -o build/program.so entrypoint.bc
```

## Inspired By

- [clana](https://github.com/Rhovian/clana) - Solana programs in C
- [swiftana](https://github.com/dhl/swiftana) - Solana programs in Swift
- [zignocchio](https://github.com/vitorpy/zignocchio) - Solana programs in Zig

## License

MIT
