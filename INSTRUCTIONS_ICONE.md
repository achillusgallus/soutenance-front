# Instructions pour générer l'icône TogoSchool

## Option 1 : Utiliser un générateur en ligne (Recommandé)

### Étape 1 : Créer l'icône
Utilisez un de ces sites gratuits :
- **Canva** (https://www.canva.com) - Créer un design carré 1024x1024px
- **Figma** (https://www.figma.com) - Gratuit pour usage personnel
- **Adobe Express** (https://www.adobe.com/express) - Générateur d'icônes

### Étape 2 : Design suggéré
Créez une icône avec :
- **Symbole** : Un livre ouvert avec une graduation cap OU un "T" stylisé
- **Couleurs** : Inspirées du drapeau du Togo
  - Vert : #006A4E
  - Jaune/Or : #FFCE00
  - Rouge : #D21034
- **Style** : Moderne, flat design, minimaliste
- **Format** : Carré avec coins arrondis (20% de rayon)

### Étape 3 : Exporter
- Exportez en **PNG** à 1024x1024px
- Nommez le fichier `app_icon.png`

## Option 2 : Utiliser un service de génération d'icônes Flutter

### Avec flutter_launcher_icons

1. Placez votre icône `app_icon.png` dans le dossier `assets/`

2. Ajoutez dans `pubspec.yaml` :
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  web:
    generate: true
    image_path: "assets/app_icon.png"
    background_color: "#006A4E"
    theme_color: "#006A4E"
  image_path: "assets/app_icon.png"
  adaptive_icon_background: "#006A4E"
  adaptive_icon_foreground: "assets/app_icon.png"
```

3. Exécutez :
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## Option 3 : Icônes manuelles

### Pour le Web
Remplacez ces fichiers dans `web/` :
- `favicon.png` (32x32px)
- `icons/Icon-192.png` (192x192px)
- `icons/Icon-512.png` (512x512px)
- `icons/Icon-maskable-192.png` (192x192px)
- `icons/Icon-maskable-512.png` (512x512px)

### Pour Android
Remplacez dans `android/app/src/main/res/` :
- `mipmap-hdpi/ic_launcher.png` (72x72px)
- `mipmap-mdpi/ic_launcher.png` (48x48px)
- `mipmap-xhdpi/ic_launcher.png` (96x96px)
- `mipmap-xxhdpi/ic_launcher.png` (144x144px)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192px)

### Pour iOS
Utilisez Xcode pour remplacer l'icône dans `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Palette de couleurs TogoSchool suggérée

```
Vert principal : #006A4E
Jaune/Or : #FFCE00
Rouge accent : #D21034
Blanc : #FFFFFF
Gris foncé : #2C3E50
```

## Exemple de prompt pour IA (si vous utilisez DALL-E, Midjourney, etc.)

```
Create a modern, minimalist app icon for an educational platform called "TogoSchool". 
The icon should feature a graduation cap or open book symbol. 
Use the colors of the Togo flag (green #006A4E, yellow #FFCE00, red #D21034) in a tasteful, 
professional way. Square format with rounded corners, flat design style, 
suitable for both mobile and web at 1024x1024px resolution. No text in the icon.
```

## Après avoir créé l'icône

1. Placez votre icône dans le dossier approprié
2. Reconstruisez l'application :
   ```bash
   flutter clean
   flutter pub get
   flutter build web --release
   ```
3. Redéployez sur Firebase :
   ```bash
   firebase deploy --only hosting
   ```
