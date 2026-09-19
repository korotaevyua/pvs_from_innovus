#=============================================================================
#  stream_out.tcl -- example of the script pvs_drc sources when the GDS is
#  missing. Adapt the map file, units and merge list to your PDK, then point
#  ::pvs::defaults(stream) (or -stream) at your copy.
#=============================================================================

set gds_out  [file normalize ./gds/top_merged.gds]
set map_file /pdk/tsmcN7/streamOut.map
set lib_name DesignLib

# Standard cell / IP / IO GDS that has to be merged into the stream-out.
set merge_gds [list \
    /pdk/tsmcN7/gds/stdcells.gds \
    /pdk/tsmcN7/gds/io.gds \
    ./macros/sram_512x64.gds]

file mkdir [file dirname $gds_out]

streamOut $gds_out \
    -mapFile $map_file \
    -libName $lib_name \
    -merge $merge_gds \
    -units 2000 \
    -mode ALL \
    -uniquifyCellNames

puts "-- \[PVS\] streamed out $gds_out"
