const app = require("./app");
const { startOsrm } = require("./lib/osrm-runner");

const PORT = process.env.EXPRESS_PORT || 5200;

// Start the OSRM backend process first
startOsrm();

app.listen(PORT, () => {
  console.log(`[server] osrm-express listening on port ${PORT}`);
});
