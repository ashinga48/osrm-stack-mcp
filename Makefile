.PHONY: help extract start stop start-all stop-all restart logs status clean mcp-venv mcp-install mcp-test mcp-check mcp-validate

# Load environment variables from .env file
include .env
export

# Default target
help:
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
	@echo ""
	@echo "MCP Server Commands:"
	@echo "  make mcp-venv                  - Create Python virtual environment"
	@echo "  make mcp-install               - Install MCP server dependencies in venv"
	@echo "  make mcp-check                 - Check if MCP dependencies are installed"
	@echo "  make mcp-test                  - Test MCP server connection to OSRM"
	@echo "  make mcp-validate              - Validate MCP server configuration"

# Pre-process OSM data
extract:
	@echo "Extracting OSM data..."
	@docker run -t -v "$$(pwd)/../_data:/data" ghcr.io/project-osrm/osrm-backend osrm-extract -p /opt/car.lua /data/berlin.pbf
	@echo "Partitioning graph (MLD algorithm)..."
	@docker run -t -v "$$(pwd)/../_data:/data" ghcr.io/project-osrm/osrm-backend osrm-partition /data/berlin.osrm
	@echo "Customizing graph (MLD algorithm)..."
	@docker run -t -v "$$(pwd)/../_data:/data" ghcr.io/project-osrm/osrm-backend osrm-customize /data/berlin.osrm
	@echo "Pre-processing complete!"

# Start a specific service
start:
	@if [ -z "$(service)" ]; then \
		echo "Error: Please specify a service name (osrm-backend or osrm-frontend)"; \
		echo "Usage: make start service=osrm-backend"; \
		exit 1; \
	fi
	@docker-compose up -d $(service)
	@echo "Started $(service)"

# Stop a specific service
stop:
	@if [ -z "$(service)" ]; then \
		echo "Error: Please specify a service name (osrm-backend or osrm-frontend)"; \
		echo "Usage: make stop service=osrm-backend"; \
		exit 1; \
	fi
	@docker-compose stop $(service)
	@echo "Stopped $(service)"

# Start all services
start-all:
	@docker-compose up -d
	@echo "Started all services"

# Stop all services
stop-all:
	@docker-compose down
	@echo "Stopped all services"

# Restart a specific service
restart:
	@if [ -z "$(service)" ]; then \
		echo "Error: Please specify a service name (osrm-backend or osrm-frontend)"; \
		echo "Usage: make restart service=osrm-backend"; \
		exit 1; \
	fi
	@docker-compose restart $(service)
	@echo "Restarted $(service)"

# View logs for a specific service
logs:
	@if [ -z "$(service)" ]; then \
		echo "Error: Please specify a service name (osrm-backend or osrm-frontend)"; \
		echo "Usage: make logs service=osrm-backend"; \
		exit 1; \
	fi
	@docker-compose logs -f $(service)

# Show status of all services
status:
	@docker-compose ps

# Clean up - stop and remove all containers
clean:
	@docker-compose down
	@echo "Cleaned up all containers"

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
	@if ! curl -s http://localhost:5000/route/v1/driving/13.388860,52.517037;13.385983,52.496891 > /dev/null 2>&1; then \
		echo "✗ OSRM backend is not running. Start it with 'make start service=osrm-backend'"; \
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

