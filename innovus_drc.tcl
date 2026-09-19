#=============================================================================
#  innovus_drc.tcl -- compatibility shim
#
#  The original single-proc version of this repo lived here. Everything now
#  sits in pvs.tcl + tcl/, and pvs_drc takes real arguments instead of the
#  YOUR_GDS_NAME / RULE_DECK placeholders you used to edit by hand:
#
#      source innovus_drc.tcl
#      pvs_drc -rules /pdk/pvs/drc.rul -gds top_merged.gds \
#              -stream scripts/stream_out.tcl -cpus 16
#
#  Sourcing this file keeps old setup scripts working.
#=============================================================================

source [file join [file dirname [file normalize [info script]]] pvs.tcl]
