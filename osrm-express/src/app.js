const express = require("express");
const { createProxyMiddleware } = require("http-proxy-middleware");
const requestLogger = require("./middleware/logger");
const { OSRM_PORT } = require("./lib/osrm-runner");

const app = express();

// Middleware
app.use(requestLogger);

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok", service: "osrm-express" });
});

// Proxy routes to OSRM backend
app.use(
  "/route",
  createProxyMiddleware({
    target: `http://127.0.0.1:${OSRM_PORT}`,
    changeOrigin: false,
    pathRewrite: {
      "^/route": "/route" // run.js uses /route/v1/... so we keep it or adjust as needed. 
                          // OSRM usually expects /route/v1/profile/coords
                          // If user hits /route/v1/driving/..., it maps directly.
    },
    onProxyReq: (proxyReq, req, res) => {
        // Optional: Log proxying
    }
  })
);

// Catch-all proxy for other OSRM endpoints (nearest, table, match, trip, tile)
app.use(
  "/",
  createProxyMiddleware({
    target: `http://127.0.0.1:${OSRM_PORT}`,
    changeOrigin: false,
    logLevel: "warn"
  })
);

module.exports = app;
