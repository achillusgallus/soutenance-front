# Dossier Assets - TogoSchool

Ce dossier contient les ressources statiques de l'application.

## Structure

```
assets/
├── app_icon.png          <- Placez votre icône ici (1024x1024px)
├── images/               <- Pour les images de l'application
└── fonts/                <- Pour les polices personnalisées (si nécessaire)
```

## Instructions pour l'icône

1. Créez votre icône sur Canva (voir INSTRUCTIONS_ICONE.md à la racine du projet)
2. Exportez-la en PNG 1024x1024px
3. Nommez-la **app_icon.png**
4. Placez-la directement dans ce dossier `assets/`

## Après avoir ajouté l'icône

1. Assurez-vous que le dossier assets est déclaré dans `pubspec.yaml` :
   ```yaml
   flutter:
     assets:
       - assets/app_icon.png
   ```

2. Installez le package flutter_launcher_icons :
   ```bash
   flutter pub add dev:flutter_launcher_icons
   ```

3. Générez les icônes pour toutes les plateformes :
   ```bash
   flutter pub run flutter_launcher_icons
   ```
