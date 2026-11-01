param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('Initialize', 'Sign', 'CopyKeystoreSecret', 'CopyPasswordSecret')]
  [string]$Action,
  [string]$JavaHome,
  [string]$Apk,
  [string]$OutputApk,
  [string]$BuildTools = "$env:LOCALAPPDATA/Android/Sdk/build-tools/36.0.0"
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$signingRoot = Join-Path $projectRoot '.signing'
$keyPath = Join-Path $signingRoot 'immuch-android-tv.p12'
$passwordPath = Join-Path $signingRoot 'password.dpapi'

if ($Action -eq 'Initialize') {
  if ((Test-Path -LiteralPath $keyPath) -or (Test-Path -LiteralPath $passwordPath)) {
    throw 'Signing material already exists. Refusing to replace the permanent identity.'
  }
  if (-not (Test-Path -LiteralPath (Join-Path $JavaHome 'bin/keytool.exe'))) {
    throw 'Pass -JavaHome pointing to a JDK with keytool.'
  }
  New-Item -ItemType Directory -Force -Path $signingRoot | Out-Null
  $randomBytes = [byte[]]::new(32)
  [System.Security.Cryptography.RandomNumberGenerator]::Fill($randomBytes)
  $password = [Convert]::ToBase64String($randomBytes)
  $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
  ConvertFrom-SecureString $securePassword | Set-Content -LiteralPath $passwordPath -NoNewline
} else {
  if (-not (Test-Path -LiteralPath $passwordPath)) { throw 'Initialize the signing identity first.' }
  $securePassword = Get-Content -Raw -LiteralPath $passwordPath | ConvertTo-SecureString
  $password = [System.Net.NetworkCredential]::new('', $securePassword).Password
}

try {
  $env:IMMUCH_SIGNING_PASSWORD = $password
  switch ($Action) {
    'Initialize' {
      & (Join-Path $JavaHome 'bin/keytool.exe') -genkeypair -alias tvtest -keyalg RSA -keysize 3072 -validity 10950 -storetype PKCS12 -keystore $keyPath -storepass:env IMMUCH_SIGNING_PASSWORD -keypass:env IMMUCH_SIGNING_PASSWORD -dname 'CN=Immuch Android TV, O=Personal Development' -noprompt
      if ($LASTEXITCODE -ne 0) { throw 'Key generation failed. Do not discard or replace existing material automatically.' }
      & (Join-Path $JavaHome 'bin/keytool.exe') -exportcert -alias tvtest -keystore $keyPath -storepass:env IMMUCH_SIGNING_PASSWORD -file (Join-Path $signingRoot 'signer.der')
      if ($LASTEXITCODE -ne 0) { throw 'Certificate export failed.' }
      Get-FileHash -LiteralPath (Join-Path $signingRoot 'signer.der') -Algorithm SHA256
      Write-Output 'Permanent key created. Password is protected for this Windows user; private files are ignored by Git.'
    }
    'Sign' {
      if (-not $Apk -or -not $OutputApk) { throw 'Pass -Apk and -OutputApk.' }
      if ([IO.Path]::GetFullPath($Apk) -eq [IO.Path]::GetFullPath($OutputApk)) { throw 'Use a separate output file.' }
      $java = Join-Path $JavaHome 'bin/java.exe'
      $signer = Join-Path $BuildTools 'lib/apksigner.jar'
      & $java -jar $signer sign --ks $keyPath --ks-key-alias tvtest --ks-pass env:IMMUCH_SIGNING_PASSWORD --key-pass env:IMMUCH_SIGNING_PASSWORD --out $OutputApk $Apk
      if ($LASTEXITCODE -ne 0) { throw 'APK signing failed.' }
      & $java -jar $signer verify --verbose --print-certs $OutputApk
      if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
      Get-FileHash -LiteralPath $OutputApk -Algorithm SHA256
    }
    'CopyKeystoreSecret' {
      [Convert]::ToBase64String([IO.File]::ReadAllBytes($keyPath)) | Set-Clipboard
      Write-Output 'Keystore copied to clipboard for TV_TEST_KEYSTORE_BASE64. Do not paste it into chat, commits or comments.'
    }
    'CopyPasswordSecret' {
      Set-Clipboard -Value $password
      Write-Output 'Password copied to clipboard for TV_TEST_KEYSTORE_PASSWORD. Do not paste it into chat, commits or comments.'
    }
  }
} finally {
  Remove-Item Env:IMMUCH_SIGNING_PASSWORD -ErrorAction SilentlyContinue
  $password = $null
}
