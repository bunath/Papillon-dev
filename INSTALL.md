# Papillon sur Apple Watch

App montre en SwiftUI, avec deux pages à faire défiler à la Digital Crown :

- **Emploi du temps** : aujourd'hui et les 6 jours suivants, un bloc par jour. Le cours en cours est mis en avant, les cours terminés sont estompés, les cours annulés sont barrés. La liste s'ouvre sur le cours en cours ou le prochain.
- **Devoirs** : les 14 prochains jours, regroupés par date de remise. Un appui ouvre le texte complet. Les devoirs faits ont une coche, les évaluations un badge.

L'iPhone envoie les données à la montre (WatchConnectivity). Elles sont gardées sur la montre, donc lisibles même iPhone hors de portée.

## Contenu

| Dossier | Rôle |
| --- | --- |
| `targets/watch/` | L'app montre (Swift) et sa configuration `expo-target.config.js` |
| `modules/papillon-watch/` | Module natif iPhone qui envoie les données à la montre |
| `utils/watch/` | Calcul des données (`payload.ts`, avec tests) et hook de synchro |
| `papillon-watch-edits.patch` | Les 3 petites modifications de fichiers existants |

## Installation

1. Copie `targets/`, `modules/papillon-watch/` et `utils/watch/` à la racine du projet.
2. Applique les 3 modifications : `git apply papillon-watch-edits.patch`, ou à la main :
   - `package.json` : ajouter la dépendance `"@bacons/apple-targets": "^5.0.0"`
   - `app.config.ts` : ajouter `"@bacons/apple-targets"` dans `plugins`, après `"@getpapillon/papillonkit"`
   - `app/_layout.tsx` : `import { useWatchSync } from '@/utils/watch/useWatchSync';` puis appeler `useWatchSync();` sous `useCourseLiveActivity();`
3. `npm install --legacy-peer-deps`
4. `npx expo prebuild -p ios --no-install` (macOS ou Linux/WSL, pas Windows natif). Cela ajoute la cible `PapillonWatch` au projet Xcode. Commite aussi `ios/Papillon.xcodeproj/project.pbxproj` : `ci_post_clone.sh` fait un `git restore .` après le prebuild, qui effacerait la cible sinon.
5. Dans Xcode 16 ou plus : installe la plateforme **watchOS** dans les réglages d'Xcode (onglet Plateformes ou Components selon la version), sinon même l'app iPhone ne compile plus. Puis `cd ios && pod install` et ouvre `Papillon.xcworkspace`.

## Tester dans le simulateur

Choisis le schéma `PapillonWatch` et un simulateur Apple Watch. Tant que l'iPhone n'a rien envoyé, un build debug affiche des données de démonstration (indiquées en bas de liste). Pour une vraie synchro, lance aussi Papillon sur un simulateur iPhone associé à cette montre.

## À savoir

- **Pas compilé dans Xcode.** Le code a été vérifié sans Xcode : syntaxe Swift, types TypeScript, tests du calcul des données, génération du projet. Une erreur de compilation Swift reste possible : envoie-moi le message d'Xcode, je corrige.
- Identifiants à adapter pour ta propre app : `ios.bundleIdentifier` et `ios.appleTeamId` dans `app.config.ts`. La montre prend `<bundleIdentifier>.watchkitapp`.
- Pas de complication sur le cadran : une complication ne défile pas.
- L'icône de la montre vient de `assets/images/icon.png`, qui a un canal alpha : à remplacer par une version sans transparence avant un envoi sur l'App Store.
- Le format des données est défini des deux côtés : `utils/watch/payload.ts` et `targets/watch/Models.swift`. Si tu en changes un, change l'autre.
- Tests : `bun test utils/watch`. Le `jest` du projet ne démarre pas sur une installation neuve (il manque `@react-native/jest-preset`), indépendamment de cet ajout.
