# Android TV test APK: preserve Immich login across builds

The test build uses Android package ID `com.aprogsys.immuch360.tvtest` and label **Immuch TV Test** on all TV feature branches. This is separate from the official Immuch360 package. The package name alone is not enough to preserve login; **every APK must also have the same signing certificate**.

## Set up a persistent signing key (once)

Create a **local test-only signing key** with Java's `keytool`. Do **not** use an Android production/app-store signing key.

On Windows PowerShell, with the JDK installed:

```powershell
keytool -genkeypair -alias tvtest -keyalg RSA -keysize 3072 -validity 3650 -storetype PKCS12 -keystore "$HOME\immuch-tv-test.jks" -dname "CN=Immuch Android TV Test, O=Personal Development"
```

Enter a strong keystore password when prompted and save it securely. For PKCS12 the key password is the keystore password.

Copy the keystore to the clipboard **as Base64** (do not paste it into GitHub issues, PR comments or chats):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\immuch-tv-test.jks")) | Set-Clipboard
```

In the **fork** `mlc70/Immuch-Android-TV`, open **Settings → Secrets and variables → Actions → New repository secret** and create:

| Secret | Value |
| --- | --- |
| `TV_TEST_KEYSTORE_BASE64` | Paste the Base64 data from your clipboard |
| `TV_TEST_KEYSTORE_PASSWORD` | The keytool password |

Only two secrets are needed. The alias is fixed as `tvtest`. Keep `immuch-tv-test.jks` and its password in secure offline storage so the same signing identity can be restored later. Clear the clipboard after uploading the key.

After both secrets are configured, run the [Android TV Test APK](https://github.com/mlc70/Immuch-Android-TV/actions/workflows/android-tv-test-apk.yml) workflow again. In its Summary, verify **Signing mode: persistent**. If either secret is missing, the workflow falls back to a temporary debug signing key and will warn that upgrades might not preserve app data; it won't silently claim persistence.

## Install/update

Because older test APKs were `.pr1`, `.pr2` or `.pr3` and signed by temporary keys, **a single fresh login is required in the new `.tvtest` application**. After that, compatible future APKs made with the *same two secrets* install as in-place updates.

```powershell
adb install -r .\Immuch-Android-TV-test.apk
```

Avoid `adb uninstall`, `adb shell pm clear`, or Android Settings → Clear storage/data: they erase the local Immich session. If an update reports `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, stop and inspect the APK signer instead of uninstalling: it means the certificate is different. An older feature branch may also use incompatible database migrations, so prefer upgrading forward from the same development line.

The app intentionally sets `android:allowBackup="false"`; copying its encrypted/local session to a different app ID is not a supported Android procedure. Never commit signing keys, authentication tokens, server passwords, or backed-up app databases to this repository.

## Current status

- Android TV test build workflow supports stable signing when configured, but **the GitHub repository secrets must be created by its owner**.
- The build artifact's Android package ID is fixed, independently of which PR branch is being built.
