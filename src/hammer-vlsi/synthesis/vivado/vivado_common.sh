#!/bin/bash
# Common parameters for Vivado invocation.
# Parses the command-line options passed to the including script.
# Required variables:
# - workdir_tag - see below

if [ -z "$workdir_tag" ]; then
    >&2 echo "You must set \$workdir_tag before including this common file.";
    >&2 echo "e.g. workdir_tag=foo will create \$workdir at \$output/foo";
    exit 1;
fi

script_dir="$(dirname "$0")"

unset vivado
v=()
unset dcp
unset dcp_macro_dir
unset output
unset board_files
unset top
unset sram_module
unset width
unset depth
lib=()
while [[ "$1" != "" ]]
do
    case "$1" in
    "$0") ;;
    */vivado) vivado="$1";;
    *.v) v+=("$1");;
    "-o") output="$2"; shift;;
    "--dcp") dcp="$2"; shift;;
    "--dcp_macro_dir") dcp_macro_dir="$2"; shift;;
    "--board_files") board_files="$2"; shift;;
    "--top") top="$2"; shift;;
    "--sram-module") sram_module="$2"; shift;;
    "--width") width="$2"; shift;;
    "--depth") depth="$2"; shift;;
    *.lib) lib+=("$1");;
    *.dcp) ;; # TODO: remove this hack. Need to swallow .dcp or figure out a better way to pass all the verilog files
    *) echo "Unknown argument $1"; exit 1;;
    esac
    shift
done

if [ -z "$output" ]; then
    >&2 echo "--output is required; the workdir will be created at \$output/workdir";
    exit 1;
fi

set -ex

workdir="$(dirname "$output")/$workdir_tag"
#rm -rf "$workdir"
mkdir -p "$workdir"

# TODO: refactor scripts to be more generic and configurable
cp -r $script_dir/constrs $workdir/
cp $script_dir/*.tcl $workdir/

function _join_by { local IFS="$1"; shift; echo "$*"; }
v_joined=$(_join_by ' ' "${v[@]}")

# TODO: do srcmainverilogfile properly (that is the top-level verilog file)
cat > $workdir/paths.tcl <<EOF
# This file is dynamically-generated; do not edit this file.
# TCL fragment to set some paths.

set_param board.repoPaths [list "${board_files}"];
set scriptdir "${workdir}";
set dcpdir "${dcp_macro_dir}";
set srcmainverilogfile "${v}";
set srcmainverilogfiles "${v_joined}";
EOF

VIVADOFLAGS="-nojournal -mode batch -source board.tcl -source paths.tcl -source project.tcl"
