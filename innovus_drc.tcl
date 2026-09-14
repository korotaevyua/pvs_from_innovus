proc pvs_drc {} {
    if {![file exists out/asterix.GDSout.merged.gds.gz]} {
        source YOUR_SCRIPT_TO_STREAM_OUT_MERGED_GDS.tcl
    }
    mkdir -p drc ; cd drc
    exec pvs -dp 16 -drc RULE_DECK
    clearDrc
    cd ..
    loadViolationReport -type PVS -filename drc/DRC_RES.db
    win
    violationBrowser
}
