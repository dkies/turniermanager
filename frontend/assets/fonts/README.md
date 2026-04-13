# Schriftarten für deutsche Sonderzeichen (ß, ä, ö, ü)

Damit ß und Umlaute in der Web-App korrekt angezeigt werden, wird eine Schrift mit Latin-Extended-Unterstützung benötigt.

**So richten Sie die Schrift ein:**

1. Gehen Sie zu https://fonts.google.com/noto/specimen/Noto+Sans
2. Klicken Sie auf "Download family"
3. Entpacken Sie die ZIP-Datei
4. Kopieren Sie die Datei `NotoSans-Regular.ttf` in diesen Ordner (`assets/fonts/`)
5. Ohne `NotoSans-Regular.ttf` bricht der Build ab – die Datei ist Pflicht.

Die App verwendet dann automatisch diese Schrift; alle deutschen Sonderzeichen (ß, ä, ö, ü) werden korrekt dargestellt – auch offline.
