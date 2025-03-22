# mdbook-builder Docker Image

A multi-architecture Docker image for building and serving [mdBook](https://rust-lang.github.io/mdBook/) documentation with PDF export capability.

## Features

- ✅ Multi-architecture support (AMD64/ARM64)
- ✅ PDF generation via mdbook-pdf
- ✅ Chromium headless browser for PDF rendering
- ✅ Small footprint with Alpine Linux base
- ✅ Security-focused with non-root user

## Quick Start

### Pull the image from Docker Hub

```bash
docker pull auser/mdbook-builder:latest
```

### Building a book

Mount your book directory to `/book` and run:

```bash
docker run --rm -v ${PWD}:/book auser/mdbook-builder build
```

### Development server

To serve your book with live reloading:

```bash
docker run --rm -p 8989:8989 -v ${PWD}:/book auser/mdbook-builder serve --hostname 0.0.0.0
```

Then access your book at http://localhost:8989

## Using with Docker Compose

Create a `docker-compose.yml` file:

```yaml
services:
  mdbook:
    image: auser/mdbook-builder:latest
    ports:
      - 8989:8989
    volumes:
      - ${PWD}:/book
    command:
      - serve
      - --hostname
      - '0.0.0.0'
      - --port
      - '8989'
```

Then run:

```bash
docker compose up
```

## Using with Just

This repository includes a Justfile with common commands for development and building:

```bash
# Setup
just setup

# Development server
just dev

# Build the book (HTML and PDF)
just build

# Check for errors
just check
```

## Building the Image

### Single Architecture

```bash
just build-image
```

### Multi-Architecture (AMD64 and ARM64)

```bash
just build-push-multiarch
```

## Environment Variables

| Variable       | Description                 | Default                                                       |
| -------------- | --------------------------- | ------------------------------------------------------------- |
| CHROME_BIN     | Path to Chromium binary     | /usr/bin/chromium-browser                                     |
| CHROME_PATH    | Path to Chromium libraries  | /usr/lib/chromium/                                            |
| CHROMIUM_FLAGS | Flags for headless Chromium | --headless --disable-gpu --no-sandbox --disable-dev-shm-usage |

## License

This project is open source and available under the MIT license.
