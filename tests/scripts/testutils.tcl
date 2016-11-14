proc _clip_test {row col ops polylist {resultdir .} {wh {200 200}}} {
    file mkdir $resultdir

    set width [lindex $wh 0]
    set height [lindex $wh 1]

    # create valid canvas
    while {[info command [set canv ".c[incr i]"]] ne ""} {}
    grid [canvas $canv -width $width -height $height -background \#ffffff]
    grid configure $canv -row $row -column $col

    # Draw polylist
    set colors {\#0000ff \#ff0000 \#00ffff \#ffff00 \#ff00ff}
    set letters {A B C D E}
    set t {A}
    lappend e [lindex $polylist 0]
    if {$ops eq ""} {
        set t "Original"
    } else {
        for {set i 0} {$i < [llength $polylist]} {incr i} {
            # Build expression
            if {$i != 0} {
                lappend t [lindex $ops [expr $i-1]] [lindex $letters $i]
                lappend e  [lindex $ops [expr $i-1]] [lindex $polylist $i]
            }
        }
    }
    # Write expression
    $canv create text 0 0 -text $t -anchor nw -font {courier 10}

    # Do clipping
    set cliplist {}
    if {$t ne "Original" && [catch {set cliplist [mrfclip::clip {*}$e]} msg err]} {
        $canv create text 100 100 -text "ERROR" -fill \#ff0000 -font {courier 10}
        puts [dict get $err -errorinfo]
        return
    }

    # Draw polylist
    for {set i 0} {$i < [llength $polylist]} {incr i} {
        $canv create polygon {*}[lindex $polylist $i] -fill {} -outline [lindex $colors $i] -width 2
        $canv create text 0 [expr ($i+1)*10] -text [lindex $letters $i] -fill [lindex $colors $i] -anchor nw -font {courier 10}
    }

    # Draw clipped polygon
    if {$t ne "Original"} {
        if {[llength $cliplist]} {
            foreach poly $cliplist {
                $canv create polygon {*}$poly -fill \#00ff00 -outline {}
            }
        }
    }

    # Annotate clip result onto plot 
    #$canv create text 0 $height -text $cliplist -fill \#000000 -anchor sw -font {courier 6} -width $width

    # Write output
    set fname "r${row}_${col}"
    puts "Writing postscript for r=$row c=$col"
    $canv postscript -file $resultdir/${fname}.ps -width $width -height $height -pagewidth $width -pageheight $height -x 0 -y 0 -pageanchor nw
    return $cliplist
}
