#!/usr/bin/env bash
# Downloads the MediaPipe face tracker (wasm runtime + model) into ./vendor/mediapipe
# so the installation runs without internet. Then open index.html?local
# (three.js and Spark still come from their CDN — vendor them too for a fully
# offline machine, see TRACKING.md).
set -euo pipefail
cd "$(dirname "$0")/.."
VER=1.0.1
DST=vendor/mediapipe
mkdir -p "$DST/wasm"
TMP=$(mktemp -d)
curl -fsSL "https://registry.npmjs.org/@mediapipe/tasks-vision/-/tasks-vision-$VER.tgz" | tar xz -C "$TMP"
cp "$TMP/package/vision_bundle.mjs" "$DST/"
cp "$TMP"/package/wasm/* "$DST/wasm/"
curl -fsSL -o "$DST/face_landmarker.task" \
  "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"
rm -rf "$TMP"
echo "OK — $DST ready. Serve the folder and open index.html?local"
