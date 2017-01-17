#!/usr/bin/env tclsh

package require Tk

set dir [file dirname [info script]]
lappend auto_path [file normalize [file join $dir ..]]
package require mrfclip

source [file join $dir scripts testutils.tcl]
set rdir [file join $dir results [lindex [file split [file rootname [info script]]] end]]

set fliph 460

# Read world map
puts "DEBUG: Reading world map"
set fworld [open "scripts/worldmap" "r"]
gets $fworld npolygons
set poly1 {}
while {[gets $fworld line] > -1} {
    set ncoords [lindex $line 0]
    set poly {}
    for {set i 0} {$i < $ncoords} {incr i} {
        gets $fworld pline
        lappend poly [expr {[lindex $pline 0]*2 + 80}] [expr {$fliph - ([lindex $pline 1]*2 + 200)}]
    }
    lappend poly1 $poly
}
close $fworld

# Read clipping polygons
set fclip [open "scripts/wm_50_squares" "r"]
gets $fclip npolygons
set poly2 {}
while {[gets $fclip line] > -1} {
    set ncoords [lindex $line 0]
    set poly {}
    for {set i 0} {$i < $ncoords} {incr i} {
        gets $fclip pline
        lappend poly [expr {[lindex $pline 0]*2 + 80}] [expr {$fliph - ([lindex $pline 1]*2 + 200)}]
    }
    lappend poly2 $poly
}
close $fclip

set wh {860 460}
# Clip it
puts "DEBUG: Drawing OR polygons"
_clip_test 0 0 {OR}     [list $poly1 $poly2] $rdir $wh
puts "DEBUG: Drawing AND polygons"
_clip_test 0 1 {AND}    [list $poly1 $poly2] $rdir $wh
puts "DEBUG: Drawing NOT polygons"
_clip_test 1 0 {NOT}    [list $poly1 $poly2] $rdir $wh
puts "DEBUG: Drawing XOR polygons"
_clip_test 1 1 {XOR}    [list $poly1 $poly2] $rdir $wh
