# JobPilot AI

Flutter Android app with no signup, local PDF/DOCX resume extraction, editable profile, SQLite storage, manual job entry, offline scoring and manual tracker. The approved dark navy UI and logo are retained. No bundled sample jobs remain. Database upgrades remove legacy demo jobs/history while preserving real profile and manual jobs. Live discovery and automatic applications are not implemented.

## Commands

Flutter 3.47.7 / Dart 3.13.5, Java 17 are pinned in GitHub Actions.

```
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter build apk --release --target-platform android-arm64 --split-debug-info=build/symbols --tree-shake-icons
```

R8 minification and resource shrinking are enabled in android/app/build.gradle.kts. Only a green CI run publishes the APK to the fixed v0.1.0 release asset. Check the Actions job for actual results and byte size. Each published feature release must bump pubspec.yaml version and build number.

## Optional Groq ranking

Settings saves a user key only through flutter_secure_storage, never source code or repo. Existing saved keys unlock the toggle; AI stays opt-in. Turning it on, refreshing matches, adding a job or updating a profile can use https://api.groq.com/openai/v1/chat/completions with openai/gpt-oss-20b, documented at https://console.groq.com/docs/models and https://console.groq.com/docs/api-reference. Only supplied skills, target roles, location and saved job title/location/description are sent. The original resume file, name, email and phone fields are not included. Do not paste personal identifiers into these fields if you do not want them sent.

JSON responses require every supplied job once, integer scores 0-100 and exact quotes present in the supplied profile and job. AI cannot alter profile facts, listed skills/gaps or manual tracker status. Explanation text is composed locally from validated quotes. A score remains an estimate, not a hiring probability. Invalid responses, missing key, network failures and timeout restore offline scoring. 401/403 shows a clear rejected-key message and disables AI; 429 respects Retry-After with a cooldown and no automatic retry loop.

Keys embedded in an APK can be extracted. Secure storage reduces exposure but cannot protect a compromised device. Never ship a shared key; use a secure backend or each user's own key for public releases. Android backup is disabled.

## Verification and limits

CI has mocked HTTP tests for Groq request format, evidence validation, invalid key, rate limits and offline fallback, plus Settings toggle tests. No real Groq key is available for a live authenticated call. Never call mocked success a verified live Groq integration.

PDF text extraction is local via pdfrx; DOCX XML includes headers and paragraph boundaries. Scanned resumes require OCR elsewhere. Missing/ambiguous fields stay empty. Location heuristics copy labeled addresses and common header city/state/PIN lines without geocoding or guessing a city from a PIN alone. Review extracted details. Use Edit profile > Fill empty fields from saved resume for prior uploads.

Only arm64 Android is included. Signing uses an ephemeral development debug key, not a production key, so updates from different CI runs may fail signature checks. Do not uninstall blindly: uninstalling loses local resume/profile/tracker data. A stable release signing key and device testing remain required for production. This update has not been run on a phone.
