// metro.config.js: Expo's defaults, plus one: SQLite's web build is a .wasm file, which Metro must
// treat as an asset to copy rather than as code to read.
const { getDefaultConfig } = require("expo/metro-config");

const config = getDefaultConfig(__dirname);
config.resolver.assetExts.push("wasm");
module.exports = config;
