default:
  just --list

# Architecture detection
arch := `uname -m`

platform := if arch == "x86_64" { "amd64" } else if arch == "arm64" { "arm64" } else if arch == "aarch64" { "arm64" } else { "unknown" }
cargo_target := if arch == "x86_64" { "x86_64-unknown-linux-musl" } else if arch == "arm64" { "aarch64-unknown-linux-musl" } else if arch == "aarch64" { "aarch64-unknown-linux-musl" } else { "aarch64-unknown-linux-musl" }

# Define the Docker registry - DockerHub by default
docker_username := "auser"
docker_image := "mdbook-builder"
docker_tag := "latest"

# Full Docker image name with tag for DockerHub
docker_full_image := docker_username + "/" + docker_image + ":" + docker_tag

# Setup the docker container
setup:
  docker compose build --build-arg "CARGO_TARGET={{cargo_target}}"

# Rebuild the container (use after Dockerfile changes)
rebuild:
  docker compose down
  docker compose build --no-cache --build-arg "CARGO_TARGET={{cargo_target}}"
  
# Development server
dev:
  docker compose up

# Build the book with both HTML and PDF
build:
  docker compose run --rm mdbook build /book/book-builder
  rm -rf ./output && mkdir -p ./output
  mv ./book-builder/book/* ./output/

# Check for errors in the book without building
check:
  docker compose run --rm mdbook test /book/book-builder

# Build Docker image for current architecture
build-image:
  docker build -t {{docker_full_image}} .

# Enable Docker buildx for multi-architecture builds
setup-buildx:
  docker buildx inspect --builder default || docker buildx create --name default --driver docker-container --use

# Build multi-architecture image with buildx (without pushing)
# We need to build each platform separately when using --load
build-multiarch: setup-buildx
  # Build for the current platform only, as --load can't handle multiple platforms
  docker buildx build --platform linux/$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/') -t {{docker_full_image}} --load .
  # Output message about multi-platform limitations
  echo "Note: For true multi-architecture builds, use 'just build-push-multiarch' to build and push directly"

# Tag the image with current date for versioning
tag-image-date:
  docker tag {{docker_full_image}} {{docker_username}}/{{docker_image}}:$(date +%Y%m%d)

# Login to Docker Hub (may prompt for credentials)
docker-login:
  docker login

# Push the Docker image to registry
push-image: build-image
  docker push {{docker_full_image}}

# Build and push multi-architecture image
build-push-multiarch: setup-buildx docker-login
  docker buildx build --platform linux/amd64,linux/arm64 -t {{docker_full_image}} -t {{docker_username}}/{{docker_image}}:$(date +%Y%m%d) --push .

# Complete workflow: build, tag, and push Docker image for single architecture
release-image: docker-login build-image tag-image-date push-image
  echo "Image {{docker_image}} built and pushed to registry"

# Complete workflow for multi-architecture image
release-multiarch: docker-login build-push-multiarch
  echo "Multi-architecture image {{docker_image}} built and pushed to registry"