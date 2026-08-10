# FrameKit - Project Analysis

## Overview
**FrameKit** is an App Store Screenshot Maker tailored for solo developers and indie app makers. Its primary goal is to provide a premium, efficient, and precise tool to generate high-fidelity app store screenshots without the bloat of generic design tools.

## Tech Stack
* **Framework:** Flutter (SDK ^3.11.0)
* **Language:** Dart
* **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`)
* **Navigation:** GoRouter
* **Backend:** Firebase (Auth, Cloud Firestore, Cloud Storage)
* **Local Storage:** Hive (`hive_flutter`)
* **Design & Assets:** Google Fonts (Syne, DM Sans, Syne Mono), Lucide Icons (`lucide_flutter`)

## Firebase Architecture
Analyzed via local configuration and verified against the live environment using the Firebase MCP (`firebase-tools`):
* **Project ID:** `framekit-app` (Lifecycle State: ACTIVE)
* **Auth:** Uses Email/Password authentication. Currently has an active user (`mastereditor8780@gmail.com`, UID: `WTxsBrSZnuYObZgdAnJzVHZqz7O2`) verifying the Auth module is active and receiving logins.
* **Firestore Data Model & Live Security Rules:**
  * `/users/{userId}`: User profiles (Contains: `name`, `email`, `avatarUrl`, `isPro`, `autoSave`, `defaultExportFormat`)
  * `/users/{userId}/collections/{collectionId}`: User collections (folders for screenshots)
  * `/users/{userId}/screenshots/{screenshotId}`: Individual screenshots containing canvas state
  * `/templates/{templateId}`: Global templates (Admin write-only, public read-only for authenticated users)
  * *Rules Verified:* Strict user isolation is enforced on the server. Authenticated users can only read/write their own data in Firestore based on `request.auth.uid`.
* **Storage & Live Security Rules:**
  * *Rules Verified:* Users can upload images to `/users/{userId}/thumbnails/` with a strictly enforced 5MB limit and `image/.*` content-type validation. Template assets are read-only.

## Project Structure (`lib/`)
* **`core/`**: Routing configuration (`app_router.dart`) and thematic design tokens (`app_theme.dart`).
* **`models/`**: Data classes for `CanvasElement`, `Collection`, `Screenshot`, `Template`, and `UserModel`.
* **`providers/`**: Riverpod state management. Notably, `EditorNotifier` implements a robust undo/redo stack (up to 50 actions) for canvas manipulation.
* **`screens/`**: UI screens including Auth, Collections, Editor, Export, Home, Onboarding, Profile, Splash, and Templates browser.
* **`services/`**: Repositories for interacting with Firebase (`auth_service.dart`, `firestore_service.dart`, `storage_service.dart`).
* **`widgets/`**: Reusable UI components like `dynamic_template.dart`, `template_renderer.dart`, `bottom_nav.dart`, and standard buttons/inputs following the design specs.

## Design System (from `DESIGN.md`)
* **Theme:** Studio Precision with Forest Depth (Light Theme with `#F5F7F5` ambient background and deep forest green `#1A6B4A` accent).
* **Typography:** Syne (Display/Headlines), DM Sans (Body/UI), Syne Mono (Technical specs).
* **Animations:** Snappy and purposeful (e.g., fast micro-interactions, spring bounces for success states).

## Key Workflows
* **Template Browsing & Rendering:** Users can browse cloud-hosted templates, dynamically load them, and render custom screenshots.
* **Canvas Editing:** The editor allows adding elements, changing backgrounds, and manipulating layout with a robust state management system.
* **Organization:** Screenshots are organized into Collections (like folders).
