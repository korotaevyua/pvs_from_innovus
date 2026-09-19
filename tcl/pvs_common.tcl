#=============================================================================
#  pvs_common.tcl -- shared helpers for the pvs_from_innovus flow
#
#  Part of https://github.com/korotaevyua/pvs_from_innovus
#  Written for Tcl 8.4+ so it works in every Innovus shell.
#=============================================================================

namespace eval ::pvs {
    variable version "1.1.0"
    variable defaults

    # Session-wide defaults. Override them in your setup file, e.g.
    #     set ::pvs::defaults(rules) /pdk/.../drc.rul
    if {![info exists defaults(cpus)]} {
        array set defaults {
            rules   ""
            gds     ""
            cdl     ""
            stream  ""
            top     ""
            cpus    8
            drc_dir drc
            lvs_dir lvs
        }
    }
}

#-----------------------------------------------------------------------------
# Messaging
#-----------------------------------------------------------------------------
proc ::pvs::msg {text} {
    puts "-- \[PVS\] $text"
}

proc ::pvs::warn {text} {
    puts "** \[PVS\] WARNING: $text"
}

proc ::pvs::die {text} {
    return -code error "\[PVS\] $text"
}

#-----------------------------------------------------------------------------
# ::pvs::parse_options -- tiny option parser
#
#   spec    list of {name kind default}; kind is "value" or "flag"
#   arglist the raw args
#   optVar  name of an array in the caller that receives the result
#-----------------------------------------------------------------------------
proc ::pvs::parse_options {spec arglist optVar} {
    upvar 1 $optVar opt

    set names {}
    foreach item $spec {
        set name [lindex $item 0]
        set kind($name) [lindex $item 1]
        set opt($name) [lindex $item 2]
        lappend names $name
    }

    set n [llength $arglist]
    for {set i 0} {$i < $n} {incr i} {
        set token [lindex $arglist $i]

        if {[string equal $token "-help"] || [string equal $token "-h"]} {
            set opt(help) 1
            continue
        }
        if {![string match {-*} $token]} {
            ::pvs::die "unexpected argument \"$token\" -- options start with '-'"
        }

        set name [string range $token 1 end]
        if {[lsearch -exact $names $name] < 0} {
            ::pvs::die "unknown option \"$token\"\n            valid options: -[join $names { -}]"
        }
        if {[string equal $kind($name) "flag"]} {
            set opt($name) 1
            continue
        }

        incr i
        if {$i >= $n} {
            ::pvs::die "option \"$token\" needs a value"
        }
        set opt($name) [lindex $arglist $i]
    }
}

#-----------------------------------------------------------------------------
# Environment helpers
#-----------------------------------------------------------------------------

# Absolute path of an executable, or "" when it is not in PATH.
proc ::pvs::which {name} {
    if {[catch {exec which $name} path]} {
        return ""
    }
    return [string trim $path]
}

# Absolute path, so the value survives the cd into the run directory.
proc ::pvs::abs {path} {
    if {[string equal $path ""]} {
        return ""
    }
    return [file normalize $path]
}

# Top cell of the design currently loaded in Innovus ("" when unknown).
proc ::pvs::design_top {} {
    if {[catch {dbGet top.name} name]} {
        return ""
    }
    if {[string equal $name "0x0"]} {
        return ""
    }
    return $name
}

# Evaluate a script with the CWD set to dir, then always come back.
proc ::pvs::in_dir {dir script} {
    file mkdir $dir
    set origin [pwd]
    cd $dir
    set code [catch {uplevel 1 $script} result]
    cd $origin
    if {$code} {
        return -code $code $result
    }
    return $result
}

#-----------------------------------------------------------------------------
# ::pvs::invoke -- run the pvs binary, tee-ing the output to a log file
#
#   Returns 1 on a clean exit, 0 when pvs exits non-zero (which many decks do
#   simply because violations were found -- that is not a reason to abort).
#-----------------------------------------------------------------------------
proc ::pvs::invoke {cmdargs {logfile ""} {dryrun 0}} {
    ::pvs::msg "cmd: pvs [join $cmdargs { }]"
    ::pvs::msg "cwd: [pwd]"
    if {$dryrun} {
        ::pvs::msg "dry run -- nothing was executed"
        return 1
    }

    set bin [::pvs::which pvs]
    if {[string equal $bin ""]} {
        ::pvs::die "'pvs' was not found in PATH.\n            Source your Cadence PVS setup before starting Innovus."
    }

    set cmd [list exec $bin]
    foreach a $cmdargs {
        lappend cmd $a
    }
    if {![string equal $logfile ""]} {
        lappend cmd |& tee $logfile
    }
    lappend cmd >&@stdout

    if {[catch {eval $cmd} result]} {
        ::pvs::warn "pvs exited with an error: $result"
        if {![string equal $logfile ""]} {
            ::pvs::warn "see [file join [pwd] $logfile] for the full transcript"
        }
        return 0
    }
    return 1
}

#-----------------------------------------------------------------------------
# ::pvs::load_report -- pull a PVS result database into the Innovus GUI
#-----------------------------------------------------------------------------
proc ::pvs::load_report {file} {
    if {![file exists $file]} {
        ::pvs::warn "result database \"$file\" was not produced -- check the run log"
        return 0
    }

    catch {clearDrc}
    loadViolationReport -type PVS -filename $file
    ::pvs::msg "loaded [file tail $file]"

    if {[catch {win}]} {
        ::pvs::msg "GUI is not up -- run 'win ; violationBrowser' to inspect the markers"
        return 1
    }
    catch {violationBrowser}
    return 1
}

# First matching result database inside dir, or "".
proc ::pvs::find_report {dir preferred pattern} {
    set direct [file join $dir $preferred]
    if {[file exists $direct]} {
        return $direct
    }
    set hits [lsort [glob -nocomplain -directory $dir $pattern]]
    if {[llength $hits] == 0} {
        return ""
    }
    if {[llength $hits] > 1} {
        ::pvs::warn "several result databases in $dir -- using [file tail [lindex $hits 0]]"
    }
    return [lindex $hits 0]
}

#-----------------------------------------------------------------------------
# ::pvs::run -- escape hatch: run pvs with hand-written switches
#
#   pvs_run -dir sigoff_drc -- -dp 32 -drc my_deck.rul
#-----------------------------------------------------------------------------
proc ::pvs::run {args} {
    set sep [lsearch -exact $args "--"]
    if {$sep < 0} {
        ::pvs::die "usage: pvs_run ?-dir <run_dir>? ?-log <file>? -- <pvs switches>"
    }

    set head [lrange $args 0 [expr {$sep - 1}]]
    set tail [lrange $args [expr {$sep + 1}] end]
    if {[llength $tail] == 0} {
        ::pvs::die "no pvs switches given after '--'"
    }

    set spec [list \
        [list dir    value "."] \
        [list log    value "pvs_run.log"] \
        [list dryrun flag  0]]
    ::pvs::parse_options $spec $head opt

    set switches {}
    foreach a $tail {
        lappend switches $a
    }

    return [::pvs::in_dir $opt(dir) {
        ::pvs::invoke $switches $opt(log) $opt(dryrun)
    }]
}

interp alias {} pvs_run {} ::pvs::run

#-----------------------------------------------------------------------------
# ::pvs::help -- one screen of usage
#-----------------------------------------------------------------------------
proc ::pvs::help {} {
    variable version
    puts "
pvs_from_innovus $version -- run Cadence PVS from the Innovus command line

  pvs_drc  -rules <deck> ?options?    signoff DRC, results loaded in the GUI
  pvs_lvs  -rules <deck> -cdl <file>  LVS against a source netlist
  pvs_run  ?-dir d? -- <switches>     any other pvs invocation
  pvs_help                            this message

Common options
  -rules <path>    rule deck handed to pvs            (required)
  -gds <path>      layout; streamed out when missing
  -stream <path>   Tcl script that writes that layout
  -top <cell>      top cell, passed to pvs as -top_cell
  -cpus <n>        value for 'pvs -dp'                (default $::pvs::defaults(cpus))
  -dir <path>      run directory                      (drc / lvs)
  -extra {...}     extra switches appended verbatim
  -dryrun          print the command without running it

Defaults live in ::pvs::defaults -- see examples/pvs_defaults.tcl
"
}

interp alias {} pvs_help {} ::pvs::help
