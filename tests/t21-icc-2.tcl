#!/usr/bin/env tclsh

package require Tk

set dir [file dirname [info script]]
lappend auto_path [file normalize [file join $dir ..]]
package require mrfclip

source [file join $dir scripts testutils.tcl]
set rdir [file join $dir results [lindex [file split [file rootname [info script]]] end]]


set poly2 {{50 50 50 150 150 150 150 50}}
set poly1 {
    {60 60 60 100 100 100 100 60}
    {100 100 100 50 125 50 125 100}
    {100 140 100 160 125 160 125 140}
}
# case 2
set poly1 {
    {60 60 60 100 100 100 100 60}
    {100 100 100 75 125 75 125 100}
    {100 140 100 160 125 160 125 140}
}


_clip_test 0 0 {}       [list $poly1 $poly2] $rdir
_clip_test 0 1 {OR}     [list $poly1 $poly2] $rdir
_clip_test 0 2 {AND}    [list $poly1 $poly2] $rdir
_clip_test 0 3 {XOR}    [list $poly1 $poly2] $rdir
_clip_test 0 4 {NOT}    [list $poly1 $poly2] $rdir

