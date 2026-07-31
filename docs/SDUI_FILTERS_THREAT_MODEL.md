# 🛡️ Server-Driven Filters (Phase 0) - Threat Model & Security Design

## 1. Overview
Server-Driven Filters allow dynamic control over mobile UI tabs, names, icons, colors, and order without APK rebuilds. Because dynamic UI configurations can be exploited if intercepted or altered, this document establishes a zero-trust threat model and enforcement rules.

---

## 2. Threat Vector Matrix

| Threat | Attack Vector | Prevention / Mitigation Mechanism |
| :--- | :--- | :--- |
| **Man-In-The-Middle (MITM) Tampering** | Attacker modifies filter JSON payload in transit over HTTP/HTTPS. | **Ed25519 Asymmetric Digital Signature**: Every payload is signed with an Ed25519 private key and verified on client using public key. |
| **Configuration Rollback Attack** | Attacker injects a valid, signed old configuration payload with disabled filters. | **Monotonic `configVersion` Guard**: Client rejects any payload whose `configVersion` is less than or equal to the locally cached valid `configVersion`. |
| **Expired Config / Replay Attack** | Attacker replays a stale signed config payload after feature deprecation. | **`expiresAt` Validation**: Client rejects configurations where `currentTime > expiresAt`. |
| **Unsupported App Version Incompatibility** | Server sends filter configuration using schema features not supported by old APK. | **`minAppVersion` SemVer Check**: Client rejects config if its app version < `minAppVersion`. |
| **Malicious Action / Icon Injection** | Server or attacker passes unexpected action IDs or invalid icons. | **Allowlist Execution Engine**: Icons, colors, and actions are validated against explicit local allowlists. Unknown values default to safe fallbacks. |
| **Corrupt / Poisoned Local Cache** | Local storage is modified or corrupted by malware or storage failure. | **On-Read Signature Verification**: Payload + Signature are cached together. On read, signature is re-verified before use. Fallback to hardcoded defaults if corrupt. |

---

## 3. Canonical JSON Normalization Standard
To guarantee deterministic Ed25519 signature computation:
1. Object keys are sorted lexicographically in Unicode code-point order.
2. No unnecessary whitespace, indentation, or newlines (compact JSON).
3. Numbers and booleans maintain standard JSON formatting.
4. Strings are encoded as UTF-8 bytes.

---

## 4. Client Fallback Pipeline
```
[Fetch Network Config (with ETag)]
       │
       ├─► 304 Not Modified ──► Load Cached Config (Re-verify Signature)
       │
       ├─► 200 OK ──► Verify Ed25519 Signature
       │                  │
       │                  ├── Valid ──► Check configVersion > cached.configVersion ──► Save Cache & Apply
       │                  └── Invalid/Stale ──► Reject ──► Fallback to Cache / Hardcoded
       │
       └─► Network Error / Offline ──► Load Cached Config (Re-verify Signature) ──► Hardcoded Fallback
```
