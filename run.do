# Questa/ModelSim script for the integrated RV32 UVM bench.
# From the repository root at the Questa prompt, run:  do run.do
# Batch mode: vsim -c -do "do run.do; quit -f"
# If UVM is not found automatically, set UVM_HOME to the UVM distribution
# root (the directory containing src/) or directly to its src directory.

# Resolve paths relative to this script so it can be launched from the repo root
# or by its absolute path.
set _run_do_script [info script]
if {$_run_do_script eq ""} {
    set PROJECT_ROOT [file normalize [pwd]]
} else {
    set PROJECT_ROOT [file dirname [file normalize $_run_do_script]]
}

set RTL_DIR [file join $PROJECT_ROOT RISCV_UVM-main rtl]
set TB_DIR  [file join $PROJECT_ROOT RISCV_UVM-main tb_main]
set RTL_FILE [file join $RTL_DIR design.sv]
set TB_FILE  [file join $TB_DIR top.sv]

proc run_do_fail {message} {
    puts stderr "run.do: $message"
    error $message
}

# Search explicit UVM_HOME first, then common Questa/ModelSim installation paths.
proc run_do_find_uvm_src {} {
    set candidates [list]
    set install_roots [list]

    if {[info exists ::env(UVM_HOME)] && $::env(UVM_HOME) ne ""} {
        set uvm_home [file normalize $::env(UVM_HOME)]
        lappend candidates $uvm_home [file join $uvm_home src]
    }

    if {[info exists ::env(QUESTA_HOME)] && $::env(QUESTA_HOME) ne ""} {
        lappend install_roots $::env(QUESTA_HOME)
    }
    if {[info exists ::env(MODELSIM)] && $::env(MODELSIM) ne ""} {
        set modelsim_path [file normalize $::env(MODELSIM)]
        if {[file isdirectory $modelsim_path]} {
            lappend install_roots $modelsim_path
        } else {
            lappend install_roots [file dirname $modelsim_path]
        }
    }

    set simulator_exe [info nameofexecutable]
    if {$simulator_exe ne ""} {
        if {[file isdirectory $simulator_exe]} {
            lappend install_roots $simulator_exe
        } else {
            lappend install_roots [file dirname [file normalize $simulator_exe]]
        }
    }

    foreach root $install_roots {
        set search_dir [file normalize $root]
        # Walk up a few levels: Questa binaries commonly live in bin/, win64/,
        # or linux_x86_64/ below the installation root.
        for {set level 0} {$level < 5} {incr level} {
            foreach relative_path {
                verilog_src/uvm-1.2/src
                verilog_src/uvm-1.1d/src
                verilog_src/uvm-2020.3.1/src
                verilog_src/uvm-2020.3.1a/src
                verilog_src/uvm-2020.3.1
                verilog_src/uvm/src
            } {
                lappend candidates [file join $search_dir $relative_path]
            }
            set parent_dir [file dirname $search_dir]
            if {$parent_dir eq $search_dir} {
                break
            }
            set search_dir $parent_dir
        }
    }

    foreach source_dir [lsort -unique $candidates] {
        set package_file [file join $source_dir uvm_pkg.sv]
        if {[file isfile $package_file] &&
            [file isfile [file join $source_dir uvm_macros.svh]]} {
            return [file normalize $source_dir]
        }
    }
    return ""
}

proc run_do_compile {label args} {
    puts "\n=== Compiling $label ==="
    if {[catch {uplevel #0 [linsert $args 0 vlog]} message]} {
        puts stderr "run.do: Questa compilation failed for $label."
        error $message
    }
}

if {![file isfile $RTL_FILE]} {
    run_do_fail "cannot find $RTL_FILE; run this script from the repository checkout."
}
if {![file isfile $TB_FILE]} {
    run_do_fail "cannot find $TB_FILE; run this script from the repository checkout."
}

set UVM_SRC [run_do_find_uvm_src]
if {$UVM_SRC eq ""} {
    run_do_fail "could not locate uvm_pkg.sv. Set UVM_HOME to the UVM distribution root or its src directory, then run do run.do again."
}
set UVM_PACKAGE [file join $UVM_SRC uvm_pkg.sv]
puts "Repository: $PROJECT_ROOT"
puts "UVM source: $UVM_SRC"

# Keep Questa libraries, transcript, and other generated files outside the repo.
set TEMP_ROOT ""
foreach temp_var {TMPDIR TEMP TMP} {
    if {[info exists ::env($temp_var)] &&
        $::env($temp_var) ne "" &&
        [file isdirectory $::env($temp_var)]} {
        set TEMP_ROOT [file normalize $::env($temp_var)]
        break
    }
}
if {$TEMP_ROOT eq ""} {
    set TEMP_ROOT [file dirname $PROJECT_ROOT]
}
set BUILD_DIR [file join $TEMP_ROOT "phase2.1_questa_[pid]_[clock clicks]"]
file mkdir $BUILD_DIR
cd $BUILD_DIR

transcript file [file join $BUILD_DIR transcript.log]
transcript on
vlib work
vmap work [file join $BUILD_DIR work]

set COMMON_SV_FLAGS [list -sv -work work -timescale 1ns/1ps]

# Compile in dependency order: UVM, RTL, then the testbench (which includes
# the project packages and selects test_random from top.sv). UVM_NO_DPI avoids
# requiring a separately built UVM DPI shared library for this bench.
set UVM_ARGS $COMMON_SV_FLAGS
lappend UVM_ARGS +define+UVM_NO_DPI "+incdir+$UVM_SRC" $UVM_PACKAGE
run_do_compile "UVM package" {*}$UVM_ARGS

set RTL_ARGS $COMMON_SV_FLAGS
foreach include_dir [list $RTL_DIR [file join $RTL_DIR package]] {
    lappend RTL_ARGS "+incdir+$include_dir"
}
lappend RTL_ARGS $RTL_FILE
run_do_compile "RTL design" {*}$RTL_ARGS

set TB_ARGS $COMMON_SV_FLAGS
set TB_INCLUDE_DIRS [list \
    $UVM_SRC \
    $RTL_DIR \
    [file join $RTL_DIR package] \
    $TB_DIR \
    [file join $TB_DIR agents base] \
    [file join $TB_DIR agents instruction] \
    [file join $TB_DIR agents data] \
    [file join $TB_DIR agents reset] \
    [file join $TB_DIR agents debug] \
    [file join $TB_DIR agents muld] \
    [file join $TB_DIR environment] \
    [file join $TB_DIR virtual_sequences] \
    [file join $TB_DIR test]]
foreach include_dir $TB_INCLUDE_DIRS {
    lappend TB_ARGS "+incdir+$include_dir"
}
lappend TB_ARGS $TB_FILE
run_do_compile "UVM testbench" {*}$TB_ARGS

puts "\n=== Starting simulation: work.top ==="
if {[catch {vsim -voptargs=+acc work.top} message]} {
    puts stderr "run.do: Questa failed to load work.top."
    error $message
}
run -all
puts "\nSimulation finished. Questa build/log directory: $BUILD_DIR"
