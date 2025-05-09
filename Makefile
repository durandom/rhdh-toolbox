# Makefile for building rhdh-toolbox container image

# Variables - simplified
NAME := rhdh-toolbox
VERSION := 0.1
REGISTRY ?= quay.io/mhild

# Image names - local images have no registry prefix
LOCAL_IMAGE := $(NAME):$(VERSION)
LOCAL_LATEST := $(NAME):latest
# Registry images include the registry prefix
REMOTE_IMAGE := $(REGISTRY)/$(NAME):$(VERSION)
REMOTE_LATEST := $(REGISTRY)/$(NAME):latest

PLATFORMS := linux/amd64,linux/arm64
BUILD_TOOL ?= podman

# Default target
.PHONY: all
all: build

# Build for current architecture - always build local images
.PHONY: build
build:
	$(BUILD_TOOL) build -t $(LOCAL_IMAGE) -t $(LOCAL_LATEST) -f Containerfile .
	@echo "Built $(LOCAL_IMAGE) for current architecture"

# Architecture-specific builds - build with local names
.PHONY: build-amd64
build-amd64:
	$(BUILD_TOOL) build --platform linux/amd64 -t $(LOCAL_IMAGE)-amd64 -f Containerfile .
	@echo "Built $(LOCAL_IMAGE)-amd64 for AMD64 architecture"

.PHONY: build-arm64
build-arm64:
	$(BUILD_TOOL) build --platform linux/arm64 -t $(LOCAL_IMAGE)-arm64 -f Containerfile .
	@echo "Built $(LOCAL_IMAGE)-arm64 for ARM64 architecture"

# Build multi-architecture image - combines the architecture-specific images
.PHONY: build-multi
build-multi: build-amd64 build-arm64
ifeq ($(BUILD_TOOL), podman)
	# Remove existing manifests if they exist
	-$(BUILD_TOOL) manifest rm $(LOCAL_IMAGE) 2>/dev/null || true
	-$(BUILD_TOOL) manifest rm $(LOCAL_LATEST) 2>/dev/null || true
	# Force remove any existing images with the same tags
	-$(BUILD_TOOL) rmi -f $(LOCAL_IMAGE) 2>/dev/null || true
	-$(BUILD_TOOL) rmi -f $(LOCAL_LATEST) 2>/dev/null || true
	# Also try with localhost prefix that podman sometimes adds
	-$(BUILD_TOOL) rmi -f localhost/$(LOCAL_IMAGE) 2>/dev/null || true
	-$(BUILD_TOOL) rmi -f localhost/$(LOCAL_LATEST) 2>/dev/null || true
	# Create manifest for versioned tag (with --amend to replace if it exists)
	$(BUILD_TOOL) manifest create --amend $(LOCAL_IMAGE) $(LOCAL_IMAGE)-amd64 $(LOCAL_IMAGE)-arm64
	# Create manifest for latest tag (with --amend to replace if it exists)
	$(BUILD_TOOL) manifest create --amend $(LOCAL_LATEST) $(LOCAL_IMAGE)-amd64 $(LOCAL_IMAGE)-arm64
	@echo "Created multi-arch manifest for $(LOCAL_IMAGE) and $(LOCAL_LATEST)"
else
	# Docker buildx can build multi-arch images directly
	$(BUILD_TOOL) buildx build --platform $(PLATFORMS) -t $(LOCAL_IMAGE) -t $(LOCAL_LATEST) -f Containerfile --load .
	@echo "Built $(LOCAL_IMAGE) for $(PLATFORMS)"
endif

# Push to registry - tag local images with registry prefix and push
.PHONY: push
push:
ifeq ($(BUILD_TOOL), podman)
	# For podman, check if local manifests exist
	if ! $(BUILD_TOOL) manifest exists $(LOCAL_IMAGE) 2>/dev/null; then \
		echo "No local manifest exists. Run 'make build-multi' first."; \
		exit 1; \
	fi
	# Tag local manifests with registry prefix
	$(BUILD_TOOL) manifest push $(LOCAL_IMAGE) docker://$(REMOTE_IMAGE)
	$(BUILD_TOOL) manifest push $(LOCAL_LATEST) docker://$(REMOTE_LATEST)
else
	# For docker, tag and push
	$(BUILD_TOOL) tag $(LOCAL_IMAGE) $(REMOTE_IMAGE)
	$(BUILD_TOOL) tag $(LOCAL_LATEST) $(REMOTE_LATEST)
	$(BUILD_TOOL) push $(REMOTE_IMAGE)
	$(BUILD_TOOL) push $(REMOTE_LATEST)
endif
	@echo "Pushed images to $(REGISTRY)"

# Add a specific target for building and pushing multi-arch in one go
.PHONY: build-push-multi
build-push-multi: build-multi push
	@echo "Built and pushed multi-architecture images to $(REGISTRY)"

# Clean
.PHONY: clean
clean:
	@echo "Removing local images"
	-$(BUILD_TOOL) rmi -f $(LOCAL_IMAGE) $(LOCAL_LATEST) 2>/dev/null || true
	-$(BUILD_TOOL) rmi -f $(LOCAL_IMAGE)-amd64 $(LOCAL_IMAGE)-arm64 2>/dev/null || true
	-$(BUILD_TOOL) rmi -f localhost/$(LOCAL_IMAGE) localhost/$(LOCAL_LATEST) 2>/dev/null || true
	-$(BUILD_TOOL) rmi -f localhost/$(LOCAL_IMAGE)-amd64 localhost/$(LOCAL_IMAGE)-arm64 2>/dev/null || true
	-$(BUILD_TOOL) manifest rm $(LOCAL_IMAGE) $(LOCAL_LATEST) 2>/dev/null || true

# Help documentation
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build             - Build container image for current architecture"
	@echo "  build-multi       - Build multi-architecture container image ($(PLATFORMS))"
	@echo "  push              - Push container image to registry"
	@echo "  build-push-multi  - Build and push multi-architecture container image"
	@echo "  clean             - Remove local container images"
	@echo "  help              - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  BUILD_TOOL   - Tool to use for building (podman or docker), current: $(BUILD_TOOL)"
	@echo "  REGISTRY     - Registry to push to, current: $(REGISTRY)"
	@echo "  VERSION      - Image version tag, current: $(VERSION)"
