# Instructions pour générer l'icône TogoSchool

## Option 1 : Utiliser un générateur en ligne (Recommandé)

### Étape 1 : Créer l'icône
Utilisez un de ces sites gratuits :
- **Canva** (https://www.canva.com) - Créer un design carré 1024x1024px
- **Figma** (https://www.figma.com) - Gratuit pour usage personnel
- **Adobe Express** (https://www.adobe.com/express) - Générateur d'icônes

### Étape 2 : Design moderne et professionnel pour TogoSchool

#### Concept recommandé : "Digital Learning Hub"

**Symbole principal** :
- Un **livre ouvert stylisé** qui se transforme en **écran/tablette** (fusion du traditionnel et du digital)
- OU un **"T"** géométrique moderne avec un **point/accent** qui représente la connaissance
- OU une **graduation cap minimaliste** avec des lignes épurées

**Palette de couleurs moderne** :
- **Couleur principale** : Bleu profond `#1E3A8A` ou Violet moderne `#6366F1` (représente la confiance, l'intelligence)
- **Couleur secondaire** : Cyan/Turquoise `#06B6D4` ou Orange vibrant `#F97316` (représente l'innovation, l'énergie)
- **Accent** : Blanc `#FFFFFF` pour la clarté
- **Fond** : Dégradé subtil du bleu foncé vers le bleu clair OU fond uni avec ombre portée

**Style visuel** :
- **Design flat/material** : Pas de textures, formes géométriques simples
- **Effet de profondeur** : Légère ombre portée ou dégradé subtil pour donner du relief
- **Coins arrondis** : 20-25% de rayon pour un look moderne et accessible
- **Minimaliste** : Maximum 2-3 couleurs, formes simples et reconnaissables

**Exemples de composition** :
1. **Option 1 - Tech Education** : 
   - Fond : Dégradé bleu foncé → bleu clair
   - Symbole : Livre ouvert blanc avec des pixels/carrés qui s'envolent (représente la transformation digitale)
   
2. **Option 2 - Modern Academic** :
   - Fond : Violet moderne uni
   - Symbole : "T" géométrique en blanc avec un point cyan au-dessus (comme un i-accent)
   
3. **Option 3 - Smart Learning** :
   - Fond : Bleu profond
   - Symbole : Graduation cap minimaliste en blanc avec une ampoule/étoile orange au sommet

**Ce qu'il faut éviter** :
- ❌ Trop de détails (illisible en petit format)
- ❌ Plus de 3 couleurs
- ❌ Texte dans l'icône
- ❌ Effets 3D complexes ou réalistes
- ❌ Cliparts génériques

### Étape 3 : Créer sur Canva

1. Allez sur **canva.com** et connectez-vous
2. Cliquez sur **"Créer un design"** → **"Taille personnalisée"** → **1024 x 1024 px**
3. Choisissez un fond :
   - Soit un **dégradé** : Éléments → Dégradés → Choisir bleu foncé vers bleu clair
   - Soit une **couleur unie** : Couleur de fond → `#1E3A8A` (bleu profond)
4. Ajoutez votre symbole :
   - Allez dans **Éléments** → Recherchez "book icon", "graduation cap", ou "letter T"
   - Choisissez un design **minimaliste/ligne**
   - Changez la couleur en **blanc** `#FFFFFF`
   - Centrez et agrandissez (70% de la taille du carré)
5. Ajoutez un accent (optionnel) :
   - Un petit cercle/point de couleur `#F97316` (orange) ou `#06B6D4` (cyan)
6. Ajoutez une ombre portée subtile :
   - Sélectionnez votre symbole → Effets → Ombre → Opacité 20%, Flou 10px


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

## Palette de couleurs TogoSchool moderne

```
Option 1 - Bleu Professionnel :
  Bleu principal : #1E3A8A
  Cyan accent : #06B6D4
  Blanc : #FFFFFF

Option 2 - Violet Innovant :
  Violet principal : #6366F1
  Orange accent : #F97316
  Blanc : #FFFFFF

Option 3 - Bleu Dégradé :
  Bleu foncé : #1E40AF
  Bleu clair : #3B82F6
  Blanc : #FFFFFF
```

## Exemple de prompt pour IA (DALL-E, Midjourney, etc.)

```
Create a modern, minimalist app icon for "TogoSchool", an educational technology platform.
Design style: Flat design with subtle depth, professional and clean.
Color scheme: Deep blue (#1E3A8A) background with white (#FFFFFF) symbol and cyan (#06B6D4) accent.
Symbol: A minimalist open book that transforms into a digital screen/tablet, representing the fusion of traditional and digital learning.
OR: A geometric letter "T" with a glowing dot above it representing knowledge and innovation.
Format: Square 1024x1024px with 20% rounded corners.
Style: Modern, professional, suitable for both mobile and web.
No text, no realistic effects, clean geometric shapes only.
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
