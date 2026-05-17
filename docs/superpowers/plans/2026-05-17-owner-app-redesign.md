# Owner App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve the owner app's operational clarity and field efficiency while keeping the current MiniFoot visual identity.

**Architecture:** Add a thin reusable owner design layer in shared widgets, then update the highest-value operational screens to consume those components. Payment branding is normalized through reusable payment logo badges and consistent status language.

**Tech Stack:** Flutter, GetX, flutter_svg, existing MiniFoot owner theme

---

### Task 1: Shared owner design components

**Files:**
- Create: `lib/core/widgets/owner_ui.dart`
- Modify: `lib/features/payments/screens/payments_screen.dart`
- Modify: `lib/features/profile/screens/payment_methods_screen.dart`

- [ ] Add reusable owner section header, intro card and payment brand badge widgets.
- [ ] Reuse those widgets in payment-focused screens first.
- [ ] Keep colors aligned with `lib/core/theme/app_theme.dart`.

### Task 2: Operational screen harmonization

**Files:**
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart`
- Modify: `lib/features/reservations/screens/reservations_screen.dart`
- Modify: `lib/features/availability/screens/availability_screen.dart`
- Modify: `lib/features/terrain/screens/terrain_list_screen.dart`

- [ ] Rework top sections to foreground today's context and next actions.
- [ ] Normalize section titles, subtitles and business wording.
- [ ] Reduce decorative noise where it slows down scanning.

### Task 3: Secondary screen alignment

**Files:**
- Modify: `lib/features/controllers/screens/controllers_screen.dart`
- Modify: `lib/features/notifications/screens/notifications_screen.dart`
- Modify: `lib/features/profile/screens/profile_screen.dart`

- [ ] Align labels, section structure and action visibility with the new owner UI language.
- [ ] Improve business comprehension without changing navigation architecture.

### Task 4: Verification

**Files:**
- Modify: `pubspec.yaml` only if needed by assets usage

- [ ] Run static verification on modified files.
- [ ] Review wording, accents, and visual consistency in the changed screens.
