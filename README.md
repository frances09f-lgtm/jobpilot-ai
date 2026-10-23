# JobPilot AI

Phase 1 only: a free-first, local Flutter Android MVP. No account or login. The eight screens follow the approved navy/blue/violet preview: resume upload, processing, dashboard, recommended jobs, job details, profile, application tracker and settings. Five tabs: Home, Jobs, Profile, Tracker, Settings.

## Implemented
- Pick a text-based PDF or DOCX, extract on device using pdfrx/PDFium or archive + xml, keep the original in app-private documents and review candidate fields before saving.
- Conservative local regex and section parsing. Missing fields stay empty. Names in contact headers are copied as review candidates when a nearby email or phone supports the header. Explicit labels and comma-separated header locations are supported; ambiguous fields stay empty. Stored resume text fills previously empty fields without overwriting edits. Suggested roles are separate from verified profile fields.
- SQLite via sqflite persists the profile, normalized fictional sample jobs, scores, matched skills/gaps, statuses, dates, errors and status history. Unique job keys and a composite uniqueness rule prevent repeated seed imports.
- Explainable offline 0–100 score: skills 70, inferred/explicit role 20, explicitly matching location 10. Missing information gets no points. These are relevance scores, not hiring probabilities.
- A persistent Hide sample jobs switch hides fictional jobs from dashboard, recommendations and tracker without deleting practice records. Live jobs remain out of scope.
- Original navy/blue/violet vector launcher logo is also shown on upload and in the app bar. No paid generation or external login.
- Search/filter sample jobs, view score explanations, edit profile, replace resume, and manually record all eight application statuses.
- Optional key field uses flutter_secure_storage. It is not used or sent anywhere in Phase 1. No shared key is committed.

## Build and run
Pinned CI SDK: Flutter 3.47.7 stable, Dart bundled with that SDK, Java 17. CI prints flutter --version, flutter doctor -v and java -version before building.

If android/ is absent, generate scaffolding without replacing the MVP source:

```sh
flutter create --platforms=android --org com.ambi.jobpilot --project-name jobpilot_ai /tmp/jobpilot_scaffold
cp -R /tmp/jobpilot_scaffold/android .
cp /tmp/jobpilot_scaffold/.metadata .
```

Then:

```sh
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter run
flutter build apk --release --target-platform android-arm64 --split-debug-info=build/symbols
```

CI does not run flutter run or a phone/emulator test. It uploads build/app/outputs/flutter-apk/app-release.apk as JobPilot-AI-APK and publishes JobPilot-AI.apk under release tag v0.1.0 after successful analysis, tests and build. The release uses debug-keystore signing for development only, not Play Store distribution. CI commits generated Android scaffolding and pubspec.lock with [skip ci]. All build writes stay in this repository.

## Honest limitations and safety
- All jobs are fictional samples, clearly labelled. No real applications are possible from them and no fake employer links are supplied. The official-page launcher is disabled for samples. Real submissions count is zero even if a sample is manually marked Applied.
- Phase 2 live API availability/terms/limits, Phase 3 Groq calls/cover letters, Phase 4 permitted automation and Phase 5 background refresh are not implemented.
- No CAPTCHA, authentication or anti-bot bypass. Applied is a manual record, not provider verification. No invented screening/eligibility/legal answers.
- PDF text order and heuristic fields can be imperfect. Ambiguous names and locations stay blank. Header name candidates are heuristic and must be reviewed. Scans need external OCR. Old DOC, corrupt/encrypted documents and files over 10 MB are rejected or shown with an error; PDFs over 50 pages and DOCX text over 2 MB are limited. DOCX extraction includes body and header/footer paragraphs, not images.
- SQLite/profile/resume files are app-private, not additionally encrypted. Android backup is disabled in CI-generated manifest. Uninstalling/clearing app data removes local records. No cloud backup/sync/analytics.
- Secure key storage cannot protect keys on a compromised device. Keys embedded in APKs can be extracted. Use your own key or a secure backend for public AI releases. No network requests are made by the MVP app. The unused direct HTTP dependency was removed; dependencies may still use it transitively.
- Dark theme only; system theme selection and pixel-perfect typography are not implemented. Native layouts follow the preview rather than copying illustrative counts or profile data.
- Unit tests cover extraction heuristics, matching, status serialization and sample safety. Actual file picker, PDFium extraction, SQLite, keystore, rendering, accessibility and phone behavior require device testing. CI success alone is not proof of a working phone flow.

## Architecture
lib/app: startup, theme and Riverpod state.
lib/core: extraction, conservative parser and matching.
lib/data: models, SQLite repository and sample seed data.
lib/features: screens and reusable UI components.

Package documentation: https://pub.dev/packages/pdfrx , https://pub.dev/packages/file_picker , https://pub.dev/packages/archive , https://pub.dev/packages/xml , https://pub.dev/packages/sqflite

The project does not include personal resumes, API keys or user identity. All test names and companies are fictional.
