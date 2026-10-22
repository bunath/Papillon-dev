# Papillon + Apple Watch — projet complet

Ce dossier est le dépôt officiel **PapillonApp/Papillon** (commit `fc92c7a`) avec l'app Apple Watch déjà intégrée et le projet Xcode déjà généré. Rien à copier, pas de patch à appliquer.

## Ce que fait l'app montre

Deux pages, qu'on fait défiler à la Digital Crown (glisse sur le côté pour passer de l'une à l'autre) :

- **Emploi du temps** : aujourd'hui et les 6 jours suivants, un bloc par jour. Le cours en cours est mis en avant, les cours terminés sont estompés, les cours annulés sont barrés. La liste s'ouvre sur le cours en cours ou le prochain.
- **Devoirs** : les 14 prochains jours, regroupés par date de remise. Un appui ouvre le texte complet. Les devoirs faits ont une coche, les évaluations un badge.

L'iPhone envoie les données à la montre (WatchConnectivity) : à l'ouverture de Papillon, à chaque changement de l'emploi du temps ou des devoirs, puis toutes les 5 minutes tant que l'app tourne. La montre garde les dernières données reçues, donc elles restent lisibles iPhone hors de portée.

## Prérequis

Un **Mac** : Xcode n'existe pas sur Windows ni Linux, donc pas de simulateur Apple Watch ailleurs.

- Xcode 16 ou plus, avec la plateforme **watchOS** installée (réglages d'Xcode, onglet Plateformes ou Components selon la version). Sans elle, même l'app iPhone ne compile plus.
- Node 22 et CocoaPods 1.16.2 ou plus.

## Build

```bash
npm install --legacy-peer-deps
cd ios && pod install
open Papillon.xcworkspace
```

`package-lock.json` fige les versions qui ont été testées.

Si Xcode répond « node: command not found » (Node installé via nvm, par exemple), crée `ios/.xcode.env.local` avec `export NODE_BINARY=/chemin/vers/node`.

## Tester dans le simulateur

Dans Xcode, _Window → Devices and Simulators → Simulators → +_ : crée un iPhone avec une **Apple Watch associée** (« Paired Apple Watch »).

1. **La montre seule** : schéma `PapillonWatch` (si Xcode en propose deux, prends celui du projet Papillon, l'autre vient de Pods), destination = la montre de la paire, Run. En debug, tant que l'iPhone n'a rien envoyé, la montre affiche des données de démonstration (indiquées en bas de liste). Pas besoin de Metro ni de compte.
2. **Avec la vraie synchro** : lance `npx expo start` dans un terminal, puis schéma `Papillon` sur l'iPhone de la paire, Run. Dans le lanceur de développement qui s'ouvre, choisis le serveur Metro (`http://localhost:8081`). Connecte un compte dans Papillon : les données arrivent sur la montre quelques secondes plus tard.

`npx expo run:ios` fait aussi le build, lance Metro et ouvre l'app (choisis l'iPhone de la paire).

## Ce qui a été ajouté au dépôt officiel

| Chemin                                             | Rôle                                                                                                             |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `targets/watch/`                                   | L'app montre (SwiftUI) et `expo-target.config.js`. `Info.plist` et `Assets.xcassets` sont générés par le plugin. |
| `modules/papillon-watch/`                          | Module natif Expo côté iPhone : envoie les données à la montre.                                                  |
| `utils/watch/`                                     | Calcul des données (`payload.ts`, avec tests) et hook de synchro.                                                |
| `package.json`, `app.config.ts`, `app/_layout.tsx` | 3 petites modifications : dépendance `@bacons/apple-targets`, plugin, appel de `useWatchSync()`.                 |
| `ios/`                                             | Projet Xcode régénéré, avec la cible `PapillonWatch`. Fichiers officiels inchangés, sauf `project.pbxproj`.      |
| `package-lock.json`                                | Versions exactes testées (le dépôt officiel n'en a pas).                                                         |

Pour proposer le code à Papillon, ou le reprendre dans ton fork, seuls les quatre premiers éléments comptent.

## À savoir

- **Jamais compilé dans Xcode.** Il n'y avait pas de Mac pour le faire. Ce qui a été vérifié sans Xcode : la syntaxe des 13 fichiers Swift, les types TypeScript, les tests du calcul des données, la génération du projet Xcode (`expo prebuild`) et la détection du module natif. Une erreur de compilation Swift reste possible : envoie le message d'Xcode et je corrige.
- **Identifiants de Papillon.** Le bundle id `xyz.getpapillon.ios` et l'équipe `7RXNP6V83P` sont ceux de Papillon. Le simulateur n'en a pas besoin. Pour un vrai appareil, mets ta propre équipe dans _Signing & Capabilities_ (cibles `Papillon`, `PapillonWidgets`, `PapillonWatch`) et adapte `ios.bundleIdentifier` et `ios.appleTeamId` dans `app.config.ts`. La montre prend `<bundle id>.watchkitapp`.
- **Pas de complication** sur le cadran : une complication ne défile pas.
- **Si tu relances** `npx expo prebuild -p ios --no-install`, le plugin recrée la cible montre. Dans le dépôt officiel, commite alors `ios/Papillon.xcodeproj/project.pbxproj` : `ci_post_clone.sh` fait un `git restore .` après le prebuild, qui effacerait la cible sinon.
- **Format des données** défini des deux côtés : `utils/watch/payload.ts` et `targets/watch/Models.swift`. Si tu en changes un, change l'autre.
- **Tests** : `bun test utils/watch`. Le `jest` du projet ne démarre pas sur une installation neuve (il manque `@react-native/jest-preset`), indépendamment de cet ajout.
