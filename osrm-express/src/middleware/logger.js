const logfmt = require("logfmt");

function requestLogger(req, res, next) {
  const start = Date.now();
  
  // Log request start
  const logDataStart = {
    type: "request_start",
    method: req.method,
    url: req.originalUrl || req.url,
    ip: req.ip
  };
  console.log(logfmt.stringify(logDataStart));

  res.on("finish", () => {
    const elapsed = Date.now() - start;
    const duration = elapsed < 1000 ? `${elapsed}ms` : `${(elapsed / 1000).toFixed(2)}s`;
    
    // Log request completion
    const logDataEnd = {
      type: "request_end",
      method: req.method,
      url: req.originalUrl || req.url,
      status: res.statusCode,
      duration: duration,
      elapsed_ms: elapsed
    };
    console.log(logfmt.stringify(logDataEnd));
  });

  next();
}

module.exports = requestLogger;
