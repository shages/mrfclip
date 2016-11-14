#!/usr/bin/env tclsh

package require Tk

set dir [file dirname [info script]]
lappend auto_path [file normalize [file join $dir ..]]
package require mclip

source [file join $dir scripts testutils.tcl]
set rdir [file join $dir results [lindex [file split [file rootname [info script]]] end]]

set N 500
set p2 [expr {2*3.141592}]
set poly1 {}
set xoff 200.0 ; set yoff 200.0
for {set r 0} {$r < $p2} {set r [expr {$r + $p2/$N}]} {
    set ampfactorx [format "%.4f" [expr {(rand() + 1) * 85}]]
    set ampfactory [format "%.4f" [expr {(rand() + 1) * 85}]]
    set x [format "%.4f" [expr {$xoff + cos($r)*$ampfactorx}]]
    set y [format "%.4f" [expr {$yoff + sin($r)*$ampfactorx}]]
    lappend poly1 {*}[list $x $y]
}
#set poly2 {-2 -0.5 2 -0.5 2 0.5 -2 0.5}
set poly2 {50 100 50 300 350 300 350 100}

set wh {400 400}

_clip_test 0 0 {OR}     [list $poly1 $poly2] $rdir $wh
_clip_test 0 1 {AND}    [list $poly1 $poly2] $rdir $wh
_clip_test 1 0 {XOR}    [list $poly1 $poly2] $rdir $wh
_clip_test 1 1 {NOT}    [list $poly1 $poly2] $rdir $wh
