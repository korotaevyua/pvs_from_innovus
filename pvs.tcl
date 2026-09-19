#=============================================================================
#  pvs.tcl -- entry point for pvs_from_innovus
#
#  Source this once from your Innovus session (or from your .innovusrc / setup
#  script) and you get:
#
#      pvs_drc  -rules <deck> ?options?
#      pvs_lvs  -rules <deck> -cdl <netlist> ?options?
#      pvs_run  ?-dir <d>? -- <raw pvs switches>
#      pvs_help
#
#  https://github.com/korotaevyua/pvs_from_innovus
#=============================================================================

namespace eval ::pvs {
    variable home [file dirname [file normalize [info script]]]
}

foreach __pvs_part {pvs_common.tcl pvs_drc.tcl pvs_lvs.tcl} {
    set __pvs_file [file join $::pvs::home tcl $__pvs_part]
    if {![file exists $__pvs_file]} {
        return -code error "\[PVS\] cannot find $__pvs_file -- keep pvs.tcl next to the tcl/ directory"
    }
    source $__pvs_file
}
unset __pvs_part __pvs_file

# Optional per-site defaults: drop a pvs_defaults.tcl next to pvs.tcl and it is
# picked up automatically. See examples/pvs_defaults.tcl for a template.
if {[file exists [file join $::pvs::home pvs_defaults.tcl]]} {
    source [file join $::pvs::home pvs_defaults.tcl]
    ::pvs::msg "loaded site defaults from pvs_defaults.tcl"
}

::pvs::msg "pvs_from_innovus $::pvs::version ready -- type 'pvs_help' for usage"
