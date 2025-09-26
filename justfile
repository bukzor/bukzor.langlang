# Development commands for LangLang

# Build everything
build:
    cargo build

# Build release version
build-release:
    cargo build --release

# Run tests
test:
    cargo test

# Check code without building
check:
    cargo check

# Format code
fmt:
    cargo fmt

# Lint code
lint:
    cargo clippy -- -D warnings

# Generate Cap'n Proto schemas
schemas:
    cd crates/common && cargo build

# Clean build artifacts
clean:
    cargo clean

# Full development cycle
dev: fmt lint test build

# Install CLI tool locally
install:
    cargo install --path crates/cli

# Example: Parse a Python config
example-python file:
    echo "def config(): return {'db': 'localhost'}" | cargo run --bin langlang-parser -- --language python

# Example: Full pipeline (when components are ready)
example-pipeline file:
    cat {{file}} | \
    cargo run --bin langlang-parser -- --language python | \
    cargo run --bin langlang-typechecker | \
    cargo run --bin langlang-fomega-encoder | \
    cargo run --bin langlang-evaluator

# Run a specific component
run-parser:
    cargo run --bin langlang-parser

run-typechecker:
    cargo run --bin langlang-typechecker

run-encoder:
    cargo run --bin langlang-fomega-encoder

run-evaluator:
    cargo run --bin langlang-evaluator

# Debug pipeline with Cap'n Proto inspection
debug-pipeline file:
    cat {{file}} | cargo run --bin langlang-parser -- --language python > /tmp/ast.capnp
    echo "AST generated, inspect with: capnp decode --short schema/ast.capnp ASTNode < /tmp/ast.capnp"

# Performance testing
perf-test:
    cargo build --release
    hyperfine 'cat examples/large-config.py | ./target/release/langlang-parser --language python'

# Documentation
docs:
    cargo doc --open

# Update dependencies
update:
    cargo update