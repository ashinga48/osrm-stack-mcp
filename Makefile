.PHONY: help extract start stop start-all stop-all restart logs status clean volume-ls volume-rm mcp-venv mcp-install mcp-test mcp-check mcp-validate

# Load environment variables from .env file
include .env
export

# Container runtime detection (docker or podman)
# Uses CONTAINER_RUNTIME from .env or defaults to docker
# Can be overridden: make start-all CONTAINER_RUNTIME=podman
CONTAINER_RUNTIME ?= docker

# Volume name (based on COMPOSE_PROJECT_NAME from .env)
VOLUME_NAME = $(COMPOSE_PROJECT_NAME)_osrm-data

# Default target
help:
	@echo "Container Runtime: $(CONTAINER_RUNTIME)"
	@echo "Set CONTAINER_RUNTIME=podman in .env or override: make start-all CONTAINER_RUNTIME=podman"
	@echo ""
	@echo "OSRM Makefile Commands:"
	@echo "  make extract                    - Pre-process OSM data (extract, partition, customize)"
	@echo "  make start service=<name>       - Start a specific service (osrm-backend or osrm-frontend)"
	@echo "  make stop service=<name>        - Stop a specific service (osrm-backend or osrm-frontend)"
	@echo "  make start-all                 - Start all services"
	@echo "  make stop-all                  - Stop all services"
	@echo "  make restart service=<name>     - Restart a specific service"
	@echo "  make logs service=<name>        - View logs for a specific service"
	@echo "  make status                    - Show status of all services"
	@echo "  make clean                     - Stop and remove all containers"
	@echo "  make destroy                   - Stop containers and remove ALL data (Reset)"
	@echo "  make volume-ls                 - List volumes"
	@echo "  make volume-rm                 - Remove OSRM data volume"
	@echo ""
	@echo "MCP Server Commands:"
	@echo "  make mcp-venv                  - Create Python virtual environment"
	@echo "  make mcp-install               - Install MCP server dependencies in venv"
	@echo "  make mcp-check                 - Check if MCP dependencies are installed"
	@echo "  make mcp-test                  - Test MCP server connection to OSRM"
	@echo "  make mcp-validate              - Validate MCP server configuration"

# Pre-process OSM data
extract:
	@echo "Extracting OSM data using $(CONTAINER_RUNTIME)..."
	@echo "Volume: $(VOLUME_NAME)"
	@if [ ! -f "./_data/berlin.pbf" ]; then \
		echo "Error: Source file ./_data/berlin.pbf not found"; \
		exit 1; \
	fi
	@echo "Step 1: Ensuring volume exists..."
	@$(CONTAINER_RUNTIME) volume create $(VOLUME_NAME) 2>/dev/null || echo "Volume already exists"
	@echo "Step 2: Copying source PBF file to volume..."
	@$(CONTAINER_RUNTIME) run --rm -v $(VOLUME_NAME):/data -v "$$(pwd)/_data:/source:ro" alpine sh -c "cp /source/berlin.pbf /data/berlin.pbf && ls -lh /data/berlin.pbf"
	@echo "Step 3: Extracting OSM data..."
	@$(CONTAINER_RUNTIME) run --rm -v $(VOLUME_NAME):/data ghcr.io/project-osrm/osrm-backend osrm-extract -p /opt/car.lua /data/berlin.pbf
	@echo "Step 4: Partitioning graph (MLD algorithm)..."
	@$(CONTAINER_RUNTIME) run --rm -v $(VOLUME_NAME):/data ghcr.io/project-osrm/osrm-backend osrm-partition /data/berlin.osrm
	@echo "Step 5: Customizing graph (MLD algorithm)..."
	@$(CONTAINER_RUNTIME) run --rm -v $(VOLUME_NAME):/data ghcr.io/project-osrm/osrm-backend osrm-customize /data/berlin.osrm
	@echo "✓ Pre-processing complete! Data stored in '$(VOLUME_NAME)' volume"

# Start a specific service
start:
	@if [ -z "$(service)" ]; then \
		echo "Error: Please specify a service name (osrm-backend or osrm-frontend)"; \
		echo "Usage: make start service=osrm-backend"; \
		exit 1; \
	fi
	@RUNTIME=$(CONTAINER_RUNTIME); \
	if command -v $${RUNTIME}-compose > /dev/null 2>&1; then \
		$${RUNTIME}-compose up -d $(service); \
	elif $${RUNTIME} compose version > /dev/null 2>&1; then \
		$${RUNTIME} compose up -d $(service); \
	else \
		echo "Error: $${RUNTIME}-compose or $${RUNTIME} compose not found"; \
		exit 1; \
	fi
	@echo "Started $(service) using $(CONTAINER_RUNTIME)"

# Stop a specific service
stop:
	@if [ -z "$(service)" ]; then \
		echo "Error: Please specify a service name (osrm-backend or osrm-frontend)"; \
		echo "Usage: make stop service=osrm-backend"; \
		exit 1; \
	fi
	@RUNTIME=$(CONTAINER_RUNTIME); \
	if command -v $${RUNTIME}-compose > /dev/null 2>&1; then \
		$${RUNTIME}-compose stop $(service); \
	elif $${RUNTIME} compose version > /dev/null 2>&1; then \
		$${RUNTIME} compose stop $(service); \
	else \
		echo "Error: $${RUNTIME}-compose or $${RUNTIME} compose not found"; \
		exit 1; \
	fi
	@echo "Stopped $(service)"

# Start all services
start-all:
	@RUNTIME=$(CONTAINER_RUNTIME); \
	if command -v $${RUNTIME}-compose > /dev/null 2>&1; then \
		$${RUNTIME}-compose up -d; \
	elif $${RUNTIME} compose version > /dev/null 2>&1; then \
		$${RUNTIME} compose up -d; \
	else \
		echo "Error: $${RUNTIME}-compose or $${RUNTIME} compose not found"; \
		exit 1; \
	fi
	@echo "Started all services using $(CONTAINER_RUNTIME)"

# Stop all services
stop-all:
	@RUNTIME=$(CONTAINER_RUNTIME); \
	if command -v $${RUNTIME}-compose > /dev/null 2>&1; then \
		$${RUNTIME}-compose down; \
	elif $${RUNTIME} compose version > /dev/null 2>&1; then \
		$${RUNTIME} compose down; \
	else \
		echo "Error: $${RUNTIME}-compose or $${RUNTIME} compose not found"; \
		exit 1; \
	fi
	@echo "Stopped all services"

# Restart a specific service
restart:
	@if [ -z "$(service)" ]; then \
		echo "Error: Please specify a service name (osrm-backend or osrm-frontend)"; \
		echo "Usage: make restart service=osrm-backend"; \
		exit 1; \
	fi
	@RUNTIME=$(CONTAINER_RUNTIME); \
	if command -v $${RUNTIME}-compose > /dev/null 2>&1; then \
		$${RUNTIME}-compose restart $(service); \
	elif $${RUNTIME} compose version > /dev/null 2>&1; then \
		$${RUNTIME} compose restart $(service); \
	else \
		echo "Error: $${RUNTIME}-compose or $${RUNTIME} compose not found"; \
		exit 1; \
	fi
	@echo "Restarted $(service)"

# View logs for a specific service
logs:
	@if [ -z "$(service)" ]; then \
		echo "Error: Please specify a service name (osrm-backend or osrm-frontend)"; \
		echo "Usage: make logs service=osrm-backend"; \
		exit 1; \
	fi
	@RUNTIME=$(CONTAINER_RUNTIME); \
	if command -v $${RUNTIME}-compose > /dev/null 2>&1; then \
		$${RUNTIME}-compose logs -f $(service); \
	elif $${RUNTIME} compose version > /dev/null 2>&1; then \
		$${RUNTIME} compose logs -f $(service); \
	else \
		echo "Error: $${RUNTIME}-compose or $${RUNTIME} compose not found"; \
		exit 1; \
	fi

# Show status of all services
status:
	@RUNTIME=$(CONTAINER_RUNTIME); \
	if command -v $${RUNTIME}-compose > /dev/null 2>&1; then \
		$${RUNTIME}-compose ps; \
	elif $${RUNTIME} compose version > /dev/null 2>&1; then \
		$${RUNTIME} compose ps; \
	else \
		echo "Error: $${RUNTIME}-compose or $${RUNTIME} compose not found"; \
		exit 1; \
	fi

# Clean up - stop and remove all containers
clean:
	@RUNTIME=$(CONTAINER_RUNTIME); \
	if command -v $${RUNTIME}-compose > /dev/null 2>&1; then \
		$${RUNTIME}-compose down; \
	elif $${RUNTIME} compose version > /dev/null 2>&1; then \
		$${RUNTIME} compose down; \
	else \
		echo "Error: $${RUNTIME}-compose or $${RUNTIME} compose not found"; \
		exit 1; \
	fi
	@echo "Cleaned up all containers"

# Destroy everything - stops containers, removes them, and deletes data volume
destroy: clean
	@echo "Destroying everything including data volumes..."
	@make volume-rm FORCE=1
	@echo "✓ Stack destroyed successfully"

# Volume management commands

# List volumes
volume-ls:
	@echo "OSRM-related volumes:"
	@$(CONTAINER_RUNTIME) volume ls | grep -E "(osrm|$(COMPOSE_PROJECT_NAME))" || echo "No OSRM volumes found"

# Remove OSRM data volume (WARNING: This deletes all processed data!)
volume-rm:
	@echo "WARNING: This will delete the OSRM data volume: $(VOLUME_NAME)"
	@echo "This action cannot be undone. All processed OSRM data will be lost."
	@echo "To proceed, run: $(CONTAINER_RUNTIME) volume rm $(VOLUME_NAME)"
	@echo "Or set FORCE=1 to remove without confirmation: make volume-rm FORCE=1"
	@if [ "$(FORCE)" = "1" ]; then \
		$(CONTAINER_RUNTIME) volume rm $(VOLUME_NAME) 2>/dev/null || echo "Volume does not exist or is in use"; \
	fi

# MCP Server Commands

# Python virtual environment path
VENV = venv
PYTHON = $(VENV)/bin/python
PIP = $(VENV)/bin/pip

# Create Python virtual environment
mcp-venv:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Creating Python virtual environment..."; \
		python3 -m venv $(VENV); \
		echo "✓ Virtual environment created"; \
	else \
		echo "✓ Virtual environment already exists"; \
	fi

# Install MCP server dependencies
mcp-install: mcp-venv
	@echo "Installing MCP server dependencies..."
	@$(PIP) install --upgrade pip
	@$(PIP) install -r requirements.txt
	@echo "✓ MCP dependencies installed!"

# Check if MCP dependencies are installed
mcp-check:
	@echo "Checking MCP dependencies..."
	@if [ ! -d "$(VENV)" ]; then \
		echo "✗ Virtual environment not found. Run 'make mcp-venv' first."; \
		exit 1; \
	fi
	@$(PYTHON) -c "import mcp; import httpx; print('✓ MCP dependencies are installed')" 2>/dev/null || \
		(echo "✗ MCP dependencies are missing. Run 'make mcp-install' to install them." && exit 1)

# Test MCP server connection to OSRM
mcp-test:
	@echo "Testing MCP server connection to OSRM..."
	@BACKEND_PORT=$$(grep BACKEND_PORT .env 2>/dev/null | cut -d= -f2 || echo "5001"); \
	if ! curl -s http://localhost:$${BACKEND_PORT}/route/v1/driving/13.388860,52.517037;13.385983,52.496891 > /dev/null 2>&1; then \
		echo "✗ OSRM backend is not running on port $${BACKEND_PORT}. Start it with 'make start service=osrm-backend'"; \
		exit 1; \
	fi
	@echo "✓ OSRM backend is accessible"
	@if grep -q "OSRM_BASE_URL" mcp_server.py 2>/dev/null; then \
		echo "✓ MCP server configuration found"; \
	else \
		echo "✗ Could not find OSRM_BASE_URL in mcp_server.py"; \
		exit 1; \
	fi
	@echo "✓ MCP server test passed!"

# Validate MCP server configuration
mcp-validate:
	@echo "Validating MCP server configuration..."
	@if [ ! -f mcp_server.py ]; then \
		echo "✗ mcp_server.py not found"; \
		exit 1; \
	fi
	@if [ ! -f requirements.txt ]; then \
		echo "✗ requirements.txt not found"; \
		exit 1; \
	fi
	@if [ ! -f mcp_config.json ]; then \
		echo "⚠ mcp_config.json not found (optional)"; \
	else \
		echo "✓ mcp_config.json found"; \
	fi
	@if [ ! -d "$(VENV)" ]; then \
		echo "⚠ Virtual environment not found. Run 'make mcp-venv' first."; \
	else \
		$(PYTHON) -c "import ast; ast.parse(open('mcp_server.py').read()); print('✓ mcp_server.py syntax is valid')" 2>/dev/null || \
			(echo "✗ mcp_server.py has syntax errors" && exit 1); \
	fi
	@make mcp-check
	@echo "✓ MCP server configuration is valid!"

