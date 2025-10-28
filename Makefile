# Makefile for Shell Unit Test Framework
# Follows GNU Makefile conventions

# Installation directories
# PREFIX is the runtime prefix (used in paths embedded into wrappers)
PREFIX ?= /usr/local
# DESTDIR is a staging prefix for packaging (left empty in normal installs)
DESTDIR ?=

DATADIR = $(PREFIX)/share
DOCDIR = $(DATADIR)/doc/shellunittest
LIBEXECDIR = $(PREFIX)/libexec
LIBDIR = $(LIBEXECDIR)/shellunittest
BINDIR = $(PREFIX)/bin

# Source files
FRAMEWORK_SRC = src/unittest.sh
EXAMPLE_SRC = examples/example_test.sh
DOC_FILES = README.md INSTALL AUTHORS CHANGELOG NEWS

# Phony targets
.PHONY: all check install uninstall clean help test example

# Default target
all: check
	@echo "Shell Unit Test Framework is ready to use"
	@echo "Run 'make test' to run example tests"
	@echo "Run 'make install' to install system-wide"

# Run tests
check: test

# Run example tests
test: example

example:
	@echo "Running example tests..."
	@./$(EXAMPLE_SRC)
	@echo ""
	@echo "Example tests completed successfully!"

# Run example tests with JSON output
test-json:
	@echo "Running example tests with JSON output..."
	@./$(EXAMPLE_SRC) --format=json --output=test-results.json
	@echo ""
	@echo "JSON output written to test-results.json"
	@cat test-results.json | jq . 2>/dev/null || cat test-results.json

# Run example tests with JUnit output
test-junit:
	@echo "Running example tests with JUnit XML output..."
	@./$(EXAMPLE_SRC) --format=junit --output=test-results.xml
	@echo ""
	@echo "JUnit XML output written to test-results.xml"

# Install system-wide (supports DESTDIR for packaging)
install:
    @echo "Installing Shell Unit Test Framework to $(DESTDIR)$(PREFIX)..."
    install -d $(DESTDIR)$(LIBDIR)
    install -d $(DESTDIR)$(DOCDIR)
    install -d $(DESTDIR)$(BINDIR)
    install -m 0755 $(FRAMEWORK_SRC) $(DESTDIR)$(LIBDIR)/
    install -m 0755 $(EXAMPLE_SRC) $(DESTDIR)$(LIBDIR)/
    install -m 0644 $(DOC_FILES) $(DESTDIR)$(DOCDIR)/
    # Install a small wrapper into bin that executes the runtime libexec script
    printf "#!/usr/bin/env bash\nexec \"%s\" \"\$@\"\n" "$(LIBDIR)/unittest.sh" > $(DESTDIR)$(BINDIR)/unittest
    chmod 0755 $(DESTDIR)$(BINDIR)/unittest
    @echo ""
    @echo "Installation complete!"
    @echo ""
    @echo "You can now run:"
    @echo "  unittest"
    @echo ""
    @echo "Or source directly in your scripts:"
    @echo "  source $(LIBDIR)/unittest.sh"
    @echo ""
    @echo "Documentation installed to: $(DOCDIR)"

# Uninstall
uninstall:
    @echo "Uninstalling Shell Unit Test Framework from $(DESTDIR)$(PREFIX)..."
    rm -f $(DESTDIR)$(BINDIR)/unittest
    rm -rf $(DESTDIR)$(LIBDIR)
    rm -rf $(DESTDIR)$(DOCDIR)
    @echo "Uninstallation complete!"

# Clean generated files
clean:
	@echo "Cleaning generated test result files..."
	rm -f test-results*.json test-results*.xml test-results*.yaml test-results*.csv
	@echo "Clean complete!"

# Clean everything (including backup files)
distclean: clean
	@echo "Deep cleaning..."
	rm -f *~ *.bak
	@echo "Deep clean complete!"

# Show help
help:
    @echo "Shell Unit Test Framework - Makefile targets:"
	@echo ""
	@echo "  make                 - Default target (same as 'make check')"
	@echo "  make check           - Run example tests"
	@echo "  make test            - Run example tests"
	@echo "  make example         - Run example tests"
	@echo "  make test-json       - Run tests with JSON output"
	@echo "  make test-junit      - Run tests with JUnit XML output"
    @echo "  make install         - Install system-wide (supports DESTDIR)"
    @echo "  make uninstall       - Remove system-wide installation"
	@echo "  make clean           - Remove generated test result files"
	@echo "  make distclean       - Remove all generated and backup files"
	@echo "  make help            - Show this help message"
	@echo ""
	@echo "Installation directories (can be overridden):"
	@echo "  PREFIX = $(PREFIX)"
    @echo "  BINDIR = $(BINDIR)"
    @echo "  LIBDIR = $(LIBDIR)"
    @echo "  DOCDIR = $(DOCDIR)"
    @echo ""
    @echo "Supports DESTDIR for packaging (e.g., Homebrew/Linuxbrew)."
    @echo "Examples:"
    @echo "  make install PREFIX=/opt/local"
    @echo "  make install DESTDIR=/tmp/stage"
