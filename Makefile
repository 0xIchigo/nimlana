.PHONY: all build test clean help
.SILENT:

SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

BUILD_SCRIPT := ./build.sh
OUTPUT := build/program.so

all: build

build:
	@echo "Building Nim Solana BPF program..."
	$(BUILD_SCRIPT)

test: build
	@echo "Running tests..."
	cargo +nightly test -- --nocapture

clean:
	@echo "Cleaning build artifacts..."
	rm -rf build nimcache entrypoint.bc
	@echo "Cleaning cargo artifacts..."
	cargo clean

help:
	@echo "Nim Solana BPF Build Commands:"
	@echo "  make build  - Compile Nim program to Solana BPF"
	@echo "  make test   - Build and run tests"
	@echo "  make clean  - Remove build artifacts"
	@echo "  make all    - Same as 'make build' (default)"