#!/usr/bin/env tclsh

package require Tk

set dir [file dirname [info script]]
lappend auto_path [file normalize [file join $dir ..]]
package require mrfclip

source [file join $dir scripts testutils.tcl]
set rdir [file join $dir results [lindex [file split [file rootname [info script]]] end]]


set poly2 {{75 50 75 150 150 150 150 50}}
# 1 - same size left
set poly1 {
   {75 75 75 100 100 100 100 75 }
   {100 100 100 75 125 75 125 100}
   {100 140 100 160 125 160 125 140}
}
# 2 - same size right
set poly1 {
   {125 100 125 75 150 75 150 100}
   {100 100 100 75 125 75 125 100}
   {100 140 100 160 125 160 125 140}
}
# 3 - same size bottom
set poly1 {
   {100 100 100 125 125 125 125 100}
   {100 100 100 75 125 75 125 100}
   {100 140 100 160 125 160 125 140}
}
# 4 - same size top
set poly1 {
   {100 75 125 75 125 50 100 50}
   {100 100 100 75 125 75 125 100}
   {100 140 100 160 125 160 125 140}
}

# 5 - left side, taller
set poly1 {
   {75 50 75 100 100 100 100 50 }
   {100 100 100 75 125 75 125 100}
   {100 140 100 160 125 160 125 140}
}
# 6 - left side, even taller
set poly1 {
   {75 50 75 125 100 125 100 50}
   {100 100 100 75 125 75 125 100}
   {100 140 100 160 125 160 125 140}
}
# 7 - 6 plus bottom wide poly
#set poly1 {
#   {100 50 100 75 150 75 150 50}
#   {75 50 75 125 100 125 100 50}
#   {100 100 100 75 125 75 125 100}
#   {100 140 100 160 125 160 125 140}
#}

#set poly1 {
#  {75 50 75 150 125 150 125 100 150 100 150 50}
#}

set poly1 [_scale_poly $poly1 4 4]
set poly2 [_scale_poly $poly2 4 4]

set wh {800 800}

_clip_test 0 0 {}       [list $poly1 $poly2] $rdir $wh
_clip_test 0 1 {OR}     [list $poly1 $poly2] $rdir $wh
_clip_test 0 2 {AND}    [list $poly1 $poly2] $rdir $wh
_clip_test 0 3 {XOR}    [list $poly1 $poly2] $rdir $wh
_clip_test 0 4 {NOT}    [list $poly1 $poly2] $rdir $wh
