#!/bin/bash
set -e

# Lê versão do pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
TAG="v$VERSION"
APK="build/app/outputs/flutter-apk/app-release.apk"

echo "==> Buildando versão $VERSION..."
flutter build apk --release --dart-define=BASE_URL=http://147.15.59.213

echo ""
echo "==> Criando release $TAG no GitHub..."
gh release create "$TAG" "$APK" \
  --repo queirozsnr/gama \
  --title "GAMA $TAG" \
  --notes "Release $TAG"

echo ""
echo "✓ Release $TAG publicada com sucesso!"
echo "  APK disponível em: https://github.com/queirozsnr/gama/releases/tag/$TAG"
