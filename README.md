<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Credentio Web Validator

> In-browser C2PA Content Credentials validator powered by [Google Credentio](https://mediaprovenance.googlesource.com/credentio) compiled to WebAssembly.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.7+-blue.svg)](https://www.typescriptlang.org/)
[![WebAssembly](https://img.shields.io/badge/WebAssembly-WASM-654FF0.svg)](https://webassembly.org/)
[![Firebase](https://img.shields.io/badge/Firebase-Hosting-FFA611.svg)](https://firebase.google.com/)

This repository contains the standalone client-side web application for validating C2PA media provenance locally in the browser with zero network transmission.

> **Disclaimer:** This project is an open-source community contribution and is not an officially supported Google product.

---

## Features

- **100% Client-Side:** Files are validated directly inside WebAssembly memory in your browser. Zero bytes are uploaded to remote servers.
- **Universal Browser Execution:** Uses single-threaded WebAssembly (`-sUSE_PTHREADS=0`), running across all modern desktop and mobile browsers without requiring special cross-origin isolation headers.
- **Format Support:** Validates JPEG, PNG, WebP, AVIF, HEIC, MP4, MP3, WAV, and PDF files containing C2PA JUMBF manifests.

---

## Local Development

### 1. Install Dependencies

```bash
npm install
```

### 2. Start Development Server

```bash
npm run dev
```

Open `http://localhost:3000` in your browser.

### 3. Build Production Bundle

```bash
npm run build
```

The static output is generated in `dist/`.

---

## Deploying to Firebase Hosting

This project is configured for Google Firebase Hosting. Anyone can deploy their own instance:

### Option A: Manual CLI Deploy

```bash
# 1. Install Firebase CLI (if not already installed):
npm install -g firebase-tools

# 2. Log in to your Firebase account:
firebase login

# 3. Build the application:
npm run build

# 4. Deploy to your Firebase project:
firebase deploy --only hosting --project <YOUR_FIREBASE_PROJECT_ID>
```

### Option B: Automated GitHub Actions Deploy

To enable automated deployment on pull requests and pushes to `main`, set the following secrets in your GitHub repository settings (**Settings → Secrets and variables → Actions**):

1. `FIREBASE_PROJECT_ID`: Your Firebase project ID (e.g. `my-c2pa-validator`).
2. `FIREBASE_SERVICE_ACCOUNT`: Service account JSON key with Firebase Hosting Admin permissions.

---

## License

This project is licensed under the **Apache 2.0 License**. See [LICENSE](LICENSE) for details.
