# Changelog

## [2.0.0] - 2026-08-17

### Advanced (`advanced/`)

- **Hub & sub-tab navigation redesign** — CPU, Memory, Disks, Network and Services
  are now hub screens with capability-gated sub-tabs: CPU (Overview / Per-Core /
  History / GPU), Disks (Filesystems / Disk I/O), Network (Interfaces /
  Connections / IP / Wi-Fi / Ports), Services (Containers / VMs / Processes /
  Programs / Extended). Deep-link routes select a sub-tab; horizontal swipe
  switches bottom-nav branches.
- **Dynamic plugin detection** — `GET /api/4/pluginslist` gates home cards and
  hub sub-tabs on the plugins the server actually reports.
- **Server-driven alert colors** — bar colors resolve from the server's limits
  (`/api/4/all/limits`), falling back to the client's scale when none are exposed.
- **HTTP Basic auth** — optional username/password saved in Settings and sent as
  a preemptive `Authorization: Basic` header.
- **Extended processes** — new Extended sub-tab backed by
  `/api/4/processes/extended` (empty state when the server doesn't enable it).
- **New screens** — GPU, Folders and Programs (empty states when the host
  reports none).
- **Server metadata** — item units/descriptions
  (`/api/4/{plugin}/{item}/unit|description`) drive rate suffixes on disk I/O.
- **Misc** — server-version badge, CPU/MEM/LOAD quicklook strip, alerts clear
  menu (warnings/all), Docker & Sensors cards gated on their plugins, third-party
  notices narrowed to a logo-only attribution.

### Minimal (`minimal/`)

- **Capability-gated hubs** — Memory, Network and Services render through hubs
  that hide sub-tabs when the server lacks the plugin (`/api/4/pluginslist`).
- **Single-pane CPU and Disks** — CPU combines overview + history sparkline in
  one pane; Disks combines filesystems + disk I/O in one pane (no tabs).
- **HTTP Basic auth** — optional credentials added in the connect dialog and
  sent as a preemptive `Authorization: Basic` header.