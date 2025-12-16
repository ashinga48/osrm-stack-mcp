# OSRM MCP Server

This directory contains an MCP (Model Context Protocol) server that exposes OSRM routing capabilities to AI assistants like Claude Desktop.

## Setup

### 1. Create Virtual Environment and Install Dependencies

**Using Makefile (recommended):**

```bash
cd osrm
make mcp-venv      # Create virtual environment
make mcp-install   # Install dependencies
```

**Or manually:**

```bash
cd osrm
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Make the Server Executable

```bash
chmod +x mcp_server.py
```

### 3. Configure Claude Desktop (or other MCP client)

The MCP server can be configured in your Claude Desktop configuration file:

**macOS:**
```
~/Library/Application Support/Anthropic/Claude/claude_desktop_config.json
```

**Windows:**
```
%APPDATA%\Anthropic\Claude\claude_desktop_config.json
```

Add the following configuration (adjust the paths to match your system):

```json
{
  "mcpServers": {
    "osrm": {
      "command": "/absolute/path/to/nbn/osrm/venv/bin/python",
      "args": [
        "/absolute/path/to/nbn/osrm/mcp_server.py"
      ],
      "env": {
        "OSRM_BASE_URL": "http://localhost:5000"
      }
    }
  }
}
```

**Note:** 
- Use the absolute path to the virtual environment's Python interpreter in the `command` field
- Use the absolute path to `mcp_server.py` in the `args` array
- Example: If your project is at `/Users/ravi/Desktop/nbn`, use `/Users/ravi/Desktop/nbn/osrm/venv/bin/python`

### 4. Start OSRM Backend

Before using the MCP server, ensure the OSRM backend is running:

```bash
make start service=osrm-backend
# or
make start-all
```

## Available Tools

The MCP server exposes three tools:

### 1. `route`
Calculate a route between two or more coordinates.

**Parameters:**
- `coordinates` (required): Array of [longitude, latitude] pairs
- `profile` (optional): "driving", "walking", or "cycling" (default: "driving")
- `alternatives` (optional): Return alternative routes (default: false)
- `steps` (optional): Return step-by-step instructions (default: false)
- `geometries` (optional): "polyline", "polyline6", or "geojson" (default: "polyline")
- `overview` (optional): "simplified", "full", or "false" (default: "simplified")

### 2. `nearest`
Find the nearest point on the road network to a given coordinate.

**Parameters:**
- `longitude` (required): Longitude of the point
- `latitude` (required): Latitude of the point
- `profile` (optional): "driving", "walking", or "cycling" (default: "driving")

### 3. `table`
Calculate travel time and distance between multiple coordinates.

**Parameters:**
- `coordinates` (required): Array of [longitude, latitude] pairs
- `profile` (optional): "driving", "walking", or "cycling" (default: "driving")
- `sources` (optional): Indices of source coordinates (default: all)
- `destinations` (optional): Indices of destination coordinates (default: all)

## Testing

You can test the MCP server directly using the MCP SDK or by configuring it in Claude Desktop and asking routing questions.

## Troubleshooting

1. **Server not connecting**: Ensure the OSRM backend is running on port 5000
2. **Python not found**: Make sure the virtual environment exists and the path in the config is correct
3. **Module not found**: Run `make mcp-install` to install dependencies in the virtual environment
4. **Path issues**: Use absolute paths in the MCP configuration file
5. **Virtual environment not found**: Run `make mcp-venv` to create the virtual environment

## Configuration

You can customize the OSRM server URL by setting the `OSRM_BASE_URL` environment variable in the MCP configuration.

