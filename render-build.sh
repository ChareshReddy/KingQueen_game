#!/usr/bin/env bash
set -e

echo "==> Installing Flutter SDK..."
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi
export PATH="$PATH:`pwd`/flutter/bin"

echo "==> Flutter version:"
flutter --version

echo "==> Enabling web support..."
flutter config --enable-web

echo "==> Fetching dependencies..."
flutter pub get

echo "==> Building web release..."
flutter build web --release

echo "==> Build complete."
