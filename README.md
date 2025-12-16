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

**Or manually (replace docker with podman if using Podman):**

```bash
# From the osrm directory
docker run -t -v "$(pwd)/../_data:/data" ghcr.io/project-osrm/osrm-backend osrm-extract -p /opt/car.lua /data/berlin.pbf
docker run -t -v "$(pwd)/../_data:/data" ghcr.io/project-osrm/osrm-backend osrm-partition /data/berlin.osrm
docker run -t -v "$(pwd)/../_data:/data" ghcr.io/project-osrm/osrm-backend osrm-customize /data/berlin.osrm
```

**Note:** The extraction process can take several minutes depending on the size of the OSM file. The process will generate several `.osrm.*` files in the `_data` directory.

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
- **OSRM Backend** on port `5000` (configurable via `.env`)
- **OSRM Frontend** on port `9966` (configurable via `.env`)

### 3. Access the Services

- **Frontend UI**: Open [http://localhost:9966](http://localhost:9966) in your browser
- **Backend API**: Available at [http://localhost:5000](http://localhost:5000)

### 4. Test the Backend API

Test the routing API with a sample request:

```bash
curl "http://localhost:5000/route/v1/driving/13.388860,52.517037;13.385983,52.496891?steps=true"
```

## Configuration

All configuration variables are defined in the `.env` file in this directory:

- `BACKEND_PORT`: Port for the OSRM backend service (default: 5000)
- `FRONTEND_PORT`: Port for the OSRM frontend service (default: 9966)
- `ALGORITHM`: Routing algorithm to use - `mld` (Multi-Level Dijkstra) or `ch` (Contraction Hierarchies) (default: mld)
- `OSM_FILE`: Base name of the OSM file without extension (default: berlin)
- `OSRM_SERVER_URL`: Backend URL used by the frontend (default: http://osrm-backend:5000)
- `PROFILE`: Routing profile to use (default: car)
- `CONTAINER_RUNTIME`: Container runtime to use - `docker` or `podman` (default: docker)

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

To use a different routing profile (e.g., `foot`, `bike`), modify the extraction command (run from project root):

```bash
# For foot profile
docker run -t -v "${PWD}/_data:/data" ghcr.io/project-osrm/osrm-backend osrm-extract -p /opt/foot.lua /data/berlin.pbf

# For bike profile
docker run -t -v "${PWD}/_data:/data" ghcr.io/project-osrm/osrm-backend osrm-extract -p /opt/bike.lua /data/berlin.pbf
```

Then update the `.env` file to set `PROFILE=foot` or `PROFILE=bike` accordingly.

## Using Contraction Hierarchies (CH) Algorithm

If you prefer to use the CH algorithm instead of MLD:

1. Replace the partition and customize steps with a single contract step (run from project root):

```bash
docker run -t -v "${PWD}/_data:/data" ghcr.io/project-osrm/osrm-backend osrm-contract /data/berlin.osrm
```

2. Update `.env` to set `ALGORITHM=ch`

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

### Services won't start
- Verify that preprocessing completed successfully and `.osrm.*` files exist in `../_data`
- Check the logs: `docker-compose logs osrm-backend`
- Ensure the ports specified in `.env` are not already in use

### Frontend can't connect to backend
- Verify both services are running: `docker-compose ps`
- Check that `OSRM_SERVER_URL` in `.env` matches the backend service name and port

## References

- [OSRM Backend GitHub](https://github.com/Project-OSRM/osrm-backend)
- [OSRM Frontend Docker Hub](https://hub.docker.com/r/osrm/osrm-frontend/)
- [OSRM API Documentation](http://project-osrm.org/docs/v5.24.0/api/)

