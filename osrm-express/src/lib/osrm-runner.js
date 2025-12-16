const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const {
  OSRM_GRAPH_BASENAME = "berlin",
  OSRM_ALGORITHM = "mld",
  OSRM_PORT = 5000
} = process.env;

const dataDir = "/data";
const graphPath = path.join(dataDir, `${OSRM_GRAPH_BASENAME}.osrm`);
let osrmProcess = null;

function startOsrm() {
  if (osrmProcess) return; // Already running

  // Robust check for graph files
  if (!fs.existsSync(graphPath)) {
    const mldExists = fs.existsSync(path.join(dataDir, `${OSRM_GRAPH_BASENAME}.osrm.partition`));
    const chExists = fs.existsSync(path.join(dataDir, `${OSRM_GRAPH_BASENAME}.osrm.hsgr`));
    
    if (mldExists || chExists) {
      console.log(`[osrm-runner] Base graph file ${graphPath} missing, but found algorithm-specific files. Proceeding.`);
    } else {
      console.error(`[osrm-runner] Missing graph file: ${graphPath} (and no MLD/CH files found)`);
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

  console.log(`[osrm-runner] launching osrm-routed with ${graphPath} using ${OSRM_ALGORITHM}`);
  
  osrmProcess = spawn("osrm-routed", osrmArgs, { stdio: "inherit" });

  osrmProcess.on("exit", (code, signal) => {
    console.error(`[osrm-runner] osrm-routed exited with code=${code} signal=${signal}`);
    process.exit(code || 1);
  });
}

function stopOsrm() {
  if (osrmProcess) {
    osrmProcess.kill();
    osrmProcess = null;
  }
}

// Handle cleanup
process.on("SIGINT", () => {
  stopOsrm();
  process.exit(0);
});

process.on("SIGTERM", () => {
  stopOsrm();
  process.exit(0);
});

module.exports = {
  startOsrm,
  OSRM_PORT
};
