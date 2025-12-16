# Stage 1: Builder
# Uses Ubuntu 24.04 to match the glibc requirements of the pre-built OSRM binary
FROM --platform=linux/amd64 ubuntu:24.04 AS builder

WORKDIR /usr/src/app

# Install build tools needed for npm install (just npm and nodeenv)
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Copy package.json and install dependencies
COPY package.json ./

# Install npm dependencies (downloads pre-built OSRM binary)
# AND apply the critical symlink fix for the binary path
RUN npm install \
    && ln -s /usr/src/app/node_modules/@project-osrm/osrm/lib/binding_napi_v8 /usr/src/app/node_modules/@project-osrm/osrm/lib/binding \
    && touch /built_check_v3

# Stage 2: Runtime
# Starts fresh with a minimal layer
FROM --platform=linux/amd64 ubuntu:24.04

WORKDIR /usr/src/app

# Install ONLY runtime dependencies
# - nodejs: to run the app
# - libtbb12: required by osrm binary
# - libbz2-1.0: required by osrm binary
RUN apt-get update && apt-get install -y \
    nodejs \
    libtbb12 \
    libbz2-1.0 \
    && rm -rf /var/lib/apt/lists/*

# Copy built node_modules from builder stage
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package.json ./

# Copy application source code
COPY src ./src

# Setup environment
ENV OSRM_GRAPH_BASENAME=berlin \
    OSRM_ALGORITHM=mld \
    OSRM_PORT=5300 \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu

VOLUME ["/data"]

EXPOSE 5300

CMD ["node", "src/run.js"]
