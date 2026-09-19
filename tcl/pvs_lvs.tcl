#=============================================================================
#  pvs_lvs.tcl -- LVS with Cadence PVS, driven from the Innovus shell
#
#  Part of https://github.com/korotaevyua/pvs_from_innovus
#
#  PVS switch names differ a little between releases and foundry kits, so this
#  proc only builds the switches it is sure about and lets you append the rest
#  with -extra. Anything really exotic goes through pvs_run.
#=============================================================================

#-----------------------------------------------------------------------------
# pvs_lvs -- stream out (if needed), run PVS LVS, report where the results are
#
#   pvs_lvs -rules /pdk/pvs/lvs.rul -cdl netlist/top.cdl
#-----------------------------------------------------------------------------
proc ::pvs::lvs {args} {
    variable defaults

    set spec [list \
        [list rules  value $defaults(rules)] \
        [list cdl    value $defaults(cdl)] \
        [list gds    value $defaults(gds)] \
        [list stream value $defaults(stream)] \
        [list top    value $defaults(top)] \
        [list cpus   value $defaults(cpus)] \
        [list dir    value $defaults(lvs_dir)] \
        [list log    value "pvs_lvs.log"] \
        [list extra  value ""] \
        [list dryrun flag  0] \
        [list help   flag  0]]

    ::pvs::parse_options $spec $args opt
    if {$opt(help)} {
        ::pvs::help
        return
    }

    #-- inputs ---------------------------------------------------------------
    if {[string equal $opt(rules) ""]} {
        ::pvs::die "no rule deck given.\n            Use 'pvs_lvs -rules <deck> -cdl <netlist>'"
    }
    set rules [::pvs::abs $opt(rules)]
    if {![file exists $rules]} {
        ::pvs::die "rule deck \"$rules\" does not exist"
    }

    set cdl [::pvs::abs $opt(cdl)]
    if {![string equal $cdl ""] && ![file exists $cdl]} {
        ::pvs::die "source netlist \"$cdl\" does not exist"
    }

    set gds    [::pvs::abs $opt(gds)]
    set stream [::pvs::abs $opt(stream)]
    if {![string equal $gds ""] && ![file exists $gds]} {
        if {[string equal $stream ""]} {
            ::pvs::die "layout \"$gds\" is missing and no -stream script was given"
        }
        ::pvs::msg "layout missing -- sourcing [file tail $stream]"
        uplevel #0 [list source $stream]
        if {![file exists $gds]} {
            ::pvs::die "\"$gds\" still missing after running [file tail $stream]"
        }
    }

    set top $opt(top)
    if {[string equal $top ""]} {
        set top [::pvs::design_top]
    }

    #-- command line ---------------------------------------------------------
    set cmd [list -dp $opt(cpus) -lvs $rules]
    if {![string equal $top ""]} {
        lappend cmd -top_cell $top
    }
    if {![string equal $cdl ""]} {
        lappend cmd -source_cdl $cdl
    }
    foreach a $opt(extra) {
        lappend cmd $a
    }

    ::pvs::msg "LVS deck   : $rules"
    if {![string equal $cdl ""]} { ::pvs::msg "source cdl : $cdl" }
    if {![string equal $top ""]} { ::pvs::msg "top cell   : $top" }
    ::pvs::msg "run dir    : $opt(dir)"

    set ok [::pvs::in_dir $opt(dir) {
        ::pvs::invoke $cmd $opt(log) $opt(dryrun)
    }]

    if {!$opt(dryrun)} {
        ::pvs::msg "LVS finished -- reports are in [file normalize $opt(dir)]"
    }
    return $ok
}

interp alias {} pvs_lvs {} ::pvs::lvs
