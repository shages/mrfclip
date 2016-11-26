#!/usr/bin/env tclsh

package require Tk

set dir [file dirname [info script]]
lappend auto_path [file normalize [file join $dir ..]]
package require mrfclip

source [file join $dir scripts testutils.tcl]
set rdir [file join $dir results [lindex [file split [file rootname [info script]]] end]]

set poly1 {{50 100 150 100 100 50}}
set poly1 {{50 100 150 100 100 150}}
set poly2 {{100 75 200 75 150 25}}
set poly2 {{100 100 200 100 150 150}}

_clip_test 0 0 {}       [list $poly1 $poly2] $rdir
_clip_test 0 1 {OR}     [list $poly1 $poly2] $rdir
_clip_test 0 2 {AND}    [list $poly1 $poly2] $rdir
_clip_test 0 3 {XOR}    [list $poly1 $poly2] $rdir
_clip_test 0 4 {NOT}    [list $poly1 $poly2] $rdir

