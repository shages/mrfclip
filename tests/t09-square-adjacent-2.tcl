#!/usr/bin/env tclsh

package require Tk

set dir [file dirname [info script]]
lappend auto_path [file normalize [file join $dir ..]]
package require mclip

source [file join $dir scripts testutils.tcl]
set rdir [file join $dir results [lindex [file split [file rootname [info script]]] end]]

set poly1 {50 50 50 100 100 100 100 50}
#set poly1 {50 50 50 100 100 100}
set poly2 {90 75 90 100 150 100 150 75}
#set poly2 {100 75 150 100 150 75}
#set poly2 {75 75 150 100 150 75}
#set poly2 {75 75 50 100 50 75} <- interesting, but currently wrong

_clip_test 0 0 {}       [list $poly1 $poly2] $rdir
_clip_test 0 1 {OR}     [list $poly1 $poly2] $rdir
_clip_test 0 2 {AND}    [list $poly1 $poly2] $rdir
_clip_test 0 3 {XOR}    [list $poly1 $poly2] $rdir
_clip_test 0 4 {NOT}    [list $poly1 $poly2] $rdir

