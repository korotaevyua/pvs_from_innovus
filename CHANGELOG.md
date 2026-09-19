# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.0] — 2026-09-19

### Added
- `pvs_lvs` — LVS runs against a source netlist, same option style as DRC.
- `pvs_run` — escape hatch that runs `pvs` with hand-written switches while
  still handling the run directory, logging and the `PATH` check.
- `pvs_help` and `-help` on every command.
- `-dryrun` to print the exact `pvs` command line without spending a license.
- Automatic tee of the full PVS transcript to a log file in the run directory.
- Site defaults via `::pvs::defaults`, auto-loaded from `pvs_defaults.tcl`.
- Examples for the defaults file and a stream-out script.
- README, MIT license, contributing guide, `.gitignore` and a CI syntax check.

### Changed
- `pvs_drc` takes real options (`-rules`, `-gds`, `-stream`, `-cpus`, `-dir`,
  …) instead of the `YOUR_GDS_NAME` / `RULE_DECK` placeholders that had to be
  edited in the source.
- Code split into `pvs.tcl` plus `tcl/pvs_*.tcl`; `innovus_drc.tcl` is now a
  shim that sources the new entry point, so old setup scripts keep working.
- Run directory is created with `file mkdir` rather than `exec mkdir -p`, and
  the original working directory is always restored, including on error.
- Missing rule decks, missing layouts and a missing `pvs` binary now fail with
  a clear message before anything is launched.
- The result database is located by name with a `*.db` fallback instead of
  being hardcoded to `DRC_RES.db`.

## [1.0.0]

### Added
- The original `pvs_drc` proc: stream out if needed, run `pvs -dp 16 -drc`,
  then `loadViolationReport` into the Innovus Violation Browser.
