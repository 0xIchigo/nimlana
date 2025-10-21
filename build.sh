#!/usr/bin/env bash
set -euo pipefail

# Solana BPF build pipeline for Nim programs
# Nim → C → LLVM bitcode → sbpf-linker

# Tool paths (Homebrew LLVM on macOS)
CLANG="${CLANG:-/opt/homebrew/opt/llvm/bin/clang}"
LINKER="${LINKER:-sbpf-linker}"

# Use system clang if Homebrew version not found
if [[ ! -x "$CLANG" ]]; then
    CLANG="clang"
fi

SRC="entrypoint.nim"
NIM_CACHE="nimcache"
BITCODE="entrypoint.bc"
OUTPUT="build/program.so"

echo "Building Nim Solana BPF Program..."

# Create build directory
mkdir -p build

# Step 1: Compile Nim to C
echo "Step 1: Compiling Nim to C..."
nim c \
  --mm:none \
  --noMain \
  --os:standalone \
  --d:useMalloc \
  --cpu:amd64 \
  --nimcache:"$NIM_CACHE" \
  --compileOnly \
  "$SRC"

# Step 2: Compile C to LLVM bitcode
echo "Step 2: Compiling C to LLVM bitcode..."
NIM_LIB="/opt/homebrew/Cellar/nim/2.2.4/nim/lib"
"$CLANG" \
  -target bpfel \
  -O2 \
  -fno-builtin \
  -fno-stack-protector \
  -emit-llvm \
  -c \
  -o "$BITCODE" \
  "$NIM_CACHE/@mentrypoint.nim.c" \
  -I "$NIM_CACHE" \
  -I "$NIM_LIB"

# Step 3: Link with sbpf-linker
echo "Step 3: Linking with sbpf-linker..."
export DYLD_LIBRARY_PATH="/opt/homebrew/opt/llvm/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
export LLVM_SYS_211_PREFIX="/opt/homebrew/opt/llvm"
"$LINKER" \
  --cpu v3 \
  --export entrypoint \
  -o "$OUTPUT" \
  "$BITCODE"

echo "Build complete: $OUTPUT"