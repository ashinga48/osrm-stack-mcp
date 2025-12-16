const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const express = require("express");
const { createProxyMiddleware } = require("http-proxy-middleware");
const morgan = require("morgan");
require("dotenv").config();

const {
  OSRM_GRAPH_BASENAME = "berlin",
  OSRM_ALGORITHM = "mld",
  OSRM_PORT = 5000,
  PROXY_PORT = 5100
} = process.env;

const dataDir = "/data";
const graphPath = path.join(dataDir, `${OSRM_GRAPH_BASENAME}.osrm`);

// Check for base graph file or algorithm-specific files
if (!fs.existsSync(graphPath)) {
  const mldExists = fs.existsSync(path.join(dataDir, `${OSRM_GRAPH_BASENAME}.osrm.partition`));
  const chExists = fs.existsSync(path.join(dataDir, `${OSRM_GRAPH_BASENAME}.osrm.hsgr`));
  
  if (mldExists || chExists) {
    console.log(`[startup] Base graph file ${graphPath} missing, but found algorithm-specific files. Proceeding.`);
  } else {
    console.error(`[startup] Missing graph file: ${graphPath} (and no MLD/CH files found)`);
    process.exit(1);
  }
}

const osrmArgs = [
  "--algorithm",
  OSRM_ALGORITHM,
  "--port",
  `${OSRM_PORT}`,
  graphPath
];

console.log(`[startup] launching osrm-routed with ${graphPath} using ${OSRM_ALGORITHM}`);
const osrmProcess = spawn("osrm-routed", osrmArgs, { stdio: "inherit" });

osrmProcess.on("exit", (code, signal) => {
  console.error(`[osrm] exited with code=${code} signal=${signal}`);
  process.exit(code || 1);
});

process.on("SIGINT", () => {
  osrmProcess.kill("SIGINT");
  process.exit(0);
});

process.on("SIGTERM", () => {
  osrmProcess.kill("SIGTERM");
  process.exit(0);
});

const app = express();

app.use((req, res, next) => {
  const start = Date.now();
  console.log(`[request] ${req.method} ${req.url} - Started`);

  res.on("finish", () => {
    const elapsed = Date.now() - start;
    const duration = elapsed < 1000 ? `${elapsed}ms` : `${(elapsed / 1000).toFixed(2)}s`;
    console.log(`[request] ${req.method} ${req.originalUrl || req.url} - Completed ${res.statusCode} in ${duration}`);
  });

  next();
});

app.use(morgan("combined"));

app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    osrm: {
      running: osrmProcess.exitCode === null,
      algorithm: OSRM_ALGORITHM,
      graph: graphPath
    }
  });
});

app.use(
  "/",
  createProxyMiddleware({
    target: `http://127.0.0.1:${OSRM_PORT}`,
    changeOrigin: false,
    logLevel: "warn"
  })
);

app.listen(PROXY_PORT, () => {
  console.log(`[proxy] listening on :${PROXY_PORT}, forwarding to osrm-routed on :${OSRM_PORT}`);
});

