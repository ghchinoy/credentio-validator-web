// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import { CredentioValidator, type ProvenanceReport } from '@ghchinoy/credentio-wasm';

let validatorPromise: Promise<CredentioValidator> | null = null;

/**
 * Initializes or returns the shared in-browser CredentioValidator instance.
 */
export async function getValidator(): Promise<CredentioValidator> {
  if (!validatorPromise) {
    validatorPromise = (async () => {
      // Dynamic import of Emscripten glue with runtime URL
      const wasmJsUrl = '/wasm/credentio.js';
      // @ts-ignore
      const glue = await import(/* @vite-ignore */ wasmJsUrl);
      const factory = glue.default || glue.createCredentioModule || glue;

      return CredentioValidator.create({
        skipTrustChecks: true,
        moduleFactory: factory,
        locateFile: (path: string) => {
          if (path.endsWith('.wasm')) {
            return '/wasm/credentio.wasm';
          }
          return '/wasm/' + path;
        }
      });
    })();
  }
  return validatorPromise;
}

/**
 * Validates a user uploaded media File or Blob in-browser with zero network egress.
 */
export async function validateUserFile(file: File): Promise<ProvenanceReport> {
  const validator = await getValidator();
  return validator.validateBlob(file);
}
