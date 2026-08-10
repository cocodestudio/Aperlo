# FrameKit Project Rules

These rules apply to all AI agents working on the FrameKit workspace.

## 1. Design & UI Consistency
- **Strict Adherence to `DESIGN.md`:** Do not deviate from the defined color palette, typography (Syne & DM Sans), and spacing.
- **Components:** Always use the defined reusable components in `lib/widgets/` rather than creating new custom variations.
- **Styling:** Avoid gradients in UI chrome. Use them only within the editor canvas.

## 2. State Management (Riverpod)
- Use Riverpod for all state management as defined in `lib/providers/`.
- Ensure new providers are properly typed and adhere to the existing architecture (e.g., Notifier classes for complex state like `EditorNotifier`).
- Do not introduce `StatefulWidget` for global or complex state; rely on `ConsumerWidget` or `ConsumerStatefulWidget` where local state is absolutely necessary.

## 3. Firebase & Backend (Live MCP Verified)
- Follow the established security rules (`firestore.rules`, `storage.rules`). The Firebase MCP live analysis confirms that these are strictly enforced in production (e.g., rigid user isolation via `request.auth.uid` and 5MB storage limits).
- Keep all Firebase logic encapsulated within the services (`lib/services/`). Do not call Firebase directly from UI widgets.
- The Auth module actively uses Email/Password authentication. Do not alter Auth mechanisms without testing against the live provider setup.
- Always use the `firebase MCP` to validate rule changes before deployment (`firebase_validate_security_rules`), as live user data is actively protected.

## 4. Code Quality
- All UI strings should be sentence case (e.g., "Export screenshot", not "Export Screenshot").
- Avoid printing to console; use proper logging if necessary.
- Write modular, DRY code, especially within the canvas rendering logic (`dynamic_template.dart`, `template_renderer.dart`).
- When running `flutter analyze`, fix warnings and errors, but keep `info` logs ignored.
