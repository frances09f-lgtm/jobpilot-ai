# JobPilot AI

Phase 1 Flutter Android MVP. No signup, login, bundled jobs or fake counts. The approved dark navy/blue/violet interface and logo are retained. Home, Jobs, Profile, Tracker and Settings tabs contain resume upload, processing, dashboard, recommended jobs, job details and profile editing.

## Current behavior
- PDF/DOCX extraction on device via pdfrx/PDFium and archive/xml. Original resume and editable profile stored locally. No personal resume is committed.
- Conservative name/contact/address parsing. Addresses, header city/state lines and accompanying PIN text are copied from the file, never inferred from a PIN database. Unknown/ambiguous fields remain empty. Existing profile edits are preserved; empty fields can be filled from stored resume text.
- No bundled job listings. Fresh install starts at zero. Database version 3 removes legacy demo jobs and their practice status history while preserving the resume, profile and non-demo listings.
- Add a job by hand: title, company, location, description and HTTPS application URL. Title/company/description required; absent location/URL stays blank. Skills recognized in the supplied description feed the unchanged offline matching scorer. Duplicate listings/URLs are rejected. Stored in SQLite via sqflite.
- Offline 0–100 matching: skills 70, inferred/explicit role 20, location 10. Missing details get no points. Relevance score is not a hiring probability.
- Search/filter saved jobs. Manual tracker supports all eight statuses. Applied count is explicitly manual, not evidence of a provider submission. The application link only opens a browser; it never submits anything.
- Optional Groq key stored in flutter_secure_storage, unused in Phase 1. No committed/hardcoded keys or network discovery. Live job sources come in Phase 2.

## Commands
Pinned CI: Flutter 3.47.7 stable and Java 17. CI prints environment details.

```sh
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter run
flutter build apk --release --target-platform android-arm64 --split-debug-info=build/symbols --tree-shake-icons
```

CI does not run flutter run. It replaces JobPilot-AI.apk in release v0.1.0 only after analysis, tests and release build pass. The arm64-only APK uses development debug-key signing, R8 and resource shrinking. It will not run on 32-bit-only Android devices. A phone test is still required for every update. CI success does not establish phone behavior.

## Limits and safety
- No live jobs, AI calls, cover letters, automated submissions or background refresh. No CAPTCHA/authentication/anti-bot bypass. Never guess screening or eligibility answers.
- Heuristic parsing depends on readable text/order. Scans need external OCR. Unsupported DOC/corrupt/encrypted files return errors. Limits: 10 MB file, 50 PDF pages, 2 MB DOCX text.
- Local resume/profile/job files are app-private, not additionally encrypted. Android backup disabled. Clearing/uninstalling loses local records. No cloud sync or analytics.
- Keys embedded in an APK can be extracted. Secure storage does not protect a compromised device. Use a user-owned key or secure backend for public AI releases.
- Tests include fictional resume/job fixtures only, not app data. Device picker/PDFium/keystore/rendering still require phone testing.

Architecture: lib/app (theme/state), lib/core (extraction/parsing/matching/manual-job validation), lib/data (SQLite/models), lib/features (screens/components).

Package docs: https://pub.dev/packages/pdfrx https://pub.dev/packages/file_picker https://pub.dev/packages/archive https://pub.dev/packages/xml https://pub.dev/packages/sqflite
