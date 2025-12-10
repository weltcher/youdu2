.PHONY: help build clean run get test build-debug build-release install-deps doctor

# Default target
help:
	@echo "Available commands:"
	@echo "  make build         - Build Windows Release version"
	@echo "  make build-debug   - Build Windows Debug version"
	@echo "  make build-release - Build Windows Release version"
	@echo "  make clean         - Clean build files and cache"
	@echo "  make run           - Run application in Debug mode"
	@echo "  make get           - Get dependencies"
	@echo "  make test          - Run tests"
	@echo "  make doctor        - Check Flutter environment"
	@echo "  make install-deps  - Install/update dependencies"

# Build Windows Release version
build:
	@echo "Building Windows Release version..."
	.\build_incremental.bat
	@echo "Build complete! Executable location: build/windows/x64/runner/Release/"

# Build Windows Release version (alias)
build-release: build

# Build Windows Debug version
build-debug: clean-build get
	@echo "Building Windows Debug version..."
	flutter build windows --debug
	@echo "Build complete! Executable location: build/windows/x64/runner/Debug/"

# Clean build folder only (not dependencies)
clean-build:
	@echo "Cleaning build folder..."
	@rm -rf build 2>/dev/null || true
	@rm -rf windows/flutter/ephemeral 2>/dev/null || true
	@echo "Build folder cleaned"

# Full clean (including dependency cache)
clean:
	@echo "Performing full clean..."
	flutter clean
	@echo "Clean complete!"

# Get dependencies
get:
	@echo "Getting Flutter dependencies..."
	flutter pub get

# Install/update dependencies
install-deps:
	@echo "Updating Flutter dependencies..."
	flutter pub get
	flutter pub upgrade

# Run application (Debug mode)
run:
	@echo "Starting application..."
	flutter run -d windows

# Run tests
test:
	@echo "Running tests..."
	flutter test

# Check Flutter environment
doctor:
	flutter doctor -v

# Analyze code
analyze:
	@echo "Analyzing code..."
	flutter analyze

# Format code
format:
	@echo "Formatting code..."
	flutter format lib/ test/

# Build and run Release version
run-release: build-release
	@echo "Starting Release version..."
	@cd build/windows/x64/runner/Release && ./youdu.exe

# Package for distribution (build + organize files)
package: build-release
	@echo "Packaging application..."
	@mkdir -p release
	@rm -rf release/youdu
	@cp -r build/windows/x64/runner/Release release/youdu
	@echo "Package complete! Release files location: release/youdu/"
	@echo "You can distribute the release/youdu folder to users"

# Clean package files
clean-package:
	@rm -rf release
	@echo "Package files cleaned"

# Full build process (clean -> get deps -> build -> package)
full-build: clean build-release package
	@echo "Full build process complete!"

# View dependency updates
outdated:
	flutter pub outdated

# Upgrade Flutter SDK
upgrade-flutter:
	flutter upgrade

