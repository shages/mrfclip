
package require Tcl 8.5

package require avltree
package require mrfclip::point
package require mrfclip::event
package require mrfclip::chain
package provide mrfclip 1.0

namespace eval mrfclip {
    namespace export mrfclip
    namespace export clip

    variable queue {}; # list of sweep events (mrfclip::event), priority queue
}

proc mrfclip::compare_events {a b} {
    # Return:
    #   -1 if a should be before b
    #   +1 if b should be before a
    #    0 if the events are identical

    # Identical events
    if {$a eq $b} { return 0 }

    # Convert all points to floating point
    set apoint [set [set ${a}::point]::coord]
    set ax [lindex $apoint 0]
    set ay [lindex $apoint 1]
    set bpoint [set [set ${b}::point]::coord]
    set bx [lindex $bpoint 0]
    set by [lindex $bpoint 1]

    # Sort top to bottom
    set epsilon 0.00000000001
    if {$ax - $bx < -$epsilon} { return -1 }
    if {$ax - $bx > $epsilon}  { return 1 }

    # Sort bottom to top
    if {$ay - $by < -$epsilon} { return -1 }
    if {$ay - $by > $epsilon} { return 1 }

    # This is the same point
    # Merge points if possible
    if {[set ${a}::point] ne [set ${b}::point]} {
        set ${b}::point [set ${a}::point]
    }

    # Check first if this is a right event,
    # in which case we shouldn't do S_point_compare
    if {![set ${a}::left] && ![set ${b}::left]} {
        # If the right endpoints aren't of the same poly, always
        # insert the subject first
        if {[set ${a}::polytype] ne [set ${b}::polytype]} {
            return [expr {[set ${a}::polytype] eq "SUBJECT" ? -1 : 1}]
        }

        # Compare the corresponding left endpoint y coords to ensure
        # the comparison works both ways
        set aleft [set [set [set ${a}::other]::point]::coord]
        set bleft [set [set [set ${b}::other]::point]::coord]
        set alx [expr {[lindex $aleft 0]*1.0}]
        set aly [expr {[lindex $aleft 1]*1.0}]
        set blx [expr {[lindex $bleft 0]*1.0}]
        set bly [expr {[lindex $bleft 1]*1.0}]

        if {abs($aly - $bly) < $epsilon} {
            # Same y, so compare x instead
            return [expr {$alx < $blx ? -1 : 1}]
        }
        return [expr {$aly < $bly ? -1 : 1}]
    }

    # One or the other is a right endpoint
    if {![set ${b}::left]} { return 1 }
    if {![set ${a}::left]} { return -1 }

    # Both are left, so sort by S ordering
    return [S_point_compare $a $b]
}

proc mrfclip::queue_insert {event} {
    # Insert a sweep event into the priority queue
    #
    # Arguments:
    # event     The sweep event to insert
    #
    # Returns the new priority queue value
    variable queue

    if {$queue eq ""} {
        return [set queue [list $event]]
    }

    for {set i 0} {$i < [llength $queue]} {incr i} {
        set c [compare_events $event [lindex $queue $i]]
        if {$c == -1} {
            return [set queue [linsert $queue $i $event]]
        }
    }
    return [lappend queue $event]
}

proc mrfclip::create_edge {p1 p2 polytype} {
    # Create an edge by instantiating two sweep events with properties
    #
    # Arguments:
    # p1    The "first" point object of the edge
    # p2    The other point object of the edge
    # polytype  The poly this edge belongs to (SUBJECT | CLIPPING)
    #
    # Return a list of two sweep events in the same order as p1 & p2

    # Check which point is left of the other
    set p1x [lindex [set ${p1}::coord] 0]
    set p1y [lindex [set ${p1}::coord] 1]
    set p2x [lindex [set ${p2}::coord] 0]
    set p2y [lindex [set ${p2}::coord] 1]
    set epsilon 0.00000000001
    set left 0
    if {abs($p1x - $p2x) < $epsilon} {
        if {$p1y - $p2y < -$epsilon} {
            set left 1
        }
    } elseif {$p1x < $p2x} {
        set left 1
    }

    # Create event objects, annotate the new events on their points, and
    # connect the events together
    set event1 [::mrfclip::event init $p1 $left $polytype]
    set event2 [::mrfclip::event init $p2 [expr {!$left}] $polytype]
    lappend ${p1}::events $event1
    lappend ${p2}::events $event2
    set ${event1}::other $event2
    set ${event2}::other $event1

    return [list $event1 $event2]
}

proc mrfclip::create_poly {poly polytype} {
    # Create a polygon object by instantiating the edges and inserting them
    # into the priority queue
    #
    # Arguments:
    # poly      The polygon (list of coordinates)
    # polytype  Which polygon this belongs to (SUBJECT | CLIPPING)
    #
    # Return all sweep events of the polygon
    variable queue

    # Convert polygon coordinates to Points
    set points {}
    foreach {x y} $poly {
        lappend points [::mrfclip::point init [list [expr {1.0*$x}] [expr {1.0*$y}]]]
    }

    # Create Events from Points
    set events {}
    lappend events {*}[create_edge \
    [lindex $points end] \
    [lindex $points 0] \
    $polytype]
    for {set i 0} {$i < [expr {[llength $points] - 1}]} {incr i} {
        lappend events {*}[create_edge \
            [lindex $points $i] \
            [lindex $points [expr {$i + 1}]] \
            $polytype]
    }

    # Insert events in the queue
    foreach event $events {
        $queue insert $event
    }

    # Merge common points
    set node [$queue leftmost_node]
    while {[set next [$queue node_right_of $node]] ne "::avltree::node::NIL"} {
        # Check if the next event's point is different, and if so fix it
        if {[set [set ${next}::value]::point] ne [set [set ${node}::value]::point]} {
            set this_coord [set [set [set ${node}::value]::point]::coord]
            set next_coord [set [set [set ${next}::value]::point]::coord]
            if {[lindex $this_coord 0] == [lindex $next_coord 0] && \
            [lindex $this_coord 1] == [lindex $next_coord 1]} {
                set [set ${next}::value]::point [set [set ${node}::value]::point]
            }
        }
        set node $next
    }

    # Return the events (only for testing)
    return $events
}

proc mrfclip::lshift {listVar} {
    # Remove the first item from the specified list and return its value

    upvar 1 $listVar l
    if {![info exists l]} {
        # make the error message show the real variable name
        error "can't read \"$listVar\": no such variable"
    }
    if {![llength $l]} {error Empty}
    set r [lindex $l 0]
    set l [lreplace $l [set l 0] 0]
    return $r
}

proc mrfclip::S_point_compare {a b} {
    # If 'a' should be ordered before 'b,' return -1, otherwise return 1
    # If a is the same edge as b, return 0
    #
    # Sort first by y-coordinate intersecting the sweep line

    # First check if they are equal (used by BST delete)
    if {$a eq $b} {
        return 0
    }

    # Check if y-coordinate of a's left endpoint (the sweep line) is
    # above or below edge b.
    set p [point_above_line {*}[set [set ${a}::point]::coord] \
    {*}[set [set ${b}::point]::coord] {*}[set [set [set ${b}::other]::point]::coord]]

    if {$p != 0} {
        return $p
    }

    # 0 means on b, but b could be vertical
    # check vertical case first
    set aline [list [set [set ${a}::point]::coord] [set [set [set ${a}::other]::point]::coord]]
    set bline [list [set [set ${b}::point]::coord] [set [set [set ${b}::other]::point]::coord]]
    set epsilon 0.00000000001
    if {abs([lindex $bline 0 0] - [lindex $bline 1 0]) < $epsilon} {
        # vertical
        # Compare by lower y-coord
        if {[lindex $aline 0 1] < [lindex $bline 0 1]} {
            return -1
        }
        if {[lindex $aline 0 1] > [lindex $bline 0 1]} {
            return 1
        }
        # same y-coord, compare other point
    }

    # on the line, so test the right endpoint of edge 'a'
    set p [point_above_line {*}[set [set [set ${a}::other]::point]::coord] \
    {*}[set [set ${b}::point]::coord] {*}[set [set [set ${b}::other]::point]::coord]]

    # For collinear edges, insert subject first always
    return [expr {$p != 0 ? $p : [set ${a}::polytype] eq "SUBJECT" ? -1 : 1}]
}

proc mrfclip::insert_S {Slist event} {
    # Insert an edge, represented by its left endpoint, into S
    #
    # Arguments:
    # S     Set of edges intersecting the sweep line
    # event The left endpoint sweep event representing this edge
    #
    # Return the position in S of the insertion
    upvar $Slist S

    if {[llength $S] == 0} {
        lappend S $event
        return 0
    }

    set ex [lindex [set [set ${event}::point]::coord] 0]
    set ey [lindex [set [set ${event}::point]::coord] 1]

    for {set i 0} {$i < [llength $S]} {incr i} {
        set this [lindex $S $i]
        if {[S_point_compare $event $this] < 0} {
            set S [linsert $S $i $event]
            return $i
        }
    }
    lappend S $event
    return [expr {[llength $S] - 1}]
}

proc mrfclip::find_in_S {S element} {
    # Find the position of this element in S
    #
    # Arguments:
    # S         List of sweep events
    # element   The sweep event to find
    for {set i 0} {$i < [llength $S]} {incr i} {
        if {[lindex $S $i] == $element} {
            return $i
        }
    }
}
proc mrfclip::poly_from_chain {chain} {
    # Convert a chain to a list of points (polygon)
    set poly {}
    foreach point [set ${chain}::points] {
        lappend poly {*}[set ${point}::coord]
    }
    return $poly
}

proc mrfclip::create_chains {segs} {
    # Connect all segments in the solution into an arbitrary number of polygons
    #
    # Arguments:
    # segs      List of segments
    #
    # Return list of polygons

    # C is dictionary of chain endpoints indexed by point name
    # R is list of resulting polygons
    set C [dict create]
    set R {}

    foreach curr $segs {
        # Shift out current list of two points
        set sl [lindex $curr 0]
        set sr [lindex $curr 1]

        # check if a matching point for this left event exists

        # If both points already exist, then connect the chains without
        # creating any new chain objects
        if {[dict exists $C $sl] && [dict exists $C $sr]} {
            #puts "DEBUG: Both SL and SR found"
            set slC [dict get $C $sl]
            set srC [dict get $C $sr]
            dict unset C $sl
            dict unset C $sr
            if {$slC eq $srC} {
                # Completing a chain and skip
                lappend R [poly_from_chain $slC]
                continue
            }

            # Merge chains together. Reuse left, destroy right.
            if {[set ${slC}::right] eq $sl} {
                if {[set ${srC}::left] eq $sr} {
                    # append in order
                    foreach point [set ${srC}::points] {
                        lappend ${slC}::points $point
                    }
                    set ${slC}::right [set ${srC}::right]
                } else {
                    set rpoints [set ${srC}::points]
                    set nrpoints [llength $rpoints]
                    for {set i [expr {$nrpoints-1}]} {$i >= 0} {incr i -1} {
                        set point [lindex $rpoints $i]
                        lappend ${slC}::points $point
                    }
                    set ${slC}::right [set ${srC}::left]
                }
            } else {
                if {[set ${srC}::left] eq $sr} {
                    # append in order
                    foreach point [set ${srC}::points] {
                        set ${slC}::points [linsert [set ${slC}::points] 0 $point]
                    }
                    set ${slC}::left [set ${srC}::right]
                } else {
                    set rpoints [set ${srC}::points]
                    set nrpoints [llength $rpoints]
                    for {set i [expr {$nrpoints-1}]} {$i >= 0} {incr i -1} {
                        set point [lindex $rpoints $i]
                        set ${slC}::points [linsert [set ${slC}::points] 0 $point]
                    }
                    set ${slC}::left [set ${srC}::left]
                }
            }
            # Replace endpoints in C
            dict set C [set ${slC}::left] $slC
            dict set C [set ${slC}::right] $slC
            continue
        }

        if {[dict exists $C $sl]} {
            set chain [dict get $C $sl]
            if {[set ${chain}::left] eq $sl} {
                # Connect to left end and replace left with sr
                set ${chain}::points [linsert [set ${chain}::points] 0 $sr]
                set ${chain}::left $sr
            } else {
                # Connect to right end and replace right with sr
                lappend ${chain}::points $sr
                set ${chain}::right $sr
            }

            dict unset C $sl
            dict set C $sr $chain

            continue
        } elseif {[dict exists $C $sr]} {
            set chain [dict get $C $sr]
            if {[set ${chain}::left] eq $sr} {
                # Connect to left end and replace left with sl
                set ${chain}::points [linsert [set ${chain}::points] 0 $sl]
                set ${chain}::left $sl
            } else {
                # Connect to right end and replace right with sl
                lappend ${chain}::points $sl
                set ${chain}::right $sl
            }

            dict unset C $sr
            dict set C $sl $chain

            continue
        }

        # Create new chain
        set c [::mrfclip::chain init]
        lappend ${c}::points $sl
        lappend ${c}::points $sr
        set ${c}::left $sl
        set ${c}::right $sr
        dict set C $sl $c
        dict set C $sr $c
    }
    return $R
}

proc mrfclip::intersect {p q} {
    # Calculate intersection point of two line segments
    #
    # Algorithm taken from:
    # http://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
    #
    # Args
    # p - first line
    # q - second line
    #
    # Returns the point of intersection if the lines intersect
    # Returns nothing if the lines are parallel

    set px [lindex $p 0]
    set py [lindex $p 1]
    set pprx [lindex $p 2]
    set ppry [lindex $p 3]

    set qx [lindex $q 0]
    set qy [lindex $q 1]
    set qpsx [lindex $q 2]
    set qpsy [lindex $q 3]

    set rx [expr {1.0*($pprx - $px)}]
    set ry [expr {1.0*($ppry - $py)}]
    set sx [expr {1.0*($qpsx - $qx)}]
    set sy [expr {1.0*($qpsy - $qy)}]

    # r x s
    #   r           s
    # [ (pprx - px) (qpsx - qx) ]
    # [ (ppry - py) (qpsy - qy) ]
    set rxs [expr {$rx*$sy - $ry*$sx}]
    set qnpxr [expr {(($qx - $px)*$ry - ($qy - $py)*$rx)}]

    # Check for collinear
    if {$rxs == 0} {
        if {$qnpxr == 0} {
            # Collinear - check for overlap
            # (q-p)*r
            set rdot [expr {pow($rx, 2) + pow($ry, 2)}]
            set t0 [expr {(($qx - $px) * $rx + ($qy - $py) * $ry) / $rdot}]
            set t1 [expr {$t0 + ($sx * $rx + $sy * $ry) / $rdot}]
            # Endpoint touching
            if {($t0 == 0 && $t1 < 0) || ($t0 == 1 && $t1 > 1)} {
                return [list $qx $qy]
            } elseif {($t1 == 0 && $t0 < 0) || ($t1 == 1 && $t0 > 1)} {
                return [list $qpsx $qpsy]
            }
            # Collinear overlaps
            if {$t0 > 0.0 && $t0 <= 1.0} {
                if {$t1 <= 0.0} {
                    return [list $qx $qy $px $py]
                } elseif {$t1 > 1.0} {
                    return [list $qx $qy $pprx $ppry]
                } else {
                    return [list $qx $qy $qpsx $qpsy]
                }
            } elseif {$t0 <= 0.0} {
                if {$t1 > 0 && $t1 <= 1.0} {
                    return [list $qpsx $qpsy $px $py]
                } elseif {$t1 > 1.0} {
                    return [list $px $py $pprx $ppry]
                }
            } else {
                if {$t1 > 0.0 && $t1 <= 1.0} {
                    return [list $qpsx $qpsy $pprx $ppry]
                } elseif {$t1 <= 0.0} {
                    return [list $px $py $pprx $ppry]
                }
            }
            return
        }
        # Parallel
        return
    }

    # t = (q - p) x s / (r x s)
    # q = q, p = s1, s = (qps - q)
    #
    #   q-p         s
    # [ (qx - px) (qpsx - qx) ]
    # [ (qy - py) (qpsy - qy) ]
    set t [expr {(($qx - $px)*$sy - ($qy - $py)*$sx) / $rxs}]

    # u = (q - p) x r / (r x s)
    # q = q, p = s1, r = (s2 - s1)
    #
    #   q-p         r
    # [ (qx - px) (s2x - s1x) ]
    # [ (qy - py) (s2y - s1y) ]
    set u [expr {$qnpxr / $rxs}]


    # Check if lines intersect
    if {!((0.0 <= $t) && ($t <= 1.0) && (0.0 <= $u) && ($u <= 1.0))} {
        # Not parallel, but segments don't intersect
        return
    }

    # p + tr
    return [list \
    [expr {$px + $t*($pprx - $px)}] \
    [expr {$py + $t*($ppry - $py)}] \
    ]
}

proc mrfclip::edges_overlap {c1l c1r c2l c2r} {
    if {[coords_equal $c1l $c2l] && [coords_equal $c1r $c2r]} {
        return 1
    }
    if {[coords_equal $c1l $c2r] && [coords_equal $c1r $c2l]} {
        return 1
    }
    return 0
}

proc mrfclip::possible_inter {e1 e2} {
    # Check for a possible intersection between two edges and subdivide them
    #
    # Arguments:
    # e1    The current edge being processed
    # e2    An adjacent edge to intersect with. May be empty.
    #
    # Side effects:
    # If an intersection occurs interior to one edge, the edges will be
    #   subdivided and the new events inserted into Q
    # Return nothing
    variable queue

    if {$e1 eq "" || $e2 eq "" || $e1 eq "NULL" || $e2 eq "NULL"} {
        return
    }

    # Check for intersection
    set e1o [set ${e1}::other]
    set e2o [set ${e2}::other]
    set e1coord [set [set ${e1}::point]::coord]
    set e2coord [set [set ${e2}::point]::coord]
    set e1ocoord [set [set ${e1o}::point]::coord]
    set e2ocoord [set [set ${e2o}::point]::coord]

    # First check for overlapping edges
    if {[edges_overlap $e1coord $e1ocoord $e2coord $e2ocoord]} {
        set ce1 [expr {[set ${e1}::left] ? $e1 : $e1o}]
        set ce2 [expr {[set ${e2}::left] ? $e2 : $e2o}]
        set ${ce1}::edgetype "NON_CONTRIBUTING"
        set ${ce2}::edgetype [expr { \
            [set ${ce1}::inout] == [set ${ce2}::inout] ? \
            "SAME_TRANSITION" : "DIFFERENT_TRANSITION"}]
        return
    }

    set inter [::mrfclip::intersect \
    [list {*}$e1coord {*}$e1ocoord] [list {*}$e2coord {*}$e2ocoord]]

    # No intersection
    if {$inter eq {}} {
        return
    }

    # Check if collinear
    if {[llength $inter] == 4} {
        # sort it
        set reverse [expr {[lindex $inter 0] > [lindex $inter 2] ? 1 : \
            [lindex $inter 0] != [lindex $inter 2] ? 0 :  \
            [lindex $inter 1] > [lindex $inter 3] ? 1 : 0}]
        if {$reverse} {
            set inter [list \
                [lindex $inter 2] \
                [lindex $inter 3] \
                [lindex $inter 0] \
                [lindex $inter 1] \
            ]
        }

        # First create new left edge
        set left1 $e1
        set left2 $e2
        set next_coord [lrange $inter 0 1]
        set left_match 0    ; # record if the original left endpoints matched
        if {[coords_equal [set [set ${left1}::point]::coord] [set [set ${left2}::point]::coord]]} {
            # If they're both equal, then skip
            set left_match 1
        } else {
            # need to cut one of them short
            if {[coords_equal [set [set ${left1}::point]::coord] $next_coord]} {
                # Save the point and remove it from the queue
                set old_right_point [set [set ${left2}::other]::point]
                $queue delete [set ${left2}::other]

                # Update  endpoint
                set [set ${left2}::other]::point [set ${left1}::point]
                set common_point [set [set ${left2}::other]::point]

                # Create new segment
                set nel [::mrfclip::event init $common_point true [set ${left2}::polytype]]
                set ner [::mrfclip::event init $old_right_point false [set ${left2}::polytype]]
                $queue insert [set ${left2}::other]
                set left2 $nel
            } else {
                # Save the point and remove it from the queue
                set old_right_point [set [set ${left1}::other]::point]
                $queue delete [set ${left1}::other]

                # Update  endpoint
                set [set ${left1}::other]::point [set ${left2}::point]
                set common_point [set [set ${left1}::other]::point]

                # Create new segment
                set nel [::mrfclip::event init $common_point true [set ${left1}::polytype]]
                set ner [::mrfclip::event init $old_right_point false [set ${left1}::polytype]]
                $queue insert [set ${left1}::other]
                set left1 $nel
            }
            set ${nel}::other $ner
            set ${ner}::other $nel
            $queue insert $nel
            $queue insert $ner
        }
        # At this point, left1 and left2 refer to the left events of the middle
        # segment. Can determine edgetype now.
        # But only do it if the left endpoints matched, because we know
        # then that both events are inserted into S and will have valid
        # flags
        if {$left_match} {
            set ${left1}::edgetype "NON_CONTRIBUTING"
            set ${left2}::edgetype [expr { \
                [set ${left1}::inout] == [set ${left2}::inout] ? \
                "SAME_TRANSITION" : "DIFFERENT_TRANSITION"}]
        }

        # Now handle the middle & right segment
        # At this point, both left1 and left2 should match the left point
        # of the overlap segment
        # Only need to determine if the other ends match or not
        set next_coord [lrange $inter 2 3]
        if {[coords_equal [set [set [set ${left1}::other]::point]::coord] \
            [set [set [set ${left2}::other]::point]::coord]]} {
            # If they're both equal, then skip
        } else {
            if {[coords_equal [set [set [set ${left1}::other]::point]::coord] $next_coord]} {
                # Save the point and remove it from the queue
                set old_right_point [set [set ${left2}::other]::point]
                $queue delete [set ${left2}::other]

                # Update  endpoint
                set [set ${left2}::other]::point [set [set ${left1}::other]::point]
                set common_point [set [set ${left2}::other]::point]

                # Create new segment
                set nel [::mrfclip::event init $common_point true [set ${left2}::polytype]]
                set ner [::mrfclip::event init $old_right_point false [set ${left2}::polytype]]
                $queue insert [set ${left2}::other]
            } else {
                # Save the point and remove it from the queue
                set old_right_point [set [set ${left1}::other]::point]
                $queue delete [set ${left1}::other]

                # Update  endpoint
                set [set ${left1}::other]::point [set [set ${left2}::other]::point]
                set common_point [set [set ${left1}::other]::point]

                # Create new segment
                set nel [::mrfclip::event init $common_point true [set ${left1}::polytype]]
                set ner [::mrfclip::event init $old_right_point false [set ${left1}::polytype]]
                $queue insert [set ${left1}::other]
            }
            set ${nel}::other $ner
            set ${ner}::other $nel
            $queue insert $nel
            $queue insert $ner
        }
        return
    }

    set icoord $inter
    # Check if intersection is at one endpoint of both lines
    if {([coords_equal $icoord $e1coord] \
    || [coords_equal $icoord $e1ocoord]) \
    && ([coords_equal $icoord $e2coord] \
    || [coords_equal $icoord $e2ocoord])} {
        return
    }

    # Check if intersection is at any endpoint, in which case we
    # need to split the other edge

    # Check edge 1
    if {[set eq [coords_equal $icoord $e1coord]] \
        || [coords_equal $icoord $e1ocoord]} {
        # Subdivide edge 2

        # Reuse the same point
        if {$eq} {
            set point [set ${e1}::point]
        } else {
            set point [set ${e1o}::point]
        }
        set nel [::mrfclip::event init $point true  [set ${e2}::polytype]]
        set ner [::mrfclip::event init $point false [set ${e2}::polytype]]

        # Connect new events first
        lappend ${point}::events $ner
        lappend ${point}::events $nel
        if {[set ${e2}::left]} {
            set ${ner}::other $e2
            set ${e2}::other $ner
            set ${nel}::other $e2o
            set ${e2o}::other $nel
        } else {
            set ${ner}::other $e2o
            set ${e2o}::other $ner
            set ${nel}::other $e2
            set ${e2}::other $nel
        }

        $queue insert $nel
        $queue insert $ner
        return
    }

    # Check edge 2
    if {[set eq [coords_equal $icoord $e2coord]] || [coords_equal $icoord $e2ocoord]} {
        # Subdivide edge 1

        # Reuse the same point
        if {$eq} {
            set point [set ${e2}::point]
        } else {
            set point [set ${e2o}::point]
        }
        set nel [::mrfclip::event init $point true  [set ${e1}::polytype]]
        set ner [::mrfclip::event init $point false [set ${e1}::polytype]]

        # Connect new events first
        lappend ${point}::events {*}[list $ner $nel]
        if {[set ${e1}::left]} {
            set ${ner}::other $e1
            set ${e1}::other $ner
            set ${nel}::other $e1o
            set ${e1o}::other $nel
        } else {
            set ${ner}::other $e1o
            set ${e1o}::other $ner
            set ${nel}::other $e1
            set ${e1}::other $nel
        }

        $queue insert $nel
        $queue insert $ner

        return
    }

    # Must subdivide both edges
    # Create new point
    set point [::mrfclip::point init $icoord]
    set nel1 [::mrfclip::event init $point true [set ${e1}::polytype]]
    set ner1 [::mrfclip::event init $point false [set ${e1}::polytype]]
    set nel2 [::mrfclip::event init $point true [set ${e2}::polytype]]
    set ner2 [::mrfclip::event init $point false [set ${e2}::polytype]]

    lappend ${point}::events {*}[list $nel1 $nel2 $ner1 $ner2]
    set ${nel1}::other [expr {[set ${e1}::left] ? $e1o : $e1}]
    set ${ner1}::other [expr {[set ${e1}::left] ? $e1 : $e1o}]
    set ${nel2}::other [expr {[set ${e2}::left] ? $e2o : $e2}]
    set ${ner2}::other [expr {[set ${e2}::left] ? $e2 : $e2o}]
    set ${e1}::other  [expr {[set ${e1}::left] ? $ner1 : $nel1}]
    set ${e1o}::other [expr {[set ${e1}::left] ? $nel1 : $ner1}]
    set ${e2}::other  [expr {[set ${e2}::left] ? $ner2 : $nel2}]
    set ${e2o}::other [expr {[set ${e2}::left] ? $nel2 : $ner2}]

    $queue insert $nel1
    $queue insert $ner1
    $queue insert $nel2
    $queue insert $ner2
}

proc mrfclip::coords_equal {a b} {
    set epsilon 0.00000000001
    return [expr { \
        abs([lindex $a 0] - [lindex $b 0]) < $epsilon \
        && abs([lindex $a 1] - [lindex $b 1]) < $epsilon \
    }]
}

proc mrfclip::event_is_vertical {event} {
    set p1 [set [set ${event}::point]::coord]
    set p2 [set [set [set ${event}::other]::point]::coord]
    return [expr {[lindex $p1 0] == [lindex $p2 0] ? 1 : 0}]
}

proc mrfclip::set_inside_flags {curr_event prev_event} {
    # set the inside flags for this event in s
    #
    # arguments:
    # curr_event    the event being inserted into s
    # prev_event    the preceeding event in s
    #
    # return nothing
    if {$prev_event eq {} || $prev_event eq "NULL"} {
        set ${curr_event}::inout 0
        set ${curr_event}::inside 0
    } elseif {[set ${curr_event}::polytype] eq [set ${prev_event}::polytype]} {
        set ${curr_event}::inside [set ${prev_event}::inside]
        set ${curr_event}::inout [expr {![set ${prev_event}::inout]}]
    } else {
        # Transition of a vertical line is the opposite, since this
        # is a vertical sweep line
        set ${curr_event}::inside [expr {[event_is_vertical $prev_event] ? [set ${prev_event}::inout] : ![set ${prev_event}::inout]}]
        set ${curr_event}::inout [set ${prev_event}::inside]
    }
}

proc mrfclip::point_above_line {ax ay bx by cx cy} {
    # check if a point is above or below the speified line
    # the point could be a left or right endpoint
    #
    # arguments:
    # point     the point (x,y coords) to test
    # line      the line (two points) to test against
    #
    # returns:
    # 1  - above
    # 0  - on
    # -1 - below

    # If the line is vertical
    set epsilon 0.00000000001
    if {abs(1.0*$bx - $cx) < $epsilon} {
        # On the line
        if {abs(1.0*$ax - $bx) < $epsilon} { return 0 }
        return -1
    }

    # caclulate m & b
    set m [expr {1.0*($cy - $by) / ($cx - $bx)}]
    set b [expr {$by - $m * $bx}]
    set line_y [expr {$m * $ax + $b}]

    return [expr {abs($ay - $line_y) < $epsilon ? 0 : \
    $ay > $line_y ? 1 : -1}]
}

proc mrfclip::mrfclip {subject clipping operation} {
    # clip two polygons based on the specified operation
    #
    # arguments:
    # subject   the subject multi-polygon
    # clipping  the clipping multi-polygon
    # operation the boolean operation to perform (and|or|not|xor)
    variable queue

    # Skip if operation is AND or NOT, and subject is empty
    if {$subject eq "{}"} {
        if {$operation eq "NOT" || $operation eq "AND"} {
            return {}
        } else {
            return $clipping
        }
    } elseif {$clipping eq "{}"} {
        if {$operation eq "NOT" || $operation eq "OR"} {
            return $subject
        } else {
            return {}
        }
    }

    #set queue {}
    # create an AVL tree
    set queue [::avltree::create]
    # Bind compare proc
    proc ${queue}::compare {a b} {
        return [::mrfclip::compare_events $a $b]
    }

    # step 1: create polygons and populate the priority queue
    # inputs "subject" and "clipping" should be multi-polygons
    foreach sub $subject {
        create_poly $sub SUBJECT
    }
    foreach clip $clipping {
        create_poly $clip CLIPPING
    }

    set S [::avltree::create]
    proc ${S}::compare {a b} {
        set epsilon 0.00000000001
        if {[lindex [set [set ${a}::point]::coord] 0] \
        - [lindex [set [set ${b}::point]::coord] 0] < -$epsilon} {
            # Do the comparison the same way during insertion, and do the
            # opposite
            set r [::mrfclip::S_point_compare $b $a]
            return [expr {$r == 0 ? 0 : $r < 0 ? 1 : -1}]
        }
        return [::mrfclip::S_point_compare $a $b]
    }
    set intersection_segs {}
    set union_segs {}
    set diff_segs {}
    set intersection_psegs {}
    set union_psegs {}
    set diff_psegs {}
    set xor_psegs {}

    # step 2: loop through priority queue while there are still events
    set iter [expr {[llength $subject] * 2}]
    set prev ""
    while {[set event [$queue pop_leftmost]] ne "NULL"} {
        if {$event eq $prev} {
            puts "FATAL: Infinite loop detected"
            puts "DEBUG: event line:
            ([lindex [set [set ${event}::point]::coord] 0], [lindex [set [set ${event}::point]::coord] 1])
            ([lindex [set [set [set ${event}::other]::point]::coord] 0], [lindex [set [set [set ${event}::other]::point]::coord] 1])
            "
            error "infinite loop"
        }
        set prev $event

        if {[set ${event}::left]} {
            # left event
            # get position to insert into s
            $S insert $event
            set S_left [$S value_left_of $event]
            set S_right [$S value_right_of $event]

            # Set flags
            set_inside_flags $event $S_left

            # Check for intersections
            possible_inter $event $S_left
            possible_inter $event $S_right
        } else {
            # get position of corresponding point
            set other [set ${event}::other]
            set prev [$S value_left_of $other]
            set next [$S value_right_of $other]

            # Check if corresponding left point is inside the other poly
            # or not
            if {[set ${other}::edgetype] eq "SAME_TRANSITION"} {
                # Add to both intersection and union
                lappend intersection_psegs [list \
                    [set ${other}::point] \
                    [set ${event}::point] \
                ]
                lappend union_psegs [list \
                    [set ${other}::point] \
                    [set ${event}::point] \
                ]
            } elseif {[set ${other}::edgetype] eq "DIFFERENT_TRANSITION"} {
                lappend diff_psegs [list \
                    [set ${other}::point] \
                    [set ${event}::point] \
                ]
            } elseif {[set ${other}::edgetype] eq "NON_CONTRIBUTING"} {

            } else {
                if {[set ${other}::inside]} {
                    if {[set ${other}::polytype] eq "CLIPPING"} {
                        lappend diff_psegs [list \
                            [set ${other}::point] \
                            [set ${event}::point] \
                        ]
                    }
                    lappend intersection_psegs [list \
                        [set ${other}::point] \
                        [set ${event}::point] \
                    ]
                } else {
                    if {[set ${other}::polytype] eq "SUBJECT"} {
                        lappend diff_psegs [list \
                            [set ${other}::point] \
                            [set ${event}::point] \
                        ]
                    }
                    lappend union_psegs [list \
                        [set ${other}::point] \
                        [set ${event}::point] \
                    ]
                }
            }

            if {[set ${other}::edgetype] ne "NON_CONTRIBUTING"} {
                lappend xor_psegs [list \
                    [set ${other}::point] \
                    [set ${event}::point] \
                ]
            }

            # Remove from S
            if {[$S delete $other] == 0} {
                puts "ERROR: Couldn't delete: $other. Result will likely be wrong."
                puts "  coord = [set [set ${other}::point]::coord]"
            }

            # Check for intersections of new neighbors
            possible_inter $prev $next
        }
    }

    # Create and connect chains of segments into polygons
    switch $operation {
        "AND" { set polygons [::mrfclip::create_chains $intersection_psegs] }
        "OR"  { set polygons [::mrfclip::create_chains $union_psegs] }
        "NOT" { set polygons [::mrfclip::create_chains $diff_psegs] }
    }
    return $polygons

    # Cleanup
    namespace delete {*}[namespace children ::mrfclip::event]
    namespace delete {*}[namespace children ::mrfclip::point]
}

proc mrfclip::multi_clip {p1 p2 op} {
    # handle multiple polygon list inputs and perform the specified operation
    #
    # args
    # p1 - subject polylist
    # p2 - clip polylist
    # op - human readable operation (and|or|xor|not)

    if {[llength [lindex $p1 0]] <= 1} {
        set p1 [list $p1]
    }
    if {[llength [lindex $p2 0]] <= 1} {
        set p2 [list $p2]
    }

    # convert inputs to lists of polies and then loop through all combinations
    set polylist {}
    if {$op eq "XOR"} {
        # xor isn't distributive, so expand the function:
        # p1 = p11 or p12 or ... or p1n
        # p2 = p21 or p22 or ... or p2n
        # p1 xor p2 =   p11 andnot p21 andnot p22 andnot ... andnot p2n
        #            or p12 andnot p21 andnot p22 andnot ... andnot p2n
        #            or ...
        #            or p1n andnot p21 andnot p22 andnot ... andnot p2n
        #            or p21 andnot p11 andnot p12 andnot ... andnot p1n
        #            or p22 andnot p11 andnot p12 andnot ... andnot p1n
        #            or ...
        #            or p2n andnot p11 andnot p12 andnot ... andnot p1n
        foreach poly $p1 {
            set args [list $poly]
            foreach arg $p2 {
                lappend args NOT $arg
            }
            lappend polylist {*}[clip {*}$args]
        }
        foreach poly $p2 {
            set args [list $poly]
            foreach arg $p1 {
                lappend args NOT $arg
            }
            lappend polylist {*}[clip {*}$args]
        }
        if {[llength $polylist] > 1} {
            # OR all of them instead of returning list
            # This is intentionally slower than ideal until ideal approach works
            set exp \{[join $polylist "\} OR \{"]\}
            return [mrfclip::clip {*}$exp]
            # Preferred implementation:
            #   Or first 0..N-1 polygons with the last polygon, letting the
            #   clipping algorithm remove common edges
            #   Currently causes errors (unable to delete element in S)
            #set first [lrange $polylist 0 end-1]
            #set last [lindex $polylist end]
            #return [mrfclip::clip $first OR $last]
        }
    } else {
        lappend polylist {*}[mrfclip $p1 $p2 $op]
    }
    return $polylist
}

proc mrfclip::clip {args} {
    # parse and execute poly clipping expression
    #
    # args
    # args - clipping expression to be parsed
    if {([llength $args] - 1) % 2 != 0} {
        error "argument list is of wrong length"
    }

    # convert inputs to lists of polies and then loop through all combinations

    if {[llength $args] == 3} {
        set p1 [lindex $args 0]
        set p2 [lindex $args 2]
        if {[llength [lindex $p1 0]] == 1} {
            set p1 [list $p1]
        }
        if {[llength [lindex $p2 0]] == 1} {
            set p2 [list $p2]
        }
        set r [multi_clip $p1 $p2 [lindex $args 1]]
        return $r
    } else {
        set p2 [lindex $args end]
        if {[llength [lindex $p2 0]] == 1} {
            set p2 [list $p2]
        }
        set r [multi_clip [clip {*}[lrange $args 0 end-2]] $p2 [lindex $args end-1]]
        return $r
    }
}
