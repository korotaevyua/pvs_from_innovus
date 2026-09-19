# Contributing

Thanks for taking a look. This is a small flow helper, so the bar is simple: it should keep working in every Innovus shell, and it should never surprise anyone running signoff.

## Ground rules

- **Tcl 8.4 compatible.** No `{*}`, no `dict`, no `lassign` — Innovus shells are conservative. Use `eval`, arrays and `lindex`.
- **No hardcoded paths or PDK names** in `pvs.tcl` / `tcl/`. Anything site-specific belongs in `examples/pvs_defaults.tcl`.
- **Don't invent `pvs` switches.** Only pass switches you have actually run against a real deck; everything else goes through `-extra` or `pvs_run`.
- **Fail loudly and early.** Check that files exist and that `pvs` is on `PATH` before burning an hour of runtime.
- **Always come back.** Anything that `cd`s must restore the original directory, including on error — use `::pvs::in_dir`.

## Before opening a PR

```bash
# the same check CI runs: parses every Tcl file, no Innovus needed
tclsh .github/scripts/check_syntax.tcl
```

Then run it for real in an Innovus session — `-dryrun` shows the command line without spending a PVS license:

```tcl
source pvs.tcl
pvs_drc -rules /path/to/deck.rul -dryrun
```

Say in the PR which Innovus and PVS versions you tested on, and which foundry kit. Reports of what *doesn't* work on your kit are just as welcome as code.
