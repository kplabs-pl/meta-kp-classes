package require cmdline

set option {
    {ws.arg		""			"Work Space Path"}
    {pname.arg	""			"Project Name"}
    {rp.arg		""			"repo path"}
    {processor_ip.arg	""			"target processor"}
    {hdf.arg	""			"hardware Definition file"}
    {arch.arg	"64"			"32/64 bit architecture"}
    {yamlconf.arg	""			"Path to Config File"}
    {xlnx_scripts.arg ""  "Path to meta-xilinx-tools scripts"}
}
set usage "A script to generate and compile device-tree"
array set params [::cmdline::getoptions argv $option $usage]

source $params(xlnx_scripts)/base-hsi.tcl

puts "HDF file: $params(hdf)"

if { [catch {hsi set_repo_path $params(rp)} res] } {
    error "Failed to set repo path $params(rp)"
}

set hdf $params(hdf)

set pname "hw_platform"
puts "basename is: $pname"

set project "$params(ws)/$pname"
puts "project is: $project"
set_hw_design $project $hdf hdf

if {[catch {hsi create_sw_design $pname -os device_tree -proc $params(processor_ip)} res] } {
    error "create_sw_design failed for $pname"
}

if {[file exists $params(yamlconf)]} {
    set_properties $params(yamlconf)
}

if {[catch {hsi generate_target -dir $project} res]} {
    error "generate_target failed"
}

if { [catch {hsi close_hw_design [hsi current_hw_design]} res] } {
    error "Failed to close hw design [hsi current_hw_design]"
}
