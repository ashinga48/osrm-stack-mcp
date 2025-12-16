// var OSRM = module.exports = require("@project-osrm/osrm/lib/binding_napi_v8/node_osrm.node").OSRM;
// OSRM.version = require("@project-osrm/osrm/package.json").version;

var OSRM = module.exports = require('./binding/node_osrm.node').OSRM;
OSRM.version = require('../package.json').version;
