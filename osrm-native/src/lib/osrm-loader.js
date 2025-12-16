const OSRM = require("@project-osrm/osrm");
// const OSRM = require("./osrm-lib");
const path = require("path");
const fs = require("fs");

const {
  OSRM_GRAPH_BASENAME = "berlin",
  OSRM_ALGORITHM = "MLD" // Default to MLD
} = process.env;

const dataDir = "/data";
const graphPath = path.join(dataDir, `${OSRM_GRAPH_BASENAME}.osrm`);

function loadOsrm() {
  console.log(`[osrm-native] Loading graph from ${graphPath} with algorithm ${OSRM_ALGORITHM}`);
  
  if (!fs.existsSync(graphPath)) {
    // Note: node-osrm might be stricter than osrm-routed about files.
    // If the main .osrm file is missing, we try to point it to the file anyway 
    // and see if the binding handles it or throws.
    console.warn(`[osrm-native] Warning: Base graph file ${graphPath} not found.`);
  }

  try {
    const osrm = new OSRM({
      path: graphPath,
      algorithm: OSRM_ALGORITHM.toUpperCase()
    });
    console.log("[osrm-native] OSRM instance created successfully");
    return osrm;
  } catch (err) {
    console.error("[osrm-native] Failed to initialize OSRM:", err);
    process.exit(1);
  }
}

module.exports = loadOsrm();
