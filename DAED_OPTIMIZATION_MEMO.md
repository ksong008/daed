# DAEd Optimization Memo

Branch: personal/stable
Repo: /Users/Shaka/New project/daed

## Scope

This memo records the daed-side changes we applied during the current optimization cycle.
It focuses on:

- submodule alignment against updated `dae-wing` / `dae-core` chains
- CI / action-based verification points
- web UI fixes that affect node creation or editing behavior

It does not attempt to restate every historical upstream web change already present in the repository.

## personal/stable line

### 1. Align daed with latest personal/stable backend chain

Commit:
- `9650e68a` `chore(submodule): bump dae-wing personal stable`

What changed:
- updated the `wing` submodule so `daed personal/stable` points to the latest `dae-wing personal/stable`
- this in turn pulled in the latest `dae-core personal/stable` chain for integration verification

Observed chain at the time:
- `daed@9650e68a`
- `dae-wing@6c51b65`
- `dae-core@a7a96d1`

Verification:
- `daed` workflow run `#48` passed

Tag:
- `daedmod`

### 2. Improve manual VLESS TLS form handling

Local commit:
- `b96f3325` `Improve VLESS TLS fp and ALPN form handling`

Status:
- committed locally on `personal/stable`
- not yet pushed to `origin/personal/stable`

Problem background:
- manually created `VLESS + security=tls` nodes in daed did not expose `fp`
- users could paste working links containing `fp` and `alpn`, but the form UI could not fully recreate them
- `alpn` was available only as a free-text input, which made common values less convenient to use

Changes:
- allow `fingerprint` to appear for `VLESS + security=tls` as well as `reality`
- write `fp` back into generated VLESS links for both `tls` and `reality`
- replace ALPN free-text-only behavior with:
  - common ALPN preset dropdown
  - custom ALPN fallback input for non-standard combinations

Files:
- `apps/web/src/components/ConfigureNodeFormModal/V2rayForm.tsx`
- `apps/web/src/components/ConfigureNodeFormModal/protocols/complex.ts`

Notes:
- `dae-wing` did not require changes for this issue because it stores and emits raw node links
- this UI fix is specifically about manual node creation / editing in `daed`

Validation notes:
- attempted local TypeScript check
- repository already contains unrelated pre-existing TypeScript issues outside the modified files
- no new errors were observed in the touched files themselves during review

## olicesxcore/stable line

### 3. Align daed with olicesxcore backend chain

Commit:
- `9f051d30` `chore(submodule): align dae-wing olicesxcore stable`

What changed:
- updated `wing` on `olicesxcore/stable` to consume the synchronized `dae-wing olicesxcore/stable`
- intentionally did not bump `dae-core` to the personal/stable chain

Observed chain at the time:
- `daed@9f051d30`
- `dae-wing@4c9286f`
- `dae-core@d0367cbd1d23b23b6c7974a70fcb0313e154397e`

Verification:
- `daed` workflow run `#49` passed

Notes:
- this line was treated as a stable integration branch
- the goal was to bring in `dae-wing` runtime / reload / schema optimizations without changing the pinned `dae-core`

## Current summary

At the time of this memo:

- `personal/stable` already contains the latest personal backend submodule alignment
- `personal/stable` also has one additional local-only web UI fix commit:
  - `b96f3325`
- `olicesxcore/stable` has already been verified successfully after backend chain synchronization

## Follow-up candidates

- push `b96f3325` to `origin/personal/stable` if the VLESS TLS form fix should be shared
- optionally add dedicated UI or parser/generator regression tests for:
  - `VLESS + security=tls + fp`
  - `VLESS + security=tls + alpn`
  - `VLESS + flow=xtls-rprx-vision`
