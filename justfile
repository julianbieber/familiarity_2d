# Bevy Project Justfile
# Uses the official Bevy CLI for build tasks

# Set environment variables
set dotenv-load := true
set shell := ["bash", "-c"]

# Default Rust toolchain
rust_version := "stable"

# Project configuration
project_name := "my_bevy_game"

# Default recipe - shows available commands
default:
    @just --list

# Development Commands
# ===================


# Run the game in release mode
run:
    bevy run --release

# Run with dynamic linking for faster compile times
run-dev:
    bevy run --features bevy/dynamic_linking

# Web Development
# ===============

# Run the game in web browser
run-web:
    bevy run web --open --release

# Code Quality
# ============

# Run Bevy-specific lints
lint:
    bevy lint

# Run standard Rust checks
check:
    cargo check --all-targets --all-features

# Run clippy lints
clippy:
    cargo clippy --all-targets --all-features -- -D warnings

# Format code
fmt:
    cargo fmt --all

# Check formatting without making changes
fmt-check:
    cargo fmt --all -- --check

# Run all tests
test:
    cargo test --all-features

# Run tests with output
test-verbose:
    cargo test --all-features -- --nocapture

# Pre-commit checks (run before committing)
pre-commit: fmt-check clippy lint test
    @echo "✅ All checks passed! Ready to commit."


# Asset Management
# ================

# Watch for asset changes and hot reload
watch:
    cargo watch -x "run --features bevy/file_watcher"

# Build assets (if using custom asset pipeline)
build-assets:
    @echo "Building assets..."
    # Add your asset build commands here

# Performance & Profiling
# =======================

# Run with profiling enabled
profile:
    cargo run --release --features bevy/trace_tracy

# Build optimized release
build-release:
    cargo build --release

# Run benchmarks
bench:
    cargo bench

# Binary size analysis
bloat:
    cargo bloat --release --crates

# Documentation
# =============

# Generate and open documentation
docs:
    cargo doc --no-deps --all-features --open

# Generate docs without opening
docs-build:
    cargo doc --no-deps --all-features

# Deployment
# ==========

# Package for distribution
package:
    cargo package

# Clean build artifacts
clean:
    cargo clean

# Clean and rebuild everything
rebuild: clean
    cargo build

# Platform-specific builds
# =======================

# Build for Windows (from any platform)
build-windows:
    cargo build --release --target x86_64-pc-windows-gnu

# Build for Linux (from any platform)
build-linux:
    cargo build --release --target x86_64-unknown-linux-gnu

# Build for macOS (from any platform)
build-macos:
    cargo build --release --target x86_64-apple-darwin

# Utility Commands
# ================

# Show dependency tree
deps:
    cargo tree

# Update dependencies
update:
    cargo update

# Show outdated dependencies
outdated:
    cargo outdated

# Security audit
audit:
    cargo audit

# Install/update tools
install-tools:
    cargo install cargo-watch cargo-bloat cargo-outdated cargo-audit
    cargo install --git https://github.com/TheBevyFlock/bevy_cli --tag cli-v0.1.0-alpha.2 --locked bevy_cli

# Development workflow
# ===================

# Full development cycle
dev: lint check test run-dev

# Release workflow
release: pre-commit build-release package
    @echo "🚀 Release build complete!"

# Quick iteration cycle for development
quick: fmt check run-dev
