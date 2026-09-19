#=============================================================================
#  check_syntax.tcl -- lightweight sanity check for the Tcl in this repo
#
#  Innovus commands (streamOut, loadViolationReport, ...) obviously cannot run
#  in a plain tclsh, so this does not source anything. It checks that every
#  file is syntactically complete Tcl and that the procs we advertise parse.
#
#  Usage: tclsh .github/scripts/check_syntax.tcl
#=============================================================================

set root [file normalize [file join [file dirname [info script]] .. ..]]

set files {}
foreach pattern {*.tcl tcl/*.tcl examples/*.tcl} {
    foreach f [lsort [glob -nocomplain -directory $root $pattern]] {
        lappend files $f
    }
}

if {[llength $files] == 0} {
    puts "no Tcl files found under $root"
    exit 1
}

set failed 0
foreach f $files {
    set name [string range $f [expr {[string length $root] + 1}] end]
    set fh [open $f r]
    set body [read $fh]
    close $fh

    if {![info complete $body]} {
        puts "FAIL  $name -- unbalanced braces, brackets or quotes"
        incr failed
        continue
    }
    puts "ok    $name"
}

# The library must define the entry points the README documents.
set common ""
foreach part {pvs_common.tcl pvs_drc.tcl pvs_lvs.tcl} {
    set fh [open [file join $root tcl $part] r]
    append common [read $fh]
    close $fh
}

foreach entry {pvs_drc pvs_lvs pvs_run pvs_help} {
    if {![regexp "interp alias \\{\\} $entry " $common]} {
        puts "FAIL  entry point '$entry' is not exposed"
        incr failed
    }
}

if {$failed} {
    puts "\n$failed check(s) failed"
    exit 1
}
puts "\nall checks passed"
exit 0
