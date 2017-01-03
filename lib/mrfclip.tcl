
package require Tcl 8.5

package require avltree
package require heap
package require mrfclip::point
package require mrfclip::event
package require mrfclip::chain
package provide mrfclip 1.1

namespace eval mrfclip {
    namespace export mrfclip
    namespace export clip

    variable queue {}; # list of sweep events (mrfclip::event), priority queue
    variable epsilon 0.00000000001
}

proc mrfclip::coords_equal {a b} {
    variable epsilon
    return [expr { \
        abs([lindex $a 0] - [lindex $b 0]) < $epsilon \
        && abs([lindex $a 1] - [lindex $b 1]) < $epsilon \
    }]
}

proc mrfclip::point_above_line {ax ay bx by cx cy} {
    # check if a point is above or below the speified line
    # the point could be a left or right endpoint
    #
    # B and C MUST be pre-sorted:
    #   Bx < Cx, elseif (Bx == Cx) By < Cy
    #
    # This sorting is already done elsewhere in the algorithm, so don't
    # do it here
    #
    # arguments:
    # point     the point (x,y coords) to test
    # line      the line (two points) to test against
    #
    # returns:
    # 1  - above
    # 0  - on
    # -1 - below

    # cross product gives us signed parallelogram area
    #   don't need actual triangle area, as positive/negative is sufficient
    #   to determine above/below
    #
    # | (ax - bx) (ay - by) |
    # | (cx - bx) (cy - by) |
    # A x B = (ax - bx) * (cy - by) - (cx - bx) * (ay - by)
    #       = ax*cy - ax*by - bx*cy + bx*by - cx*ay + cx*by + ay*bx - bx*by
    #                                 X                               X
    #       = ax*cy - ax*by - bx*cy - cx*ay + cx*by + ay*bx
    #
    # negate to get a "above" bc line
    #
    #      => -ax*cy + ax*by + bx*cy + cx*ay - cx*by - ay*bx
    variable epsilon

    set c [expr { $cx*$ay - $bx*$ay + $ax*$by - $cx*$by - $ax*$cy + $bx*$cy}]
    return [expr {abs($c) < $epsilon ? 0 : $c < -$epsilon ? -1 : 1}]
}

proc mrfclip::S_point_compare {a b} {
    # If 'a' should be ordered before 'b,' return -1, otherwise return 1
    # If a is the same edge as b, return 0
    #
    # Sort first by y-coordinate intersecting the sweep line
    variable epsilon

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

proc mrfclip::compare_events {a b} {
    # Return:
    #   -1 if a should be before b
    #   +1 if b should be before a
    #    0 if the events are identical
    variable epsilon

    # Identical events
    if {$a eq $b} { return 0 }

    # Convert all points to floating point
    set apoint [set [set ${a}::point]::coord]
    set ax [lindex $apoint 0]
    set ay [lindex $apoint 1]
    set bpoint [set [set ${b}::point]::coord]
    set bx [lindex $bpoint 0]
    set by [lindex $bpoint 1]

    # Sort left to right
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
        set alx [lindex $aleft 0]
        set aly [lindex $aleft 1]
        set blx [lindex $bleft 0]
        set bly [lindex $bleft 1]

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

proc mrfclip::create_edge {p1 p2 polytype} {
    # Create an edge by instantiating two sweep events with properties
    #
    # Arguments:
    # p1    The "first" point object of the edge
    # p2    The other point object of the edge
    # polytype  The poly this edge belongs to (SUBJECT | CLIPPING)
    #
    # Return a list of two sweep events in the same order as p1 & p2
    variable epsilon

    # Check which point is left of the other
    set p1x [lindex [set ${p1}::coord] 0]
    set p1y [lindex [set ${p1}::coord] 1]
    set p2x [lindex [set ${p2}::coord] 0]
    set p2y [lindex [set ${p2}::coord] 1]
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

    # Unclose closed poly
    if {[lindex $poly 0] == [lindex $poly end-1] \
        && [lindex $poly 1] == [lindex $poly end]} {
        set poly [lrange $poly 0 end-2]
    }

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

    # Return the events (only for testing)
    return $events
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
        set ${curr_event}::inside [expr {[::mrfclip::event is_vertical $prev_event] ? [set ${prev_event}::inout] : ![set ${prev_event}::inout]}]
        set ${curr_event}::inout [set ${prev_event}::inside]
    }
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
                set common_point [set ${left1}::point]

                set ner [::mrfclip::event init $common_point false [set ${left2}::polytype]]
                set nel [::mrfclip::event init $common_point true [set ${left2}::polytype]]

                set ${ner}::other $left2
                set ${nel}::other [set ${left2}::other]
                set [set ${left2}::other]::other $nel
                set ${left2}::other $ner
                set left2 $nel
                $queue insert $nel
                $queue insert $ner
            } else {
                set common_point [set ${left2}::point]

                set ner [::mrfclip::event init $common_point false [set ${left1}::polytype]]
                set nel [::mrfclip::event init $common_point true [set ${left1}::polytype]]

                set ${ner}::other $left1
                set ${nel}::other [set ${left1}::other]
                set [set ${left1}::other]::other $nel
                set ${left1}::other $ner
                set left1 $nel
                $queue insert $nel
                $queue insert $ner
            }
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
                set common_point [set [set ${left1}::other]::point]

                set ner [::mrfclip::event init $common_point false [set ${left2}::polytype]]
                set nel [::mrfclip::event init $common_point true [set ${left2}::polytype]]

                set ${ner}::other $left2
                set ${nel}::other [set ${left2}::other]
                set [set ${left2}::other]::other $nel
                set ${left2}::other $ner
                $queue insert $nel
                $queue insert $ner
            } else {
                set common_point [set [set ${left2}::other]::point]

                set ner [::mrfclip::event init $common_point false [set ${left1}::polytype]]
                set nel [::mrfclip::event init $common_point true [set ${left1}::polytype]]

                set ${ner}::other $left1
                set ${nel}::other [set ${left1}::other]
                set [set ${left1}::other]::other $nel
                set ${left1}::other $ner
                $queue insert $nel
                $queue insert $ner
            }
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

    # Create priority queue
    set queue [::heap::create]
    set ${queue}::priority_value_separate 0
    # Bind compare proc
    proc ${queue}::compare {a b} {
        return [::mrfclip::compare_events $a $b]
    }

    # Create polygons and populate the priority queue
    # inputs "subject" and "clipping" should be multi-polygons
    foreach sub $subject {
        create_poly $sub SUBJECT
    }
    foreach clip $clipping {
        create_poly $clip CLIPPING
    }

    # Initialize Sweep line AVL BST and bind compare proc
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

    # Lists containing resulting segments with Point objects
    set intersection_psegs {}
    set union_psegs {}
    set diff_psegs {}
    set xor_psegs {}

    # Sweep through events
    set previous_event ""
    while {[set event [$queue pop]] ne ""} {
        # Merge common points, which will always be adjacent in priority queue
        # Points must be common for chain connection later to lookup by
        # dictionary
        if {$previous_event ne "" && [coords_equal [set [set ${event}::point]::coord] [set [set ${previous_event}::point]::coord]]} {
            set ${event}::point [set ${previous_event}::point]
        }

        # Detect an infinite loop and break early
        # This happens if deleting from AVL tree fails
        if {$event eq $previous_event} {
            puts "FATAL: Infinite loop detected"
            puts "DEBUG: event line:
            ([lindex [set [set ${event}::point]::coord] 0], [lindex [set [set ${event}::point]::coord] 1])
            ([lindex [set [set [set ${event}::other]::point]::coord] 0], [lindex [set [set [set ${event}::other]::point]::coord] 1])
            "
            error "infinite loop"
        }

        if {[set ${event}::left]} {
            # left event
            # Insert into S
            set node [$S insert $event]

            # Get adjacent nodes to check for intersection
            set prev [set [$S node_left_of $node]::value]
            set next [set [$S node_right_of $node]::value]

            # Set flags for the event
            set_inside_flags $event $prev

            # Check for intersections
            possible_inter $event $prev
            possible_inter $event $next
        } else {
            # right event
            # Get the corresponding left event in S
            set other [set ${event}::other]

            # Get adjacent events to check for intersection after this event
            # is removed
            set node [$S find $other]
            set prev [set [$S node_left_of $node]::value]
            set next [set [$S node_right_of $node]::value]

            # Capture this segment for the appropriate operations
            set segment [list [set ${other}::point] [set ${event}::point]]
            if {[set ${other}::edgetype] eq "SAME_TRANSITION"} {
                lappend intersection_psegs $segment
                lappend union_psegs $segment
            } elseif {[set ${other}::edgetype] eq "DIFFERENT_TRANSITION"} {
                lappend diff_psegs $segment
            } elseif {[set ${other}::edgetype] eq "NON_CONTRIBUTING"} {
            } else {
                if {[set ${other}::inside]} {
                    if {[set ${other}::polytype] eq "CLIPPING"} {
                        lappend diff_psegs $segment
                    }
                    lappend intersection_psegs $segment
                } else {
                    if {[set ${other}::polytype] eq "SUBJECT"} {
                        lappend diff_psegs $segment
                    }
                    lappend union_psegs $segment
                }
            }

            # Capture all non-overlapping segments for XOR
            if {[set ${other}::edgetype] eq "NULL"} {
                lappend xor_psegs $segment
            }

            # Remove event from S
            if {[$S delete $other] == 0} {
                puts "ERROR: Couldn't delete: $other. Result will likely be wrong."
                puts "  coord = [set [set ${other}::point]::coord]"
            }

            # Check for intersections of new neighbors
            possible_inter $prev $next
        }
        set previous_event $event
    }

    # Create and connect chains of segments into polygons
    switch $operation {
        "AND" { set polygons [::mrfclip::create_chains $intersection_psegs] }
        "OR"  { set polygons [::mrfclip::create_chains $union_psegs] }
        "NOT" { set polygons [::mrfclip::create_chains $diff_psegs] }
        "XOR" { set polygons [::mrfclip::create_chains $xor_psegs] }
    }

    # Cleanup
    $queue destroy
    $S destroy
    namespace delete {*}[namespace children ::mrfclip::event]
    namespace delete {*}[namespace children ::mrfclip::point]
    namespace delete {*}[namespace children ::mrfclip::chain]

    return $polygons
}

proc mrfclip::convert_poly_to_multi_poly {poly} {
    # Convert polygon to a multi-polygon
    #
    # Arguments:
    # poly      Polygon or multi-polygon
    #
    # If a multi-polygon is provided, it won't be changed
    if {[llength [lindex $poly 0]] == 1} {
        return [list $poly]
    }
    return $poly
}

proc ::mrfclip::show_help {} {
    # Return help string
    return "
    ::mrfclip::clip - Clip polygons from an expression

    Usage:
      ::mrfclip::clip \$poly1 op \$poly2 \[.. op \$polyN\]

    where 'op' is one of the following clipping operations:
    AND, OR, NOT, XOR

    Example:
      ::mrfclip::clip \$poly1 OR \$poly2 AND \$poly3
    "
}

proc mrfclip::clip {args} {
    # parse and execute poly clipping expression
    #
    # Arguments:
    # args      clipping expression to be parsed
    if {([llength $args] - 1) % 2 != 0} {
        puts "ERROR: Argument list is of wrong length
        [show_help]"
        return
    }

    if {[llength $args] == 3} {
        set p1 [convert_poly_to_multi_poly [lindex $args 0]]
        set p2 [convert_poly_to_multi_poly [lindex $args 2]]
        return [mrfclip $p1 $p2 [lindex $args 1]]
    } else {
        set p2 [convert_poly_to_multi_poly [lindex $args end]]
        return [mrfclip [clip {*}[lrange $args 0 end-2]] $p2 [lindex $args end-1]]
    }
}
