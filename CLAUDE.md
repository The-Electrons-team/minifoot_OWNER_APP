# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run on connected device
flutter clean && flutter pub get  # Full reset
```

No tests are configured. No linting beyond `flutter_lints`.

## What This App Is

MiniFoot Owner is a Flutter mobile app for **mini-football pitch owners in Senegal**. It lets owners manage pitches, bookings, availability slots, payments, revenues, notifications, and chat. Built by ELECTRONS TEAM (developer: Mamadou Sy).

**Backend status**: authentication, password reset/change, terrain management, owner reservation listing/detail/refusal, QR check-in, owner profile display/edit/avatar/phone/payout info, dedicated owner dashboard, in-app notifications, revenues/payments, availability, controllers, and PDF reports are connected to the NestJS backend. Chat and tournaments still use mock data or need owner-specific endpoints.

## Architecture

**GetX** is used for everything: state management (`.obs` + `Obx`), navigation (`Get.toNamed`), dependency injection (`Get.lazyPut` in bindings).

Each feature follows this structure:
```
features/<name>/
  bindings/<name>_binding.dart   # Get.lazyPut the controller
  controllers/<name>_controller.dart  # Business logic + mock data
  screens/<name>_screen.dart     # UI widgets
```

**Entry point**: `main.dart` initializes Firebase, loads `.env` (Mapbox token), sets up French locale (`fr_FR`) for `table_calendar`, and inits FCM via `NotificationService`.

**Routing**: All routes defined in `lib/routes/app_routes.dart` as `GetPage` entries with custom transitions. Routes class has static string constants.

**Core layer** (`lib/core/`):
- `theme/app_theme.dart` — All color constants (`kBg`, `kGreen`, `kGold`, etc.), shadows, gradients, and `ThemeData`
- `services/in_app_notification_service.dart` — REST notifications in-app: list, mark read, mark all read
- `services/notification_service.dart` — FCM push shell: permission, token, foreground banner, background handler, tap-to-navigate by notification `type` field
- `widgets/` — Shared `shimmer_loading.dart`, `lottie_success_dialog.dart`

## Key Conventions

- **UI language is French** — all user-facing strings are hardcoded in French (no i18n)
- **Color constants** use `k` prefix: `kBg`, `kGreen`, `kTextPrim`, `kBorder`, etc.
- **Private widget builders** use `_build` prefix (e.g., `_buildPaymentCard()`) or private `_Widget` classes
- **Animations**: Use `flutter_animate` extension syntax: `.animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0)`
- **Mock data** still lives in some controller `_loadMock...()` methods — replace module by module with service calls
- **Payment methods**: Wave (blue `#00B0F0`), Orange Money (orange `#FF6D00`), Yas Money (gold `#FFD100`) — logos in `assets/images/`
- **PDF reports**: use built-in `pdf` fonts for generation; do not rely on the local `DMSans-Variable.ttf` asset unless it has been replaced with a real TTF file.

## Design System

### Couleurs (définies dans `core/theme/app_theme.dart`)

| Constante | Hex | Usage |
|-----------|-----|-------|
| `kBg` | `#F5F0E8` | Fond de page (beige chaud) |
| `kBgCard` | `#FFFFFF` | Fond des cartes |
| `kBgSurface` | `#F0EBE3` | Fond inputs, surfaces secondaires |
| `kGreen` | `#006F39` | Couleur principale, boutons, accents |
| `kGreenLight` | `#E8F5E9` | Badges succès, fond d'icônes vertes |
| `kGold` | `#F59E0B` | Revenus, notes, créneaux |
| `kGoldLight` | `#FEF3C7` | Badge fond or |
| `kBlue` | `#1565C0` | Réservations, info |
| `kBlueLight` | `#DBEAFE` | Badge fond bleu |
| `kOrange` | `#E65100` | Scanner, paiements |
| `kRed` | `#EF4444` | Danger, annulation |
| `kRedLight` | `#FEE2E2` | Badge fond rouge |
| `kTextPrim` | `#1A1A1A` | Texte principal |
| `kTextSub` | `#6B7280` | Texte secondaire |
| `kTextLight` | `#9CA3AF` | Placeholders, texte léger |
| `kBorder` | `#E5E0D8` | Bordures |
| `kDivider` | `#F0EBE3` | Séparateurs |

**Règles couleurs** :
- Ne jamais utiliser `Colors.red`, `Colors.black12` etc. — toujours les constantes `k*`
- Opacité blanche : utiliser `Colors.white.withValues(alpha: 0.75)` (pas `Colors.white70`)
- Chaque quick action doit avoir une couleur distincte de ses voisines dans la grille

### Typographie

| Contexte | Font | Size | Weight |
|----------|------|------|--------|
| Titres AppBar | Orbitron | 18px | w700 |
| Titre marque "MINIFOOT" | Orbitron | 22px | w900 italic |
| Section headers | Orbitron (via `OwnerSectionHeader`) | — | — |
| Valeurs chiffrées (stats, revenus) | Default (DMSans) | 20px | w900 |
| Labels de cartes/sections | Default | 12px | w500–w600 |
| Body text | Default | 13–14px | w600–w700 |
| Petits labels (nav, badges) | Default | 11–12px | w500–w700 |

**Règles typo** :
- Toujours `fontFamily: 'Orbitron'` pour les titres d'AppBar
- Les valeurs numériques importantes utilisent w900
- Les labels secondaires utilisent w500, jamais en dessous de 11px
- Pas de `letterSpacing` sauf cas très spécifique

### Border Radius

| Contexte | Radius |
|----------|--------|
| Cartes (cards, containers principaux) | **18px** |
| Revenue card (spéciale, plus grande) | **20px** |
| Inputs, champs de texte | **14px** |
| Containers d'icônes | **12px** |
| Badges, chips, toggles | **12px** |
| Bottom sheets | **24px** |
| Bottom nav (pilule) | **36px** |

### Containers d'icônes

| Taille | Usage |
|--------|-------|
| **36x36** + icône 18px | Petit (stats mini cards, champs de formulaire) |
| **40x40** + icône 20–22px | Moyen (quick actions, revenue card) |
| **46x46** + icône 22px | Grand (booking tiles, notification tiles) |

### Espacement

| Zone | Valeur |
|------|--------|
| Padding horizontal global des pages | **24px** |
| Espacement entre cartes/sections | **14–18px** |
| Espacement entre section et bouton principal | **24px** |
| `Wrap` spacing (grilles quick actions) | 12px horizontal, 14px vertical |
| Booking tiles margin bottom | **12px** |
| Bottom padding avant nav bar | **84px** (dashboard), **36px** (pages internes) |

### Icônes (Phosphor Icons)

| Style | Usage |
|-------|-------|
| `PhosphorIconsDuotone.*` | Icônes principales dans les cartes, contenus |
| `PhosphorIcons.*` (trait/regular) | Boutons retour (`caretLeft`), chevrons (`caretRight`), icônes d'actions (sécurité, reversements, lock, camera) |
| `PhosphorIconsBold.*` | Jamais seul — toujours via `PhosphorIcon`, pas via `Icon()` |

**Règles icônes** :
- **Toujours** utiliser le widget `PhosphorIcon()`, **jamais** `Icon()` avec des icônes Phosphor
- Bouton retour : `PhosphorIcons.caretLeft` à 24px (style trait)
- Chevrons de navigation : `PhosphorIcons.caretRight` à 18px (style trait)
- Ne jamais utiliser `Icons.*` (Material) — tout est en Phosphor

### Zones de tap / Interactions

- **AppBar leading/actions** : utiliser `GestureDetector` avec `behavior: HitTestBehavior.opaque` + `Center` pour que toute la zone soit cliquable, pas seulement l'icône
- **Cartes cliquables** : utiliser `GestureDetector` avec `behavior: HitTestBehavior.opaque` ou `InkWell` avec `borderRadius`
- **Boutons header (cloche, profil)** : ajouter `Padding(4)` autour du container pour agrandir la zone de tap
- Taille minimale recommandée pour une zone de tap : **48x48px**

### Textes & UX writing

- **Pas de textes kilométriques** — phrases courtes, directes, max 1 ligne si possible
- Supprimer les cartes d'introduction redondantes quand le titre de section suffit
- Hints de champs : courts ("Min. 6 caractères", pas "Entrez un mot de passe d'au moins 6 caractères")
- Boutons : un seul mot ou deux max ("Enregistrer", "Mettre à jour", pas "Enregistrer les coordonnées de paiement")
- Notices info : une seule phrase, pas de paragraphe
- Ne pas doubler les infos (pas de section header + texte explicatif qui disent la même chose)

### Boutons principaux (ElevatedButton)

| Propriété | Valeur |
|-----------|--------|
| Hauteur | **54px** |
| Border radius | **18px** |
| Background | `kGreen` |
| Disabled background | `kGreen.withValues(alpha: 0.5)` |
| Font size | **15px** w900 |
| Elevation | **0** |
| Loader | `CircularProgressIndicator` 20x20, strokeWidth 2, blanc |

### Ombres

| Constante | Usage |
|-----------|-------|
| `kCardShadow` | Cartes standard (opacity 0.08, blur 12) |
| `kElevatedShadow` | Éléments surélevés (opacity 0.12, blur 20) |
| `kNavShadow` | Barre de navigation (opacity 0.10, blur 20) |
| Ombre dynamique (revenue card) | Interpoler l'ombre selon le scroll pour donner un effet de flottement |

## Important Gotchas

- `NotificationService.init()` runs before `runApp()` — navigation from `getInitialMessage` is delayed 800ms via `Future.delayed` to wait for GetMaterialApp mount
- `table_calendar` requires `initializeDateFormatting('fr_FR', null)` in `main()` or it throws `LocaleDataException`
- Never use `shrinkWrap: true` + `NeverScrollableScrollPhysics()` on a GridView/ListView inside `Expanded` — causes massive overflow
- `.env` file contains a Mapbox token and is bundled as a Flutter asset

## Feature Status

**Connected**: auth flow (splash→onboarding→login→register→OTP), forgot/reset password, profile password change, profile avatar upload/display, phone change via OTP, owner payout info, terrain list/form CRUD, terrain image upload, terrain image display via storage proxy, Mapbox preview/geolocation in the terrain form, owner reservation list/detail/refusal, QR check-in, profile display and first/last name update, availability, dedicated `GET /owner/dashboard`, in-app notifications, revenues, payments, controllers, and PDF reports.

**Complete UI but still mock/partial**: FCM push registration, chat list, tournaments.

**Next backend task**: FCM token registration, chat owner, or tournaments.
