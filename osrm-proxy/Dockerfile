FROM ghcr.io/project-osrm/osrm-backend:latest

WORKDIR /usr/src/app

# Install Node.js (Alpine uses apk)
RUN apk add --no-cache nodejs npm

COPY package*.json ./

RUN npm install --omit=dev

COPY src ./src

ENV OSRM_GRAPH_BASENAME=berlin \
    OSRM_ALGORITHM=mld \
    OSRM_PORT=5000 \
    PROXY_PORT=5100

VOLUME ["/data"]

EXPOSE 5100

CMD ["npm", "start"]

