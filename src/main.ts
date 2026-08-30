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

import { validateUserFile } from './validator.js';
import type { ProvenanceReport } from '@ghchinoy/credentio-wasm';

const dropzone = document.getElementById('dropzone') as HTMLDivElement;
const fileInput = document.getElementById('file-input') as HTMLInputElement;
const resultContainer = document.getElementById('result-container') as HTMLDivElement;

const filenameDisplay = document.getElementById('filename-display') as HTMLHeadingElement;
const mediaTypeDisplay = document.getElementById('media-type-display') as HTMLSpanElement;
const statusBadge = document.getElementById('status-badge') as HTMLSpanElement;
const metricTime = document.getElementById('metric-time') as HTMLSpanElement;
const metricEngine = document.getElementById('metric-engine') as HTMLSpanElement;
const metricGenerator = document.getElementById('metric-generator') as HTMLSpanElement;
const metricSigner = document.getElementById('metric-signer') as HTMLSpanElement;
const assertionList = document.getElementById('assertion-list') as HTMLDivElement;
const rawJson = document.getElementById('raw-json') as HTMLPreElement;

dropzone.addEventListener('click', () => fileInput.click());
dropzone.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' || e.key === ' ') {
    e.preventDefault();
    fileInput.click();
  }
});

['dragenter', 'dragover'].forEach((name) => {
  dropzone.addEventListener(name, (e) => {
    e.preventDefault();
    dropzone.classList.add('dragover');
  });
});

['dragleave', 'drop'].forEach((name) => {
  dropzone.addEventListener(name, (e) => {
    e.preventDefault();
    dropzone.classList.remove('dragover');
  });
});

dropzone.addEventListener('drop', (e) => {
  if (e.dataTransfer && e.dataTransfer.files.length > 0) {
    handleFile(e.dataTransfer.files[0]);
  }
});

fileInput.addEventListener('change', () => {
  if (fileInput.files && fileInput.files.length > 0) {
    handleFile(fileInput.files[0]);
  }
});

async function handleFile(file: File) {
  try {
    dropzone.querySelector('.drop-title')!.textContent = `Validating ${file.name}...`;

    const report = await validateUserFile(file);
    renderReport(file.name, report);
  } catch (err) {
    console.error('Validation error:', err);
    alert(`Validation failed: ${(err as Error)?.message || String(err)}`);
  } finally {
    dropzone.querySelector('.drop-title')!.textContent = 'Drop an image, video, audio, or PDF file here';
  }
}

function renderReport(filename: string, report: ProvenanceReport) {
  resultContainer.style.display = 'block';

  filenameDisplay.textContent = filename;
  mediaTypeDisplay.textContent = report.mediaType || 'application/octet-stream';

  statusBadge.className = `status-badge ${report.badge}`;
  statusBadge.textContent = report.badge.toUpperCase();

  metricTime.textContent = `${(report.elapsedSeconds * 1000).toFixed(2)} ms`;
  metricEngine.textContent = report.engineName || 'Credentio WASM';
  metricGenerator.textContent = report.primaryClaimGenerator || '—';
  metricSigner.textContent = report.primarySignerIssuer || '—';

  assertionList.innerHTML = '';
  if (report.activeManifest && report.activeManifest.assertions.length > 0) {
    report.activeManifest.assertions.forEach((a) => {
      const card = document.createElement('div');
      card.className = 'assertion-card';
      card.innerHTML = `
        <span class="assertion-kind">${a.kind}</span>
        <div class="assertion-label">${a.label}</div>
        ${a.summary ? `<div class="assertion-summary">${a.summary}</div>` : ''}
      `;
      assertionList.appendChild(card);
    });
  } else {
    assertionList.innerHTML = `<div style="color: var(--text-muted); font-size: 0.9rem;">No manifest assertions found in this asset.</div>`;
  }

  rawJson.textContent = JSON.stringify(report, null, 2);
}
