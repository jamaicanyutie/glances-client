#!/usr/bin/env node
// Glances API capability tracker.
//
// Watches upstream nicolargo/glances for changes to the REST API surface used by
// this client and files a GitHub issue when a release changes it.
//
// Stateless: each run compares the two most recent stable upstream releases and
// creates one deduped issue per release pair (title = "Glances API change
// detected: <old> -> <new>").
//
// Surface tracked per release tag:
//   - __apiversion__ from glances/__init__.py        (4 -> 5 = critical)
//   - routes from docs/api/openapi.json              (path list, normalized)
//   - fields_description top-level keys per plugin    (the JSON keys the client parses)
//
// Env:
//   GH_TOKEN          required only for the issue-create/list steps
//   GITHUB_OUTPUT     optional; when set, writes status=<value>
//   UPSTREAM_REPO     optional; default nicolargo/glances

import fs from 'node:fs';

const UPSTREAM = process.env.UPSTREAM_REPO || 'nicolargo/glances';
const WATCHED_PLUGINS = ['cpu', 'mem', 'load', 'fs', 'diskio', 'network', 'containers', 'processcount'];
const ISSUE_PREFIX = 'Glances API change detected';
// Client model files that map to each watched plugin (for the impact section)
const CLIENT_MODELS = {
  cpu: 'lib/data/models/cpu_info.dart, lib/data/models/history_point.dart',
  mem: 'lib/data/models/mem_info.dart',
  load: 'lib/data/models/load_info.dart',
  fs: 'lib/data/models/fs_info.dart',
  diskio: 'lib/data/models/disk_io_info.dart',
  network: 'lib/data/models/network_info.dart',
  containers: 'lib/data/models/docker_container_info.dart',
  processcount: 'lib/data/models/process_count_info.dart',
};

const TARGET = {
  owner: process.env.GITHUB_REPOSITORY?.split('/')[0],
  repo: process.env.GITHUB_REPOSITORY?.split('/')[1],
};

function die(msg, code = 1) {
  console.error(`[api-tracker] ${msg}`);
  process.exit(code);
}

async function getRaw(ref, path) {
  const res = await fetch(`https://raw.githubusercontent.com/${UPSTREAM}/${ref}/${path}`, {
    headers: { 'User-Agent': 'glances-client-api-tracker' },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`raw ${ref} ${path} -> ${res.status}`);
  return res.text();
}

async function ghApi(path, opts = {}) {
  const headers = { 'User-Agent': 'glances-client-api-tracker', Accept: 'application/vnd.github+json' };
  if (process.env.GH_TOKEN) headers.Authorization = `Bearer ${process.env.GH_TOKEN}`;
  const res = await fetch(`https://api.github.com${path}`, { ...opts, headers });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`gh ${path} -> ${res.status}`);
  return res.json();
}

function extractApiversion(src) {
  const m = src?.match(/__apiversion__\s*=\s*['"]([^'"]+)['"]/);
  return m ? m[1] : null;
}

function extractVersion(src) {
  const m = src?.match(/__version__\s*=\s*["']([^"']+)["']/);
  return m ? m[1] : null;
}

function normalizeRoutes(openapiSrc) {
  if (!openapiSrc) return null;
  try {
    return Object.keys(JSON.parse(openapiSrc).paths || {})
      .map((p) => p.replace(/\{[^}]+\}/g, '{}'))
      .sort();
  } catch {
    return null;
  }
}

// Extract the top-level keys of `fields_description = { ... }` from a plugin
// module. Uses brace counting that is string-aware (handles multi-line dicts
// and descriptions containing quotes).
function extractFields(src) {
  if (!src) return null;
  const start = src.indexOf('fields_description = {');
  if (start === -1) return null;
  let i = start + 'fields_description = {'.length;
  let depth = 1;
  let inStr = null; // null | "'" | '"'
  let esc = false;
  const keys = [];
  while (i < src.length && depth > 0) {
    const ch = src[i];
    if (inStr) {
      if (esc) esc = false;
      else if (ch === '\\') esc = true;
      else if (ch === inStr) inStr = null;
    } else if (ch === "'" || ch === '"') {
      if (depth === 1) {
        // candidate top-level key: scan to closing quote; key only if ':' follows
        let k = i + 1;
        let key = '';
        let esc2 = false;
        while (k < src.length) {
          const c = src[k];
          if (esc2) { key += c; esc2 = false; }
          else if (c === '\\') esc2 = true;
          else if (c === ch) break;
          else key += c;
          k++;
        }
        if (src.slice(k + 1, k + 2) === ':') {
          if (!keys.includes(key)) keys.push(key);
          i = k + 1; // loop i++ lands on ':'
        } else {
          inStr = ch; // not a key; treat as regular string
        }
      } else {
        inStr = ch;
      }
    } else if (ch === '{') {
      depth++;
    } else if (ch === '}') {
      depth--;
    }
    i++;
  }
  return keys.sort();
}

async function manifest(tag) {
  const init = await getRaw(tag, 'glances/__init__.py');
  const openapi = await getRaw(tag, 'docs/api/openapi.json');
  const plugins = {};
  for (const p of WATCHED_PLUGINS) {
    plugins[p] = extractFields(await getRaw(tag, `glances/plugins/${p}/__init__.py`));
  }
  return {
    tag,
    apiversion: extractApiversion(init),
    version: extractVersion(init),
    routes: normalizeRoutes(openapi),
    plugins,
  };
}

function diff(oldM, newM) {
  const notes = [];
  if (oldM.apiversion !== newM.apiversion) {
    notes.push(
      `- **API version**: \`${oldM.apiversion}\` -> \`${newM.apiversion}\` — **critical**: ` +
        'the entire endpoint/field surface changes (v4 clients are incompatible).',
    );
  }
  const addedR = newM.routes ? newM.routes.filter((r) => !(oldM.routes || []).includes(r)) : [];
  const removedR = oldM.routes ? oldM.routes.filter((r) => !(newM.routes || []).includes(r)) : [];
  if (addedR.length) notes.push(`- **Routes added (${addedR.length})**:\n  ${addedR.map((r) => `\`${r}\``).join(', ')}`);
  if (removedR.length) notes.push(`- **Routes removed (${removedR.length})**:\n  ${removedR.map((r) => `\`${r}\``).join(', ')}`);
  for (const p of WATCHED_PLUGINS) {
    const o = oldM.plugins[p];
    const n = newM.plugins[p];
    if (o !== null && n === null) {
      notes.push(`- **Plugin \`${p}\`**: \`fields_description\` no longer parseable (plugin renamed/removed?)`);
      continue;
    }
    if (o === null && n !== null) {
      notes.push(`- **Plugin \`${p}\`**: newly parseable fields`);
      continue;
    }
    if (o === null && n === null) continue;
    const added = n.filter((f) => !o.includes(f));
    const removed = o.filter((f) => !n.includes(f));
    if (added.length) notes.push(`- **\`${p}\` fields added**: \`${added.join('`, `')}\``);
    if (removed.length) notes.push(`- **\`${p}\` fields removed**: \`${removed.join('`, `')}\``);
  }
  return notes;
}

function setOutput(key, value) {
  if (process.env.GITHUB_OUTPUT) {
    fs.appendFileSync(process.env.GITHUB_OUTPUT, `${key}=${value}\n`);
  }
  console.log(`[api-tracker] ${key}=${value}`);
}

// ---------------------------------------------------------------------------

const rel = await ghApi(`/repos/${UPSTREAM}/releases?per_page=10`);
const stable = (rel || []).filter((r) => !r.draft && !r.prerelease);
if (stable.length < 2) {
  setOutput('status', 'only-one-release');
  process.exit(0);
}
const [latest, prev] = stable;

const newM = await manifest(latest.tag_name);
const oldM = await manifest(prev.tag_name);

const notes = diff(oldM, newM);
if (notes.length === 0) {
  setOutput('status', 'no-changes');
  process.exit(0);
}

// Impact mapping: which client models are affected
const touched = new Set();
for (const p of WATCHED_PLUGINS) {
  const o = oldM.plugins[p];
  const n = newM.plugins[p];
  if ((o || []).join() !== (n || []).join()) touched.add(p);
}
const impact = [...touched].map((p) => `- \`${p}\` -> ${CLIENT_MODELS[p]}`).join('\n');

const title = `${ISSUE_PREFIX}: ${oldM.tag} -> ${newM.tag}`;
const body = [
  `Upstream [Glances ${newM.tag}](https://github.com/${UPSTREAM}/releases/tag/${newM.tag}) ` +
    `(version \`${newM.version}\`, API \`v${newM.apiversion}\`) changes API capabilities used by this client.`,
  '',
  '## Changes',
  notes.join('\n'),
  '',
  '## Client impact',
  'The client pins the `/api/4` prefix in `lib/data/api/glances_repository.dart` and parses these fields:',
  impact,
  '',
  'Review the affected models and update the repository call sites if any removed/renamed fields are used.',
  '',
  'Release notes: ',
  latest.body ? latest.body.split('\n').slice(0, 25).join('\n') : latest.html_url,
].join('\n');

if (!TARGET.owner || !TARGET.repo) {
  // Local run: just print what would be filed.
  console.log(`[api-tracker] would file issue: ${title}`);
  console.log(body);
  setOutput('status', 'dry-run');
  process.exit(0);
}

if (!process.env.GH_TOKEN) die('GH_TOKEN required to file issues');

// Dedupe: skip if an issue for this exact release pair already exists (any state)
const existing = await ghApi(`/repos/${TARGET.owner}/${TARGET.repo}/issues?state=all&per_page=100`);
const dup = (existing || []).find((i) => i.title === title && !i.pull_request);
if (dup) {
  setOutput('status', 'already-reported');
  process.exit(0);
}

await ghApi(`/repos/${TARGET.owner}/${TARGET.repo}/issues`, {
  method: 'POST',
  body: JSON.stringify({ title, body }),
});
setOutput('status', 'issue-created');
