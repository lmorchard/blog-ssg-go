# blog-ssg (Go Static Site Generator)

A standalone, zero-`node_modules` static site generator for [blog.lmorchard.com](https://blog.lmorchard.com), written in Go.

## Features

- **Blazingly Fast:** Builds 24 years of archives (1,400+ posts, pages, and 700+ tag indexes) in ~5 seconds.
- **Single Self-Contained Binary:** All HTML templates are embedded directly into the binary via `//go:embed`.
- **Zero `node_modules` Requirement:** Normal site generation runs with zero npm packages or Node runtime.
- **Embedded Defaults + Eject:** Ships with built-in templates out of the box; check `./templates` on disk for runtime overrides, or eject them all via `blog-ssg eject`.
- **Integrated Pagefind Search:** Detects and runs Pagefind indexing automatically at the end of the build.
- **Native Retro Dithering & Optimization:** Pure-Go Floyd-Steinberg color quantization and nearest-neighbor upscaling for retro pixelated images (`pkg/imageutil`).
- **Live Watch & Dev Server:** Built-in dev server on port 9980 with debounced recursive file watching (`fsnotify`) for instant live rebuilds.

## Quick Start with Makefile

A `Makefile` is included with common development and publishing tasks:

```bash
make help         # Show all available targets
make dev          # Start preview server on http://localhost:9980 with file watching & drafts
make build        # Full production build (with Pagefind search indexing)
make build-dev    # Fast development build (drafts enabled, search skipped)
make search       # Run Pagefind search indexing on build output
make compare      # Run automated QA DOM comparison against Node build
make test         # Run Go package unit tests
make fmt          # Format Go source code
make eject        # Eject embedded templates to ./templates for editing
make clean        # Remove build artifacts and binary
```

## Installation / Build

```bash
cd projects/blog-ssg-go
go build -o blog-ssg ./cmd/blog-ssg
```

## Usage

```bash
# Build the entire blog
./blog-ssg build \
  -posts ../../blog.lmorchard.com/content/posts \
  -pages ../../blog.lmorchard.com/content/pages \
  -public ../../blog.lmorchard.com/content/public \
  -uploads ../../blog.lmorchard.com/content/uploads \
  -build build

# Clean output first and skip search indexer for fast iteration
./blog-ssg build -clean -search=false

# Find draft posts with only placeholder text (dry-run)
./blog-ssg clean-empty-drafts -posts content/posts

# Permanently delete empty placeholder drafts
./blog-ssg clean-empty-drafts -posts content/posts -delete

# Eject default templates to disk for customization
./blog-ssg eject templates/

# Start local preview server with live file watching on port 9980
./blog-ssg serve -w

# Apply retro Floyd-Steinberg dithering to an image
./blog-ssg dither photo.jpg -o photo-dithered.png -colors 32 -downscale 0.33 -upscale 3.0

# Optimize / compress JPEG and PNG images
./blog-ssg optimize-images content/posts/2026/my-post/
```

## Architectural Invariants

### 1. Vendor JS Bundle Pattern
All custom web components are written as native browser ES modules. Any third-party npm package required by a component (such as `beautiful-mermaid`) must be compiled once into a standalone ESM bundle and committed directly to `content/public/js/vendor/bundles/`. The generator copies static public assets straight to output without invoking npm or Node.

### 2. Layered Template Fallback
Templates look for files in `./templates/` on disk first. If a template file exists on disk, it overrides the default; otherwise, it falls back to the embedded binary defaults.

### 3. Chronological Post Invariants
Posts are indexed descending (newest first). `prevPost` points to the chronologically earlier (older) post, and `nextPost` points to the chronologically later (newer) post.
