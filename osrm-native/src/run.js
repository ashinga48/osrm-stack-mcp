const app = require("./app");
const PORT = process.env.OSRM_PORT || 5300;

app.listen(PORT, () => {
  console.log(`[server] osrm-native listening on port ${PORT}`);
});
