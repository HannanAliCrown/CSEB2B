# Deployment

Every push to `deployment_mock` builds a release APK and sends it to testers
through Firebase App Distribution. The workflow is
[`.github/workflows/deploy-app-distribution.yml`](../.github/workflows/deploy-app-distribution.yml).

Nothing in the app talks to Firebase. App Distribution only receives the
finished APK, so no Firebase SDK, `google-services.json` or `firebase.json` is
needed here.

## What the workflow does

1. Checks formatting, runs `flutter analyze`, runs the tests.
2. Restores the signing keystore from a secret and builds the release APK.
3. Verifies the APK really is signed with the release key, and fails if it
   fell back to the debug key.
4. Uploads it to App Distribution with the branch, short SHA and commit
   subject as the release notes.
5. Deletes the credentials from the runner and keeps the APK on the run for
   14 days, so a tester's report can be matched to the exact binary.

Golden tests are excluded (`--exclude-tags golden`). They compare rendered
pixels, which depend on the machine's own font rasterisation, so they are a
local tool rather than a reason to block a tester build.

## One-time setup

### 1. Firebase project and Android app

1. Open the [Firebase console](https://console.firebase.google.com) and
   create a project, or pick an existing one. Google Analytics is not needed.
2. Inside the project choose **Add app → Android**.
3. Enter the package name exactly: `com.example.cse_b2b`. It must match
   `applicationId` in [`android/app/build.gradle.kts`](../android/app/build.gradle.kts).
4. Skip downloading `google-services.json` and skip the SDK steps — this
   project does not use them.
5. Open **Project settings → General**, find the Android app, and copy its
   **App ID**. It looks like `1:123456789012:android:0a1b2c3d4e5f6a7b`, and is
   already set as `FIREBASE_APP_ID` at the top of the workflow.

### 2. Tester group

In the console open **Release & Monitor → App Distribution → Testers &
Groups**, create a group, and note its alias (the workflow defaults to
`testers`). Add the testers' email addresses. Each tester accepts an
invitation once, then installs future builds from the App Distribution app or
the emailed link.

### 3. Service account for CI

The workflow authenticates as a service account rather than a person, so it
keeps working when someone leaves.

1. In the [Google Cloud console](https://console.cloud.google.com/iam-admin/serviceaccounts),
   with the Firebase project selected, choose **Create service account**.
2. Name it something like `github-app-distribution`.
3. Grant it the **Firebase App Distribution Admin** role. Nothing more —
   this account only needs to publish builds.
4. Open the account → **Keys → Add key → Create new key → JSON**, and
   download it.

That JSON is a credential. Do not commit it, and delete the download once it
is in GitHub Secrets.

### 4. GitHub secrets

In the repository, **Settings → Secrets and variables → Actions**, add these
as **repository secrets**:

| Secret | What it holds |
| --- | --- |
| `FIREBASE_SERVICE_ACCOUNT` | The entire contents of the JSON key file from step 3 |
| `ANDROID_KEYSTORE_BASE64` | The keystore, base64 encoded |
| `ANDROID_KEYSTORE_PASSWORD` | The keystore password |

The App ID is not a secret — a copy of it is embedded in every distributed
build — so it is written plainly as `FIREBASE_APP_ID` at the top of the
workflow. Change it there if the app is ever moved to another Firebase
project.

The key alias is fixed in
[`android/app/build.gradle.kts`](../android/app/build.gradle.kts) and the key
shares the store's password, so there is nothing else to configure.

Optionally add a **variable** (not a secret) named `FIREBASE_TESTER_GROUPS`
to send builds to a group other than `testers`. Several groups are separated
by commas.

## Signing

Release builds are signed with a keystore that is never stored in this
repository.

- **Locally**, `android/key.properties` supplies it. That file is
  gitignored. It is not created by a fresh clone, and without it a release
  build falls back to the debug key so `flutter run --release` still works.
- **On CI**, the same four values arrive as environment variables from the
  secrets above.

`android/key.properties` looks like this:

```properties
storeFile=C:/Projects/cse_b2b_signing/cse-upload-keystore.jks
storePassword=<the keystore password>
keyAlias=cse-upload
keyPassword=<the key password>
```

### Keep the keystore safe

Android identifies an app by its signature. If the keystore is lost, no
future build can update an existing install — every tester would have to
uninstall first, and a Play Store listing could never be updated at all.
Keep a copy somewhere durable and shared, not only on one machine.

The first CI build is also signed differently from any APK built before this
was set up, so testers holding an older sideloaded build must uninstall it
once. After that, updates install over the top normally.

## Checking a deployment

The run appears under the repository's **Actions** tab. A green run means the
APK reached App Distribution; testers are notified by email. The **Releases**
list in the Firebase console shows what each tester received, and who has
installed it.

To re-send the current commit without pushing an empty one, use **Run
workflow** on the Actions tab.
