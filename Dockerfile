# syntax=docker/dockerfile:1
FROM rust:alpine AS builder

# Arguments for multi-arch support
ARG BUILDPLATFORM
ARG TARGETPLATFORM

# Install build dependencies 
RUN apk add --no-cache \
    musl-dev \
    gcc \
    make \
    g++ \
    pkgconfig \
    chromium \
    chromium-chromedriver \
    font-liberation \
    harfbuzz \
    nss \
    freetype \
    ttf-freefont \
    ca-certificates

# Detect architecture and set appropriate target
RUN if [ "$(uname -m)" = "x86_64" ]; then \
      echo "x86_64 architecture detected"; \
      echo "export CARGO_TARGET=x86_64-unknown-linux-musl" > /cargo-target.env; \
    elif [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then \
      echo "ARM64 architecture detected"; \
      echo "export CARGO_TARGET=aarch64-unknown-linux-musl" > /cargo-target.env; \
    else \
      echo "Unknown architecture: $(uname -m)"; \
      exit 1; \
    fi

# Source the environment variables
RUN source /cargo-target.env && echo "Building for target: $CARGO_TARGET"

# Add the required target
RUN source /cargo-target.env && rustup target add $CARGO_TARGET

# Install mdbook
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo-target \
    source /cargo-target.env && \
    RUSTFLAGS="-C target-feature=+crt-static" \
    cargo install mdbook --target=$CARGO_TARGET && \
    strip /usr/local/cargo/bin/mdbook

# Install mdbook-pdf (without cross-compilation flags that could cause issues)
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo-target \
    source /cargo-target.env && \
    RUSTFLAGS="-C target-feature=+crt-static" \
    cargo install mdbook-pdf --target=$CARGO_TARGET && \
    strip /usr/local/cargo/bin/mdbook-pdf

# ====== Final Stage ======
FROM alpine:latest

# Install runtime dependencies for Chromium
RUN apk add --no-cache \
    chromium \
    chromium-chromedriver \
    font-liberation \
    harfbuzz \
    nss \
    freetype \
    ttf-freefont \
    ca-certificates \
    dbus \
    libstdc++

# Create required directories
RUN mkdir -p /etc/chromium /book

# Copy binaries from builder
COPY --from=builder /usr/local/cargo/bin/mdbook /usr/local/bin/mdbook
COPY --from=builder /usr/local/cargo/bin/mdbook-pdf /usr/local/bin/mdbook-pdf

# Setup Chrome for headless usage
ENV CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/ \
    CHROMIUM_FLAGS="--headless --disable-gpu --no-sandbox --disable-dev-shm-usage"

# Create a non-root user
RUN addgroup -S mdbook && \
    adduser -S -G mdbook mdbook && \
    chown -R mdbook:mdbook /book

# Set labels for the image
LABEL org.opencontainers.image.description="Multi-architecture mdbook builder"

# Switch to non-root user
USER mdbook
WORKDIR /book

ENTRYPOINT ["/usr/local/bin/mdbook"]