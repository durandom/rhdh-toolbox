# RHDH Toolbox

A container image for working with Red Hat Developer Hub (RHDH).

## Building the Container Image

This repository includes a Makefile to simplify building and managing the container image, with support for multiple architectures (AMD64 and ARM64).

### Prerequisites

You need either Podman or Docker installed on your system to build the container image.

### Available Make Targets

| Target | Description |
|---------|-------------|
| `make build` | Build the container image for your current architecture |
| `make build-amd64` | Build image specifically for AMD64 architecture |
| `make build-arm64` | Build image specifically for ARM64 architecture |
| `make build-multi` | Build multi-architecture image (AMD64 and ARM64) |
| `make push` | Push the container image to the registry |
| `make build-push-multi` | Build and push multi-architecture image in one step |
| `make clean` | Remove all local container images |
| `make help` | Show help documentation for all targets |

### Customizable Variables

You can customize the build by setting these variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `BUILD_TOOL` | Tool to use for building (podman or docker) | `podman` |
| `REGISTRY` | Registry to push images to | `quay.io/mhild` |
| `VERSION` | Version tag for the image | `0.1` |

### Examples

#### Build with podman (default)

```bash
# Build for current architecture
make build

# Build for multiple architectures
make build-multi
```

#### Build with Docker instead of Podman

```bash
# Build for current architecture using Docker
make build BUILD_TOOL=docker

# Build for multiple architectures using Docker
make build-multi BUILD_TOOL=docker
```

#### Push to a different registry

```bash
# Build and push to a custom registry
make build-push-multi REGISTRY=quay.io/yourusername
```

### Understanding Multi-Architecture Builds

The Makefile handles multi-architecture builds differently depending on the build tool:

- **With Podman**: Builds separate images for each architecture with `-amd64` and `-arm64` suffixes, then creates a manifest that combines them.

- **With Docker**: Uses Docker's buildx capability to create multi-architecture images directly.

The final image will automatically use the appropriate architecture version when pulled on different platforms.

## Usage

After building the container image, you can use it with the toolbox command:

```bash
# Create a toolbox using the built image
toolbox create --image rhdh-toolbox:latest

# Enter the toolbox
toolbox enter rhdh-toolbox
```

## Container Contents

The container image includes tools for working with Red Hat Developer Hub:

- Node.js development environment
- Yarn package manager
- Janus IDP CLI
- Backstage CLI
- Container tools (podman, buildah)
- Development libraries and build tools
