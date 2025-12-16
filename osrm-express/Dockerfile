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
    EXPRESS_PORT=5200

VOLUME ["/data"]

EXPOSE 5200

CMD ["npm", "start"]
