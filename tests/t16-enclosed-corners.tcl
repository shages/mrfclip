#!/usr/bin/env tclsh

package require Tk

set dir [file dirname [info script]]
lappend auto_path [file normalize [file join $dir ..]]
package require mclip

source [file join $dir scripts testutils.tcl]
set rdir [file join $dir results [lindex [file split [file rootname [info script]]] end]]

set poly1 {50 50 50 150 150 150 150 50}
set poly2 {50 50 50 125 125 125 125 50}
set poly3 {75 75 75 150 150 150 150 75}

_clip_test 0 0 {OR}     [list $poly1 $poly2] $rdir
_clip_test 1 0 {AND}    [list $poly1 $poly2] $rdir
_clip_test 2 0 {XOR}    [list $poly1 $poly2] $rdir
_clip_test 3 0 {NOT}    [list $poly1 $poly2] $rdir

_clip_test 0 1 {OR OR}     [list $poly1 $poly2 $poly3] $rdir
_clip_test 0 2 {OR AND}    [list $poly1 $poly2 $poly3] $rdir
_clip_test 0 3 {OR NOT}    [list $poly1 $poly2 $poly3] $rdir
_clip_test 0 4 {OR XOR}    [list $poly1 $poly2 $poly3] $rdir

_clip_test 1 1 {AND OR}     [list $poly1 $poly2 $poly3] $rdir
_clip_test 1 2 {AND AND}    [list $poly1 $poly2 $poly3] $rdir
_clip_test 1 3 {AND NOT}    [list $poly1 $poly2 $poly3] $rdir
_clip_test 1 4 {AND XOR}    [list $poly1 $poly2 $poly3] $rdir

_clip_test 2 1 {XOR OR}     [list $poly1 $poly2 $poly3] $rdir
_clip_test 2 2 {XOR AND}    [list $poly1 $poly2 $poly3] $rdir
_clip_test 2 3 {XOR NOT}    [list $poly1 $poly2 $poly3] $rdir
_clip_test 2 4 {XOR XOR}    [list $poly1 $poly2 $poly3] $rdir

_clip_test 3 1 {NOT OR}     [list $poly1 $poly2 $poly3] $rdir
_clip_test 3 2 {NOT AND}    [list $poly1 $poly2 $poly3] $rdir
_clip_test 3 3 {NOT NOT}    [list $poly1 $poly2 $poly3] $rdir
_clip_test 3 4 {NOT XOR}    [list $poly1 $poly2 $poly3] $rdir

