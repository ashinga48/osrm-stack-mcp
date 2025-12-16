# OS Requirement: The pre-built binary uses GLIBC 2.38+ and libtbb.so.12. 
# Ubuntu 24.04 provides these.
FROM --platform=linux/amd64 ubuntu:24.04

WORKDIR /usr/src/app

# Install dependencies and Node.js
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && mkdir -p /etc/apt/keyrings \
    && apt-get update && apt-get install -y \
    nodejs \
    npm \
    python3 \
    make \
    g++ \
    cmake \
    libboost-all-dev \
    liblua5.3-dev \
    libtbb-dev \
    libexpat1-dev \
    libbz2-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy only package.json first to cache dependencies
COPY package.json ./

# Install dependencies (including @project-osrm/osrm)
# This will attempt to download the pre-built binary.
# Since we are forcing amd64 platform in compose, it should find the x64 binary.
RUN npm install \
    && ln -s /usr/src/app/node_modules/@project-osrm/osrm/lib/binding_napi_v8 /usr/src/app/node_modules/@project-osrm/osrm/lib/binding \
    && touch /built_check_v2

COPY src ./src

ENV OSRM_GRAPH_BASENAME=berlin \
    OSRM_ALGORITHM=mld \
    OSRM_PORT=5300 \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu

VOLUME ["/data"]

EXPOSE 5300

CMD ["node", "src/run.js"]
