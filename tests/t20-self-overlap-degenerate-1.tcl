#!/usr/bin/env tclsh

package require Tk

set dir [file dirname [info script]]
lappend auto_path [file normalize [file join $dir ..]]
package require mrfclip

source [file join $dir scripts testutils.tcl]
set rdir [file join $dir results [lindex [file split [file rootname [info script]]] end]]

# original
set poly1 {
    {
        90.0180 58.2080 90.0180 58.4800 91.3140 58.4800 91.3140 58.2080
    }
    {
        90.2880 58.7520 90.2880 59.0240 91.5840 59.0240 91.5840 58.7520
    }
    {
        90.0720 58.4800 90.0720 58.7520 90.3420 58.7520 90.3420 58.4800
    }
    {
        91.3140 58.2080 91.3140 58.4800 92.6100 58.4800 92.6100 58.2080
    }
}
set poly2 {{
    90.188 58.257
    90.188 58.948
    92.743 58.948
    92.743 58.257
}}

# scaled
proc transform_poly {poly} {
    set result [list]
    foreach p $poly {
        set tmp [list]
        foreach {x y} $p {
            lappend tmp [expr {($x - 90.0) * 70.0}] [expr {($y - 58.0) * 70.0}]
        }
        lappend result $tmp
    }
    return $result
}
set poly1 [transform_poly $poly1]
set poly2 [transform_poly $poly2]

#set poly1 {{25 25 25 60 60 60 60 25} {60 25 60 60 120 60 120 25} {40 60 40 100 100 100 100 60} {60 100 60 160 200 160 200 100}}
#set poly2 {{50 50 50 150 150 150 150 50}}

set wh {800 800}
set poly1 [_scale_poly $poly1 4 4]
set poly2 [_scale_poly $poly2 4 4]

_clip_test 0 0 {}       [list $poly1 $poly2] $rdir $wh
_clip_test 0 1 {OR}     [list $poly1 $poly2] $rdir $wh
_clip_test 0 2 {AND}    [list $poly1 $poly2] $rdir $wh
_clip_test 0 3 {XOR}    [list $poly1 $poly2] $rdir $wh
_clip_test 0 4 {NOT}    [list $poly1 $poly2] $rdir $wh
