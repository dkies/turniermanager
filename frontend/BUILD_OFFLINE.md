# Offline-Build Anleitung

## Service Worker deaktivieren

Um die App ohne Service Worker zu bauen (für Offline-Betrieb ohne PWA-Caching), verwenden Sie den Build-Befehl mit der Option `--pwa-strategy=none`:

```bash
flutter build web --release --pwa-strategy=none
```

## Warum Service Worker deaktivieren?

Der Service Worker wird standardmäßig von Flutter Web generiert und cached App-Ressourcen für Offline-Funktionalität. In manchen Fällen kann dies zu Problemen führen:

- **Caching-Probleme**: Alte Versionen der App werden möglicherweise gecacht
- **Offline-Konflikte**: Der Service Worker kann versuchen, externe Ressourcen zu laden
- **Einfachere Deployment**: Ohne Service Worker ist das Deployment einfacher

## Wichtige Hinweise

1. **Alle Ressourcen müssen lokal sein**: Stellen Sie sicher, dass keine externen Ressourcen (CDN, Google Fonts, etc.) verwendet werden
2. **Backend-Verbindung**: Die App benötigt weiterhin eine Verbindung zum Backend für API-Calls
3. **Lokale Dateien**: Alle Assets (Bilder, Sounds, etc.) müssen im `build/web` Verzeichnis enthalten sein

## Docker Build

Der Dockerfile wurde bereits angepasst und verwendet `--pwa-strategy=none` automatisch.
