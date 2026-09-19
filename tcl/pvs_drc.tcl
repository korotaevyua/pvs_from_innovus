#=============================================================================
#  pvs_drc.tcl -- signoff DRC with Cadence PVS, driven from the Innovus shell
#
#  Part of https://github.com/korotaevyua/pvs_from_innovus
#=============================================================================

#-----------------------------------------------------------------------------
# pvs_drc -- stream out (if needed), run PVS DRC, load the markers in the GUI
#
#   pvs_drc -rules /pdk/pvs/drc.rul
#   pvs_drc -rules drc.rul -gds top.gds -stream scripts/stream_out.tcl -cpus 32
#-----------------------------------------------------------------------------
proc ::pvs::drc {args} {
    variable defaults

    set spec [list \
        [list rules  value $defaults(rules)] \
        [list gds    value $defaults(gds)] \
        [list stream value $defaults(stream)] \
        [list top    value $defaults(top)] \
        [list cpus   value $defaults(cpus)] \
        [list dir    value $defaults(drc_dir)] \
        [list db     value "DRC_RES.db"] \
        [list log    value "pvs_drc.log"] \
        [list extra  value ""] \
        [list noload flag  0] \
        [list dryrun flag  0] \
        [list help   flag  0]]

    ::pvs::parse_options $spec $args opt
    if {$opt(help)} {
        ::pvs::help
        return
    }

    #-- rule deck ------------------------------------------------------------
    if {[string equal $opt(rules) ""]} {
        ::pvs::die "no rule deck given.\n            Use 'pvs_drc -rules <deck>' or set ::pvs::defaults(rules)"
    }
    set rules [::pvs::abs $opt(rules)]
    if {![file exists $rules]} {
        ::pvs::die "rule deck \"$rules\" does not exist"
    }

    #-- layout ---------------------------------------------------------------
    set gds    [::pvs::abs $opt(gds)]
    set stream [::pvs::abs $opt(stream)]

    if {![string equal $gds ""] && ![file exists $gds]} {
        if {[string equal $stream ""]} {
            ::pvs::die "layout \"$gds\" is missing and no -stream script was given"
        }
        if {![file exists $stream]} {
            ::pvs::die "stream-out script \"$stream\" does not exist"
        }
        ::pvs::msg "layout missing -- sourcing [file tail $stream]"
        uplevel #0 [list source $stream]
        if {![file exists $gds]} {
            ::pvs::die "\"$gds\" still missing after running [file tail $stream]"
        }
    }

    #-- command line ---------------------------------------------------------
    # Only -dp and -drc are passed unconditionally: everything else about the
    # run (layout, top cell, output names) normally lives in the rule deck.
    # Add whatever your deck does not cover with -top / -extra.
    set cmd [list -dp $opt(cpus) -drc $rules]
    if {![string equal $opt(top) ""]} {
        lappend cmd -top_cell $opt(top)
    }
    foreach a $opt(extra) {
        lappend cmd $a
    }

    ::pvs::msg "DRC deck   : $rules"
    ::pvs::msg "design     : [::pvs::design_top]"
    ::pvs::msg "run dir    : $opt(dir)"

    set ok [::pvs::in_dir $opt(dir) {
        ::pvs::invoke $cmd $opt(log) $opt(dryrun)
    }]

    if {$opt(dryrun) || $opt(noload)} {
        return $ok
    }

    #-- results --------------------------------------------------------------
    set report [::pvs::find_report $opt(dir) $opt(db) "*.db"]
    if {[string equal $report ""]} {
        ::pvs::warn "no result database found in $opt(dir)"
        return 0
    }
    return [::pvs::load_report $report]
}

interp alias {} pvs_drc {} ::pvs::drc
