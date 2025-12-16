const express = require("express");
const logfmt = require("logfmt");
const osrm = require("./lib/osrm-loader");

const app = express();

// Logging Middleware
app.use((req, res, next) => {
  const start = Date.now();
  console.log(logfmt.stringify({ type: "request_start", method: req.method, url: req.originalUrl }));

  res.on("finish", () => {
    const elapsed = Date.now() - start;
    console.log(logfmt.stringify({
      type: "request_end",
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      duration: `${elapsed}ms`
    }));
  });
  next();
});

app.get("/health", (req, res) => {
  res.json({ status: "ok", service: "osrm-native" });
});

// Route handler using native binding
app.get("/route/v1/:profile/:coordinates", (req, res) => {
  const { coordinates } = req.params;
  const options = {
    coordinates: coordinates.split(';').map(c => c.split(',').map(Number)),
    profile: req.params.profile,
    overview: req.query.overview || 'simplified',
    geometries: req.query.geometries || 'polyline',
    steps: req.query.steps === 'true'
  };

  osrm.route(options, (err, result) => {
    if (err) {
      console.error("[osrm-native] Route error:", err);
      return res.status(500).json({ code: "InternalError", message: err.message });
    }
    return res.json(result);
  });
});

module.exports = app;
