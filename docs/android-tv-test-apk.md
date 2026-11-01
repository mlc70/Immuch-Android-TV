# Android TV test APK: preserve Immich login across builds

The TV build uses Android package ID `com.aprogsys.immuch360.tvtest` and label **Immuch Android TV**. This is separate from the official Immuch360 package. The package name alone is not enough to preserve login; **every APK must also have the same signing certificate**.

## Permanent identity

The personal signing identity was created November 1, 2026 (October 31 Pacific).
Certificate SHA-256: `822dd1fd322642aa8fd56f790de7ac1345aab52c542647492d86455fad667d3d`.
The workflow checks the keystore and finished APK against this public fingerprint.
Missing secrets, a different certificate or a missing release keystore fail the
build. There is no temporary-signing fallback for this TV fork.

The encrypted PKCS12 key and a Windows-user-protected password backup are under
the Git-ignored `.signing/` directory. `tools/android-tv-signing.ps1` initializes
only an absent key, signs/verifies APKs, or copies one required secret to the
Windows clipboard without printing it. It refuses to overwrite an existing key.
The password backup uses Windows DPAPI: do not assume it can be decrypted on a
different Windows installation. Keep a separate secure recovery copy of the key
and its password before retiring this computer.

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

After both secrets are configured, run the [Android TV APK](https://github.com/mlc70/Immuch-Android-TV/actions/workflows/android-tv-test-apk.yml) workflow on `feature/android-tv-permanent`. In its Summary, verify **Signing mode: persistent**. Missing secrets or an unexpected signer stop the build before any APK is published.

## Install/update

The Shield's r13 install and the original r20 artifact have different temporary
certificates. The permanent identity cannot update either of those temporary
identities. After the permanent APK has been built and verified, replacing the old
install requires one fresh setup. Future APKs made with the same two secrets
install as in-place updates. Keep the old app until the permanent APK is ready.

```powershell
adb install -r .\Immuch-Android-TV-test.apk
```

Avoid `adb uninstall`, `adb shell pm clear`, or Android Settings → Clear storage/data: they erase the local Immich session. If an update reports `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, stop and inspect the APK signer instead of uninstalling: it means the certificate is different. An older feature branch may also use incompatible database migrations, so prefer upgrading forward from the same development line.

The app intentionally sets `android:allowBackup="false"`; copying its encrypted/local session to a different app ID is not a supported Android procedure. Never commit signing keys, authentication tokens, server passwords, or backed-up app databases to this repository.

## Current status

- The Android TV workflow requires the permanent signing identity; the repository owner stores its two encrypted Actions secrets.
- The build artifact's Android package ID is fixed, independently of which PR branch is being built.
