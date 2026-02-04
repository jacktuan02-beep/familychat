#!/usr/bin/env bash
set -e

echo "==> Fixing Expo web deps + tunnel deps..."

# Ensure required Expo web deps exist
npx expo install react-native-web react-dom @expo/metro-runtime expo-asset expo-constants expo-file-system expo-font

# Optional: tunnel support (ngrok). Avoid global installs.
npm i -D @expo/ngrok@^4.1.0 || true

echo "==> Starting Expo (clear cache)..."
npx expo start -c
