# AGENTS.md: AI Collaborator & Maintainer Guidelines

Welcome, AI coding agent (Codex, Antigravity, Claude, Copilot, etc.)! This document defines the architectural rules, security boundaries, coding conventions, and pull request review expectations for this repository.

---

## 1. Project Mission & Architecture Philosophy

**Open Presensi** is an open-source, offline-resilient attendance and community management system tailored for small schools, local churches, and grassroots organizations across Indonesia.

### Core Architectural Decisions
1. **Backend**: Python 3.11+ using **FastAPI** + **SQLAlchemy** + **PostgreSQL 16**.
2. **Client**: Cross-platform **Flutter 3.x** utilizing the **GetX** reactive state management pattern.
3. **Deployment**: Zero-friction developer setup via `docker-compose up -d`.
4. **Domain Agnosticism**:
   * Entities are structured as: `Organization` -> `Group` (Kelas / Rayon) -> `Member` (Siswa / Jemaat) -> `AttendanceRecord`.
   * Never hardcode school-only or church-only concepts into core models. Keep domain labels localized via profile/preset templates.
5. **Offline-First Attendance**:
   * The Flutter client must support scanning/recording attendance even with zero connectivity, queuing records locally in offline storage, and syncing idempotently when a network connection is detected.

---

## 2. Invariants & Security Guardrails

Whenever generating code or reviewing pull requests, strictly verify the following:

- [ ] **No PII or Secret Leaks**: Never commit real student/jemaat names, NUPTK, phone numbers, Google Drive service account keys, or production passwords. All seed data must use dummy Indonesian identities (e.g., *SMA Nusantara* or *Jemaat Kasih Karunia*).
- [ ] **Device Binding & Anti-Cheat Invariants**: In staff/teacher attendance modes, verify hardware `device_id` consistency to prevent credential-sharing.
- [ ] **Timezone Rigor**: All attendance logs and date rollups default to Western/Central Indonesian time (`Asia/Jakarta` or `Asia/Makassar` / WITA). Never compare naive dates without explicit timezone context.
- [ ] **PowerShell File Safety (for Windows maintainers)**: Never use regex `-replace` across multiline code files. Use surgical string edits.

---

## 3. Pull Request Review Automation (Codex Bot)

This repository operates an automated PR review workflow via GitHub Actions (`.github/workflows/codex-pr-review.yml`).

### Review Criteria
When reviewing a PR, automated agents check for:
1. **Code Hygiene & Formatting**: Conformity with PEP 8 (Python) and Flutter/Dart analysis rules.
2. **Database Migrations & Backward Compatibility**: Any schema alterations must include corresponding Alembic/SQL scripts with non-breaking defaults.
3. **Data Sanitization**: Verification that dummy seeders are updated if new mandatory fields are introduced.
4. **Error Handling**: Graceful error responses with localized user messages.

---

## 4. Good First Issue Scope for Community Contributors

If you are an agent tasked with onboarding or creating beginner issues, label them `good first issue` under these modules:
- Additional PDF/Excel attendance report export styling.
- Telegram or Discord notification adapter alternative to WhatsApp.
- QR Code sticker/card generator layout presets.
- Translation expansions (Javanese, Sundanese, Batak, Kupang Malay localizations).
