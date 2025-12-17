# OSRM Local Stack

This project sets up a local Open Source Routing Machine (OSRM) stack with both backend and frontend services using Docker Compose.

## Prerequisites

- Docker and Docker Compose installed
- Berlin OSM data file (`berlin.pbf`) in the `../_data` folder (relative to this directory)

## Quick Start

### 1. Pre-process the OSM Data

Before starting the services, you need to pre-process the OSM data file. This is a one-time step that extracts, partitions, and customizes the routing graph.

**Using Makefile (recommended):**

```bash
cd osrm
make extract
```

**Note:** The extraction process can take several minutes depending on the size of the OSM file. The processed data (`.osrm.*` files) will be stored in a Docker/Podman volume named `osrm_osrm-data` (or `<COMPOSE_PROJECT_NAME>_osrm-data`). The source PBF file is read from `../_data/berlin.pbf` and copied into the volume for processing.

### 2. Start the Services

Once preprocessing is complete, start the stack from this directory:

**Using Makefile (recommended):**

```bash
cd osrm
make start-all
# Or start individual services:
make start service=osrm-backend
make start service=osrm-frontend
```

**Or using docker-compose/podman-compose directly:**

```bash
cd osrm
docker-compose up -d
# or with podman:
podman compose up -d
```

This will start:
- **OSRM Backend** on port `5001` (configurable via `BACKEND_PORT` in `.env`) - Standard C++ HTTP server
- **OSRM Frontend** on port `9966` (configurable via `FRONTEND_PORT` in `.env`) - Map UI
- **OSRM Native** on port `5300` (configurable via `.env`) - **High-performance Node.js service** using direct C++ bindings
- **Node Proxy** on port `5100` (configurable via `PROXY_PORT` in `.env`) - Proxy service for testing

### 3. Access the Services

- **Frontend UI**: Open [http://localhost:9966](http://localhost:9966) in your browser
- **Native API**: Available at [http://localhost:5300](http://localhost:5300) (High Performance)
- **Backend API**: Available at [http://localhost:5001](http://localhost:5001)
- **Proxy API**: Available at [http://localhost:5100](http://localhost:5100)

### 4. Test the Backend API

Test the routing API with a sample request:

```bash
curl "http://localhost:5001/route/v1/driving/13.388860,52.517037;13.385983,52.496891?steps=true"
```

**Note:** The default port is 5001 to avoid conflicts with macOS AirPlay Receiver (which uses port 5000). You can change it in the `.env` file.

## Configuration

All configuration variables are defined in the `.env` file in this directory:

- `BACKEND_PORT`: Port for the OSRM backend service (default: 5001, changed from 5000 to avoid macOS AirPlay Receiver conflict)
- `FRONTEND_PORT`: Port for the OSRM frontend service (default: 9966)
- `ALGORITHM`: Routing algorithm to use - `mld` (Multi-Level Dijkstra) or `ch` (Contraction Hierarchies) (default: mld)
- `OSM_FILE`: Base name of the OSM file without extension (default: berlin)
- `OSRM_SERVER_URL`: Backend URL used by the frontend (default: http://osrm-backend:5000)
- `PROFILE`: Routing profile to use (default: car)
- `CONTAINER_RUNTIME`: Container runtime to use - `docker` or `podman` (default: docker)
- `PROXY_PORT`: Port for the Node.js proxy service (default: 5100)

### Proxy Service Details

The `osrm-proxy` service lives in `osrm/osrm-proxy` and:
- Mounts the same `osrm-data` volume as the backend so the extracted graph is available at `/data/<OSM_FILE>.osrm`
- Starts `osrm-routed` inside the container using `ALGORITHM`/`OSM_FILE`
- Exposes an Express proxy on `PROXY_PORT` that forwards all API calls to the local `osrm-routed`

Example request against the proxy:

```bash
curl "http://localhost:${PROXY_PORT:-5100}/route/v1/driving/13.388860,52.517037;13.385983,52.496891?steps=true"
```

## Using Podman

The stack supports both Docker and Podman. To use Podman:

1. **Set in `.env` file:**
   ```bash
   CONTAINER_RUNTIME=podman
   ```

2. **Or override on the command line:**
   ```bash
   make start-all CONTAINER_RUNTIME=podman
   ```

**Note:** Podman uses `podman compose` (as a subcommand) or `podman-compose` (standalone). The Makefile will automatically detect which is available.

## Using Different Profiles

To use a different routing profile (e.g., `foot`, `bike`), you'll need to modify the extraction process. Currently, the Makefile uses the `car` profile by default. To use a different profile:

1. **Modify the Makefile** `extract` target to use a different profile:
   - Change `/opt/car.lua` to `/opt/foot.lua` or `/opt/bike.lua`

2. **Or run manually** (replace `docker` with `podman` if using Podman):
   ```bash
   # Ensure volume exists
   docker volume create osrm_osrm-data
   
   # Copy source file
   docker run --rm -v osrm_osrm-data:/data -v "$(pwd)/../_data:/source:ro" alpine sh -c "cp /source/berlin.pbf /data/berlin.pbf"
   
   # Extract with foot profile
   docker run --rm -v osrm_osrm-data:/data ghcr.io/project-osrm/osrm-backend osrm-extract -p /opt/foot.lua /data/berlin.pbf
   docker run --rm -v osrm_osrm-data:/data ghcr.io/project-osrm/osrm-backend osrm-partition /data/berlin.osrm
   docker run --rm -v osrm_osrm-data:/data ghcr.io/project-osrm/osrm-backend osrm-customize /data/berlin.osrm
   ```

Then update the `.env` file to set `PROFILE=foot` or `PROFILE=bike` accordingly.

## Using Contraction Hierarchies (CH) Algorithm

If you prefer to use the CH algorithm instead of MLD:

1. **Modify the Makefile** `extract` target to replace partition/customize with contract:
   - Remove the `osrm-partition` and `osrm-customize` lines
   - Add: `docker run --rm -v $(VOLUME_NAME):/data ghcr.io/project-osrm/osrm-backend osrm-contract /data/berlin.osrm`

2. **Or run manually** (replace `docker` with `podman` if using Podman):
   ```bash
   # Ensure volume exists and has the extracted data
   docker run --rm -v osrm_osrm-data:/data ghcr.io/project-osrm/osrm-backend osrm-contract /data/berlin.osrm
   ```

3. Update `.env` to set `ALGORITHM=ch`

## Managing the Stack

### Using Makefile (Recommended)

The Makefile provides convenient commands for managing the stack:

```bash
# Show all available commands
make help

# Start all services
make start-all

# Start a specific service
make start service=osrm-backend
make start service=osrm-frontend

# Stop all services
make stop-all

# Stop a specific service
make stop service=osrm-backend
make stop service=osrm-frontend

# Restart a specific service
make restart service=osrm-backend

# View logs for a service
make logs service=osrm-backend

# Check status of all services
make status

# Clean up (stop and remove containers)
make clean

# Destroy Stack (Remove containers AND Data Volume)
make destroy

# Package Data (Create tarball of processed graph)
make package

# Volume management
make volume-ls              # List OSRM volumes
make volume-rm              # Remove OSRM data volume (WARNING: deletes processed data)
```

### Using Docker Compose / Podman Compose Directly

```bash
# Stop all services
docker-compose down
# or with podman:
podman compose down

# View logs
docker-compose logs -f
# or with podman:
podman compose logs -f

# Restart services
docker-compose restart
# or with podman:
podman compose restart
```

## Troubleshooting

### Preprocessing fails
- Ensure the `berlin.pbf` file exists in the `../_data` directory
- Check that you have enough disk space (preprocessing can generate files several times larger than the original OSM file)
- Verify the volume was created: `make volume-ls` or `docker volume ls | grep osrm`

### Services won't start
- Verify that preprocessing completed successfully: `make volume-ls` should show the `osrm_osrm-data` volume
- Check the logs: `make logs service=osrm-backend`
- Ensure the ports specified in `.env` are not already in use
- Verify the volume exists and contains data: `docker volume inspect osrm_osrm-data` (or `podman volume inspect osrm_osrm-data`)

### Frontend can't connect to backend
- Verify both services are running: `docker-compose ps`
- Check that `OSRM_SERVER_URL` in `.env` matches the backend service name and port

## Native Service Details (`osrm-native`)

The `osrm-native` service is the recommended way to interact with the routing engine for custom applications.
- **Architecture**: uses the `@project-osrm/osrm` npm package to load the C++ routing engine directly into the Node.js process.
- **Performance**: Eliminates HTTP overhead between Node.js and the database engine.
- **Image Size**: Optimized multi-stage Docker build (~200MB).
- **CORS**: Enabled by default (`*`), configurable via `CORS_ORIGIN`.
- **Apple Silicon**: Runs under `linux/amd64` emulation with optimized glibc/libtbb dependencies.

## References

- [OSRM Backend GitHub](https://github.com/Project-OSRM/osrm-backend)
- [OSRM Frontend Docker Hub](https://hub.docker.com/r/osrm/osrm-frontend/)
- [OSRM API Documentation](http://project-osrm.org/docs/v5.24.0/api/)

