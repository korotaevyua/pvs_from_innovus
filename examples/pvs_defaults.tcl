#=============================================================================
#  pvs_defaults.tcl -- template for per-project / per-PDK defaults
#
#  Copy this file next to pvs.tcl (it is sourced automatically) or source it
#  yourself from your Innovus setup script. Every value here is just the
#  default for the matching pvs_drc / pvs_lvs switch, so the command line
#  always wins.
#=============================================================================

# Rule decks shipped with your PDK.
set ::pvs::defaults(rules) /pdk/tsmcN7/pvs/drc/drc_signoff.rul

# Layout that the decks expect. Leave empty if the deck points at the GDS
# itself -- the existence check is then skipped.
set ::pvs::defaults(gds) [file normalize ./gds/top_merged.gds]

# Script that produces the layout above when it is missing. Usually your
# streamOut wrapper with the right map file and merge list.
set ::pvs::defaults(stream) [file normalize ./scripts/stream_out.tcl]

# Source netlist for LVS.
set ::pvs::defaults(cdl) [file normalize ./netlist/top.cdl]

# How many cores 'pvs -dp' may use.
set ::pvs::defaults(cpus) 16

# Run directories, relative to wherever Innovus was started.
set ::pvs::defaults(drc_dir) reports/pvs_drc
set ::pvs::defaults(lvs_dir) reports/pvs_lvs

# Top cell; empty means "ask the open design".
set ::pvs::defaults(top) ""
