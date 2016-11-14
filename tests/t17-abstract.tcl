#!/usr/bin/env tclsh

package require Tk

set dir [file dirname [info script]]
lappend auto_path [file normalize [file join $dir ..]]
package require mrfclip

source [file join $dir scripts testutils.tcl]
set rdir [file join $dir results [lindex [file split [file rootname [info script]]] end]]

# Randomly generated coordinates
set poly1 {
    178.07600764002467 123.46040589430388
    77.00182664534162 29.7004282566255
    78.74464492720769 161.24729157949207
    152.51507690293485 180.89750762604993
    14.927963616758575 34.28450686125295
    101.18109410218013 150.648575341631
    135.4435339222865 179.4746318689895
}
set poly2 {
    19.041865565367914 56.63455713849261 
    95.09770910492992 147.19692655708496 
    63.229576523056984 39.49262301879592 
    24.410671021049225 110.14785077429742 
    99.7068170782676 32.47463444363076 
    130.6057667921324 51.12247536942478 
    50.137822106544775 146.37614469806482
}


_clip_test 0 0 {}       [list $poly1 $poly2] $rdir
_clip_test 0 1 {OR}     [list $poly1 $poly2] $rdir
_clip_test 0 2 {AND}    [list $poly1 $poly2] $rdir
_clip_test 0 3 {XOR}    [list $poly1 $poly2] $rdir
_clip_test 0 4 {NOT}    [list $poly1 $poly2] $rdir
