#!/usr/bin/env tclsh

package require Tk

set dir [file dirname [info script]]
lappend auto_path [file normalize [file join $dir ..]]
package require mclip

source [file join $dir scripts testutils.tcl]
set rdir [file join $dir results [lindex [file split [file rootname [info script]]] end]]

set poly1 {50 50 150 50 100 100}
set poly2 {150 150 50 150 100 100}
set poly3 {50 50 50 150 100 100}
set poly4 {100 100 150 50 150 150}

_clip_test 0 0 {}       [list $poly1 $poly2 $poly3 $poly4] $rdir
_clip_test 0 1 {OR}     [list $poly1 $poly2] $rdir
_clip_test 0 2 {OR OR} [list $poly1 $poly2 $poly3] $rdir
_clip_test 0 3 {OR OR OR}    [list $poly1 $poly2 $poly3 $poly4] $rdir

