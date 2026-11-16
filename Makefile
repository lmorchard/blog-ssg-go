.PHONY: all build-bin build build-dev dev start serve search compare test fmt eject clean clean-empty-drafts clean-empty-drafts-force help

# Configuration
CONTENT_DIR ?= ../../blog.lmorchard.com
POSTS_DIR   ?= $(CONTENT_DIR)/content/posts
PAGES_DIR   ?= $(CONTENT_DIR)/content/pages
PUBLIC_DIR  ?= $(CONTENT_DIR)/content/public
UPLOADS_DIR ?= $(CONTENT_DIR)/content/uploads
BUILD_DIR   ?= build-test
PORT        ?= 9980

BIN         := blog-ssg

# Build flags
COMMON_FLAGS := -posts $(POSTS_DIR) -pages $(PAGES_DIR) -public $(PUBLIC_DIR) -uploads $(UPLOADS_DIR) -build $(BUILD_DIR)

all: build-bin

help:
	@echo "blog-ssg-go Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build-bin                 Compile the blog-ssg CLI binary"
	@echo "  make dev                       Start dev server with file watcher & drafts on http://localhost:$(PORT)"
	@echo "  make build                     Full production build with Pagefind search indexing"
	@echo "  make build-dev                 Fast development build (drafts enabled, search skipped)"
	@echo "  make serve                     Start static preview server on port $(PORT)"
	@echo "  make search                    Run Pagefind search indexing on $(BUILD_DIR)"
	@echo "  make compare                   Run DOM comparison against Node build"
	@echo "  make clean-empty-drafts        Find empty placeholder drafts (dry-run)"
	@echo "  make clean-empty-drafts-force  Delete empty placeholder drafts"
	@echo "  make test                      Run Go unit tests"
	@echo "  make fmt                       Format all Go code"
	@echo "  make eject                     Eject embedded templates to ./templates for editing"
	@echo "  make clean                     Remove build directory and binary"
	@echo ""
	@echo "Variables:"
	@echo "  CONTENT_DIR=$(CONTENT_DIR)"
	@echo "  BUILD_DIR=$(BUILD_DIR)"
	@echo "  PORT=$(PORT)"

# Compile the Go CLI binary
build-bin:
	go build -o $(BIN) ./cmd/blog-ssg

# Full production build (with Pagefind search)
build: build-bin
	./$(BIN) build $(COMMON_FLAGS) -clean -search=true

# Fast dev build (includes drafts, skips search)
build-dev: build-bin
	./$(BIN) build $(COMMON_FLAGS) -drafts -search=false

# Start dev server with file watching and live rebuilds
dev start: build-bin
	./$(BIN) serve -w $(COMMON_FLAGS) -drafts -port $(PORT)

# Static file preview server without watcher
serve: build-bin
	./$(BIN) serve -build $(BUILD_DIR) -port $(PORT)

# Run Pagefind search indexing on existing build
search:
	@if command -v pagefind >/dev/null 2>&1; then \
		pagefind --site $(BUILD_DIR); \
	elif [ -x "$(CONTENT_DIR)/node_modules/.bin/pagefind" ]; then \
		$(CONTENT_DIR)/node_modules/.bin/pagefind --site $(BUILD_DIR); \
	else \
		echo "❌ pagefind not found on PATH or in $(CONTENT_DIR)/node_modules/.bin"; \
		exit 1; \
	fi

# Compare Go build output against Node build output
compare:
	go run ./cmd/compare-builds -node $(CONTENT_DIR)/build -go $(BUILD_DIR)

# Find empty placeholder draft posts (dry run)
clean-empty-drafts: build-bin
	./$(BIN) clean-empty-drafts -posts $(POSTS_DIR)

# Permanently delete empty placeholder draft posts
clean-empty-drafts-force: build-bin
	./$(BIN) clean-empty-drafts -posts $(POSTS_DIR) -delete

# Run all package unit tests
test:
	go test -v ./...

# Format all Go source files
fmt:
	go fmt ./...

# Eject embedded templates to disk
eject: build-bin
	./$(BIN) eject ./templates

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) $(BIN)
