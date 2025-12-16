#!/usr/bin/env python3
"""
OSRM MCP Server
Exposes OSRM routing capabilities via Model Context Protocol
"""

import asyncio
import json
import sys
from typing import Any, Optional
import httpx
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# OSRM server configuration
OSRM_BASE_URL = "http://localhost:5001"

# Initialize MCP server
server = Server("osrm-server")

@server.list_tools()
async def list_tools() -> list[Tool]:
    """List available OSRM tools"""
    return [
        Tool(
            name="route",
            description="Calculate a route between two or more coordinates using OSRM",
            inputSchema={
                "type": "object",
                "properties": {
                    "coordinates": {
                        "type": "array",
                        "items": {
                            "type": "array",
                            "items": {"type": "number"},
                            "minItems": 2,
                            "maxItems": 2
                        },
                        "description": "Array of [longitude, latitude] coordinate pairs",
                        "minItems": 2
                    },
                    "profile": {
                        "type": "string",
                        "enum": ["driving", "walking", "cycling"],
                        "default": "driving",
                        "description": "Routing profile to use"
                    },
                    "alternatives": {
                        "type": "boolean",
                        "default": False,
                        "description": "Return alternative routes"
                    },
                    "steps": {
                        "type": "boolean",
                        "default": False,
                        "description": "Return step-by-step instructions"
                    },
                    "geometries": {
                        "type": "string",
                        "enum": ["polyline", "polyline6", "geojson"],
                        "default": "polyline",
                        "description": "Format of the returned geometry"
                    },
                    "overview": {
                        "type": "string",
                        "enum": ["simplified", "full", "false"],
                        "default": "simplified",
                        "description": "Add overview geometry"
                    }
                },
                "required": ["coordinates"]
            }
        ),
        Tool(
            name="nearest",
            description="Find the nearest point on the road network to a given coordinate",
            inputSchema={
                "type": "object",
                "properties": {
                    "longitude": {
                        "type": "number",
                        "description": "Longitude of the point"
                    },
                    "latitude": {
                        "type": "number",
                        "description": "Latitude of the point"
                    },
                    "profile": {
                        "type": "string",
                        "enum": ["driving", "walking", "cycling"],
                        "default": "driving",
                        "description": "Routing profile to use"
                    }
                },
                "required": ["longitude", "latitude"]
            }
        ),
        Tool(
            name="table",
            description="Calculate travel time and distance between multiple coordinates",
            inputSchema={
                "type": "object",
                "properties": {
                    "coordinates": {
                        "type": "array",
                        "items": {
                            "type": "array",
                            "items": {"type": "number"},
                            "minItems": 2,
                            "maxItems": 2
                        },
                        "description": "Array of [longitude, latitude] coordinate pairs"
                    },
                    "profile": {
                        "type": "string",
                        "enum": ["driving", "walking", "cycling"],
                        "default": "driving",
                        "description": "Routing profile to use"
                    },
                    "sources": {
                        "type": "array",
                        "items": {"type": "integer"},
                        "description": "Indices of source coordinates (default: all)"
                    },
                    "destinations": {
                        "type": "array",
                        "items": {"type": "integer"},
                        "description": "Indices of destination coordinates (default: all)"
                    }
                },
                "required": ["coordinates"]
            }
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    """Handle tool calls"""
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            if name == "route":
                return await handle_route(client, arguments)
            elif name == "nearest":
                return await handle_nearest(client, arguments)
            elif name == "table":
                return await handle_table(client, arguments)
            else:
                return [TextContent(
                    type="text",
                    text=f"Unknown tool: {name}"
                )]
        except Exception as e:
            return [TextContent(
                type="text",
                text=f"Error: {str(e)}"
            )]

async def handle_route(client: httpx.AsyncClient, args: dict[str, Any]) -> list[TextContent]:
    """Handle route calculation"""
    coordinates = args["coordinates"]
    profile = args.get("profile", "driving")
    
    # Format coordinates as "lon,lat;lon,lat;..."
    coord_string = ";".join([f"{coord[0]},{coord[1]}" for coord in coordinates])
    
    # Build query parameters
    params = {}
    if args.get("alternatives"):
        params["alternatives"] = "true"
    if args.get("steps"):
        params["steps"] = "true"
    if "geometries" in args:
        params["geometries"] = args["geometries"]
    if "overview" in args:
        params["overview"] = args["overview"]
    
    url = f"{OSRM_BASE_URL}/route/v1/{profile}/{coord_string}"
    response = await client.get(url, params=params)
    response.raise_for_status()
    
    result = response.json()
    return [TextContent(
        type="text",
        text=json.dumps(result, indent=2)
    )]

async def handle_nearest(client: httpx.AsyncClient, args: dict[str, Any]) -> list[TextContent]:
    """Handle nearest point lookup"""
    lon = args["longitude"]
    lat = args["latitude"]
    profile = args.get("profile", "driving")
    
    url = f"{OSRM_BASE_URL}/nearest/v1/{profile}/{lon},{lat}"
    response = await client.get(url)
    response.raise_for_status()
    
    result = response.json()
    return [TextContent(
        type="text",
        text=json.dumps(result, indent=2)
    )]

async def handle_table(client: httpx.AsyncClient, args: dict[str, Any]) -> list[TextContent]:
    """Handle distance table calculation"""
    coordinates = args["coordinates"]
    profile = args.get("profile", "driving")
    
    # Format coordinates as "lon,lat;lon,lat;..."
    coord_string = ";".join([f"{coord[0]},{coord[1]}" for coord in coordinates])
    
    params = {}
    if "sources" in args:
        params["sources"] = ";".join(map(str, args["sources"]))
    if "destinations" in args:
        params["destinations"] = ";".join(map(str, args["destinations"]))
    
    url = f"{OSRM_BASE_URL}/table/v1/{profile}/{coord_string}"
    response = await client.get(url, params=params)
    response.raise_for_status()
    
    result = response.json()
    return [TextContent(
        type="text",
        text=json.dumps(result, indent=2)
    )]

async def main():
    """Main entry point"""
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main())

