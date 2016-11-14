#!/usr/bin/env tclsh

set dir [file dirname [info script]]

lappend auto_path [file normalize [file join $dir ..]]
package require mclip
lappend auto_path $dir/scripts
package require unitt

unitt::init


unitt::suite "intersect" {
    {
        set L1 {0 0 10 10}
        set L2 {0 10 10 0}
        unitt::assert_eq [mclip::intersect $L1 $L2] {5 5}
    }
    {
        set L1 {0 0 10 10}
        set L2 {0 0 10 0}
        unitt::assert_eq [mclip::intersect $L1 $L2] {0 0}
    }
    {
        # Parallel
        set L1 {0 0 5 5}
        set L2 {0 5 5 10}
        unitt::assert_eq [mclip::intersect $L1 $L2] ""
    }
    {
        # Endpoint intersect, collinear
        set L1 {0 0 5 5}
        set L2 {5 5 10 10}
        unitt::assert_eq [mclip::intersect $L1 $L2] {5 5}
    }
    {
        # Endpoint intersect, collinear
        set L1 {0 0 5 5}
        set L2 {10 10 5 5}
        unitt::assert_eq [mclip::intersect $L1 $L2] {5 5}
    }
    {
        # Endpoint intersect, collinear
        set L1 {5 5 0 0}
        set L2 {10 10 5 5}
        unitt::assert_eq [mclip::intersect $L1 $L2] {5 5}
    }
    {
        # Endpoint intersect, collinear
        set L1 {5 5 0 0}
        set L2 {5 5 10 10}
        unitt::assert_eq [mclip::intersect $L1 $L2] {5 5}
    }
    {
        # Reverse it
        # Endpoint intersect, collinear
        set L1 {0 0 5 5}
        set L2 {5 5 10 10}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5}
    }
    {
        # Endpoint intersect, collinear
        set L1 {0 0 5 5}
        set L2 {10 10 5 5}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5}
    }
    {
        # Endpoint intersect, collinear
        set L1 {5 5 0 0}
        set L2 {10 10 5 5}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5}
    }
    {
        # Endpoint intersect, collinear
        set L1 {5 5 0 0}
        set L2 {5 5 10 10}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5}
    }
    {
        # Collinear - partial overlap R0 R0
        set L1 {0 0 5 5}
        set L2 {4 4 10 10}
        unitt::assert_eq [mclip::intersect $L1 $L2] {4 4 5 5}
    }
    {
        # Collinear - partial overlap R0 R1
        set L1 {0 0 5 5}
        set L2 {10 10 4 4}
        unitt::assert_eq [mclip::intersect $L1 $L2] {4 4 5 5}
    }
    {
        # Collinear - partial overlap R1 R1
        set L1 {5 5 0 0}
        set L2 {10 10 4 4}
        unitt::assert_eq [mclip::intersect $L1 $L2] {4 4 5 5}
    }
    {
        # Collinear - partial overlap R1 R0
        set L1 {5 5 0 0}
        set L2 {4 4 10 10}
        unitt::assert_eq [mclip::intersect $L1 $L2] {4 4 5 5}
    }
    {
        # Reverse it
        # Collinear - partial overlap R0 R0
        set L1 {0 0 5 5}
        set L2 {4 4 10 10}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5 4 4}
    }
    {
        # Collinear - partial overlap R0 R1
        set L1 {0 0 5 5}
        set L2 {10 10 4 4}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5 4 4}
    }
    {
        # Collinear - partial overlap R1 R1
        set L1 {5 5 0 0}
        set L2 {10 10 4 4}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5 4 4}
    }
    {
        # Collinear - partial overlap R1 R0
        set L1 {5 5 0 0}
        set L2 {4 4 10 10}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5 4 4}
    }
    {
        # Collinear - overlap and common endpoint
        set L1 {0 0 5 5}
        set L2 {0 0 10 10}
        unitt::assert_eq [mclip::intersect $L1 $L2] {0 0 5 5}
    }
    {
        # Collinear - overlap and common endpoint
        set L1 {5 5 0 0}
        set L2 {0 0 10 10}
        unitt::assert_eq [mclip::intersect $L1 $L2] {0 0 5 5}
    }
    {
        # Collinear - overlap and common endpoint
        set L1 {5 5 0 0}
        set L2 {10 10 0 0}
        unitt::assert_eq [mclip::intersect $L1 $L2] {0 0 5 5}
    }
    {
        # Collinear - overlap and common endpoint
        set L1 {0 0 5 5}
        set L2 {10 10 0 0}
        unitt::assert_eq [mclip::intersect $L1 $L2] {0 0 5 5}
    }
    {
        # reverse it
        # Collinear - overlap and common endpoint
        set L1 {0 0 5 5}
        set L2 {0 0 10 10}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5 0 0}
    }
    {
        # Collinear - overlap and common endpoint
        set L1 {5 5 0 0}
        set L2 {0 0 10 10}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5 0 0}
    }
    {
        # Collinear - overlap and common endpoint
        set L1 {5 5 0 0}
        set L2 {10 10 0 0}
        unitt::assert_eq [mclip::intersect $L2 $L1] {5 5 0 0}
    }
    {
        # Collinear - overlap and common endpoint
        set L1 {0 0 5 5}
        set L2 {10 10 0 0}
        unitt::assert_eq [mclip::intersect $L2 $L1] {0 0 5 5}
    }
}

unitt::suite "clip" {
    {
        set mclip::queue {}
        set poly1 {{0 0 0 10 10 10 10 0}}
        set poly2 {{5 5 5 15 15 15 15 5}}
        set t [time {mclip::mclip $poly1 $poly2 AND} 10]
        puts "Time: $t"
    }
    {
        set mclip::queue {}
        set poly1 {{0 0 0 10 10 10 10 0}}
        set poly2 $poly1
        set result [mclip::mclip $poly1 $poly2 AND]
        puts "AND RESULT = [lindex $result 0]"
        puts "OR RESULT  = [lindex $result 1]"
    }
    {
        set mclip::queue {}
        set poly1 {{0 0 0 10 10 10 10 0}}
        set poly2 {{5 5 5 15 15 15 15 5}}
        set result [mclip::mclip $poly1 $poly2 AND]
        puts "AND RESULT = [lindex $result 0]"
        puts "OR RESULT  = [lindex $result 1]"
    }
    {
        set mclip::queue {}
        set poly1 {{0 0 0 10 10 10 10 0}}
        set poly2 {{2.5 2.5 7.5 2.5 7.5 7.5 2.5 7.5}}
        set result [mclip::mclip $poly1 $poly2 AND]
        puts "AND RESULT = [lindex $result 0]"
        puts "OR RESULT  = [lindex $result 1]"
    }
}
unitt::suite "event" {
    {
        set e1 [mclip::event init {0 0} true SUBJECT]
        unitt::assert_eq [set ${e1}::point] {0 0}
        unitt::assert_eq [set ${e1}::left] true
        unitt::assert_eq [set ${e1}::polytype] SUBJECT
    }
    {
        set e1 [mclip::event init {0 0} true SUBJECT]
        set e2 [mclip::event init {10 10} false SUBJECT]
        set ${e1}::other $e2
        set ${e2}::other $e1
        unitt::assert_eq [set ${e1}::other] $e2
        unitt::assert_eq [set ${e2}::other] $e1
        unitt::assert_eq [set [set ${e1}::other]::point] {10 10}
        unitt::assert_eq [set [set ${e2}::other]::point] {0 0}
    }
}

unitt::suite "edge" {
    {
        # Create an edge
        set edge [mclip::create_edge [mclip::point init {10 10}] [mclip::point init {0 0}] SUBJECT]
        unitt::assert_eq [set [set [lindex $edge 0]::point]::coord] {10 10}
        unitt::assert_eq [set [lindex $edge 0]::left] 0
        unitt::assert_eq [set [lindex $edge 0]::polytype] SUBJECT
        unitt::assert_eq [set [set [lindex $edge 1]::point]::coord] {0 0}
        unitt::assert_eq [set [lindex $edge 1]::left] 1
        unitt::assert_eq [set [lindex $edge 1]::polytype] SUBJECT
    }
    {
        # Vertical edge
        set edge [mclip::create_edge [mclip::point init {10 10}] [mclip::point init {10 0}] SUBJECT]
        unitt::assert_eq [set [lindex $edge 0]::left] 0
        unitt::assert_eq [set [lindex $edge 1]::left] 1
    }
    {
        # Connected edges with common points
        set edges {}
        set p1 [mclip::point init {0 0}]
        set p2 [mclip::point init {0 5}]
        set p3 [mclip::point init {10 5}]
        lappend edges {*}[mclip::create_edge $p1 $p2 SUBJECT]
        lappend edges {*}[mclip::create_edge $p2 $p3 SUBJECT]
        lappend edges {*}[mclip::create_edge $p3 $p1 SUBJECT]
        set [lindex $edges end]::point [set [lindex $edges 0]::point]
        unitt::assert_eq [set [lindex $edges 1]::point] [set [lindex $edges 2]::point]
        unitt::assert_eq [set [lindex $edges 3]::point] [set [lindex $edges 4]::point]
        unitt::assert_eq [set [lindex $edges 5]::point] [set [lindex $edges 0]::point]
    }
}

unitt::suite "queue" {
    {
        set mclip::queue {}
        set edge1 [mclip::create_edge [mclip::point init {0 0}] [mclip::point init {10 10}] SUBJECT]
        set edge2 [mclip::create_edge [mclip::point init {10 10}] [mclip::point init {-10 10}] SUBJECT]
        set e1 [lindex $edge1 0]
        set e2 [lindex $edge1 1]
        set e3 [lindex $edge2 0]
        set e4 [lindex $edge2 1]
        set q [mclip::queue_insert $e1]
        unitt::assert_eq $q [list $e1]
        set q [mclip::queue_insert $e2]
        unitt::assert_eq $q [list $e1 $e2]
        set q [mclip::queue_insert $e3]
        unitt::assert_eq $q [list $e1 $e2 $e3]
        set q [mclip::queue_insert $e4]
        unitt::assert_eq $q [list $e4 $e1 $e2 $e3]
    }
    {
        # Vertical edge
        set mclip::queue {}
        set events {}
        lappend events {*}[mclip::create_edge [mclip::point init {10 10}] [mclip::point init {10 0}] SUBJECT]
        lappend events {*}[mclip::create_edge [mclip::point init {0 0}] [mclip::point init {10 0}] SUBJECT]
        foreach event $events {
            set q [mclip::queue_insert $event]
        }
        unitt::assert_eq $q \
        [list \
            [lindex $events 2] \
            [lindex $events 3] \
            [lindex $events 1] \
            [lindex $events 0] \
        ]
    }
    {
        # Two left endpoints on same point (vertical edges)
        set mclip::queue {}
        set events {}
        lappend events {*}[mclip::create_edge [mclip::point init {10 10}] [mclip::point init {10 0}] SUBJECT]
        lappend events {*}[mclip::create_edge [mclip::point init {10 20}] [mclip::point init {10 0}] CLIPPING]
        foreach event $events {
            set q [mclip::queue_insert $event]
        }
        # the two right endpoints on the same X should insert simply in the
        # reverse order they are inserted
        unitt::assert_eq $q \
        [list \
            [lindex $events 1] \
            [lindex $events 3] \
            [lindex $events 0] \
            [lindex $events 2] \
        ]
    }
    {
        # Two left endpoints on same x
        set mclip::queue {}
        set events {}
        lappend events {*}[mclip::create_edge [mclip::point init {0 10}] [mclip::point init {10 10}] SUBJECT]
        lappend events {*}[mclip::create_edge [mclip::point init {0 20}] [mclip::point init {10 0}] SUBJECT]
        foreach event $events {
            set q [mclip::queue_insert $event]
        }
        # the two right endpoints on the same X should insert simply in the
        # reverse order they are inserted
        unitt::assert_eq $q \
        [list \
            [lindex $events 0] \
            [lindex $events 2] \
            [lindex $events 3] \
            [lindex $events 1] \
        ]
    }
    {
        # Two left endpoints same horizontal line
        set mclip::queue {}
        set events {}
        lappend events {*}[mclip::create_edge [mclip::point init {0 0}] [mclip::point init {10 0}] SUBJECT]
        lappend events {*}[mclip::create_edge [mclip::point init {0 0}] [mclip::point init {20 0}] SUBJECT]
        foreach event $events {
            set q [mclip::queue_insert $event]
        }
        unitt::assert_eq $q \
        [list \
            [lindex $events 2] \
            [lindex $events 0] \
            [lindex $events 1] \
            [lindex $events 3] \
        ]
    }
}

unitt::suite "poly" {
    {
        # AVL tree priority queue
        # Create a polygon
        set mclip::queue [::avltree::create]
        proc ${mclip::queue}::compare {a b} {
            return [::mclip::compare_events $a $b]
        }
        set poly {5 5 6 8 9 4 7 2}
        set r [mclip::create_poly $poly SUBJECT]
        # indices of poly correpsonding with r
        # r     poly
        # 0     3
        # 1     0
        # 2     0
        # 3     1
        # 4     1
        # 5     2
        # 6     2
        # 7     3

        # 4 edges * 2 endpoints per edge = 8
        #unitt::assert_eq [llength $mclip::queue] 8
        unitt::assert_eq [set [set [lindex $r 0]::point]::coord] {7 2}
        unitt::assert_eq [set [set [lindex $r 1]::point]::coord] {5 5}
        unitt::assert_eq [set [lindex $r 0]::left] 0
        unitt::assert_eq [set [lindex $r 1]::left] 1
        unitt::assert_eq [set [set [lindex $r 2]::point]::coord] {5 5}
        unitt::assert_eq [set [set [lindex $r 3]::point]::coord] {6 8}
        unitt::assert_eq [set [lindex $r 2]::left] 1
        unitt::assert_eq [set [lindex $r 3]::left] 0
        unitt::assert_eq [set [set [lindex $r 4]::point]::coord] {6 8}
        unitt::assert_eq [set [set [lindex $r 5]::point]::coord] {9 4}
        unitt::assert_eq [set [lindex $r 4]::left] 1
        unitt::assert_eq [set [lindex $r 5]::left] 0
        unitt::assert_eq [set [set [lindex $r 6]::point]::coord] {9 4}
        unitt::assert_eq [set [set [lindex $r 7]::point]::coord] {7 2}
        unitt::assert_eq [set [lindex $r 6]::left] 0
        unitt::assert_eq [set [lindex $r 7]::left] 1

        set order {1 2 3 4 0 7 6 5}
        set i -1
        while {[set node [$mclip::queue pop_leftmost]] ne "NULL"} {
            unitt::assert_eq $node [lindex $r [lindex $order [incr i]]]
        }
    }
    {
        # Create a polygon
        set mclip::queue [::avltree::create]
        proc ${mclip::queue}::compare {a b} {
            return [::mclip::compare_events $a $b]
        }
        set poly {0 0 0 10 10 10 10 0}
        set r [mclip::create_poly $poly SUBJECT]
        # indices of poly correpsonding with r
        # r     poly
        # 0     3
        # 1     0
        # 2     0
        # 3     1
        # 4     1
        # 5     2
        # 6     2
        # 7     3

        # 4 edges * 2 endpoints per edge = 8
        unitt::assert_eq [set [set [lindex $r 0]::point]::coord] {10 0}
        unitt::assert_eq [set [set [lindex $r 1]::point]::coord] {0 0}
        unitt::assert_eq [set [set [lindex $r 2]::point]::coord] {0 0}
        unitt::assert_eq [set [set [lindex $r 3]::point]::coord] {0 10}
        unitt::assert_eq [set [set [lindex $r 4]::point]::coord] {0 10}
        unitt::assert_eq [set [set [lindex $r 5]::point]::coord] {10 10}
        unitt::assert_eq [set [set [lindex $r 6]::point]::coord] {10 10}
        unitt::assert_eq [set [set [lindex $r 7]::point]::coord] {10 0}
        set order {1 2 3 4 0 7 6 5}
        set i -1
        while {[set node [$mclip::queue pop_leftmost]] ne "NULL"} {
            unitt::assert_eq $node [lindex $r [lindex $order [incr i]]]
        }

        # number of points should equal number of coordinates
        # provided to create_poly proc
        set points {}
        foreach event $r {
            lappend points [set ${event}::point]
        }
        unitt::assert_eq [llength [lsort -unique $points]] 4
    }
    {
        # Create two polygons
        set mclip::queue [::avltree::create]
        proc ${mclip::queue}::compare {a b} {
            return [::mclip::compare_events $a $b]
        }
        set poly1 {0 0 0 10 10 10 10 0}
        set poly2 {10 0 5 5 10 10 15 5}
        set r1 [mclip::create_poly $poly1 SUBJECT]
        set r2 [mclip::create_poly $poly2 CLIPPING]
        # indices of poly correpsonding with r
        # r     poly
        # 0     3
        # 1     0
        # 2     0
        # 3     1
        # 4     1
        # 5     2
        # 6     2
        # 7     3

        # 4 edges * 2 endpoints per edge = 8
        unitt::assert_eq [set [set [lindex $r1 0]::point]::coord] {10 0}
        unitt::assert_eq [set [set [lindex $r1 1]::point]::coord] {0 0}
        unitt::assert_eq [set [set [lindex $r1 2]::point]::coord] {0 0}
        unitt::assert_eq [set [set [lindex $r1 3]::point]::coord] {0 10}
        unitt::assert_eq [set [set [lindex $r1 4]::point]::coord] {0 10}
        unitt::assert_eq [set [set [lindex $r1 5]::point]::coord] {10 10}
        unitt::assert_eq [set [set [lindex $r1 6]::point]::coord] {10 10}
        unitt::assert_eq [set [set [lindex $r1 7]::point]::coord] {10 0}

        unitt::assert_eq [set [set [lindex $r2 0]::point]::coord] {15 5}
        unitt::assert_eq [set [set [lindex $r2 1]::point]::coord] {10 0}
        unitt::assert_eq [set [set [lindex $r2 2]::point]::coord] {10 0}
        unitt::assert_eq [set [set [lindex $r2 3]::point]::coord] {5 5}
        unitt::assert_eq [set [set [lindex $r2 4]::point]::coord] {5 5}
        unitt::assert_eq [set [set [lindex $r2 5]::point]::coord] {10 10}
        unitt::assert_eq [set [set [lindex $r2 6]::point]::coord] {10 10}
        unitt::assert_eq [set [set [lindex $r2 7]::point]::coord] {15 5}

        set r {}
        lappend r {*}$r1
        lappend r {*}$r2

        #set order {1 2 3 4 0 7 6 5}
        set order {1 2 3 4 11 12 0 10 9 7 6 5 13 14 8 15}
        set i -1
        while {[set node [$mclip::queue pop_leftmost]] ne "NULL"} {
            unitt::assert_eq $node [lindex $r [lindex $order [incr i]]]
        }

        # number of points should equal number of coordinates
        # provided to create_poly proc
        set points {}
        foreach event $r {
            lappend points [set ${event}::point]
        }
        # Number of points currently should be 8, but after merging
        # should be 6
        unitt::assert_eq [llength [lsort -unique $points]] 6
        #unitt::assert_eq [llength [lsort -unique $points]] 8
    }
    {
        # Create two identical polygons
        set mclip::queue [::avltree::create]
        proc ${mclip::queue}::compare {a b} {
            return [::mclip::compare_events $a $b]
        }
        set poly1 {0 0 0 10 10 10 10 0}
        set poly2 $poly1
        set r1 [mclip::create_poly $poly1 SUBJECT]
        set r2 [mclip::create_poly $poly2 CLIPPING]
        # indices of poly correpsonding with r
        # r     poly
        # 0     3
        # 1     0
        # 2     0
        # 3     1
        # 4     1
        # 5     2
        # 6     2
        # 7     3

        # 4 edges * 2 endpoints per edge = 8
        unitt::assert_eq [set [set [lindex $r1 0]::point]::coord] {10 0}
        unitt::assert_eq [set [set [lindex $r1 1]::point]::coord] {0 0}
        unitt::assert_eq [set [set [lindex $r1 2]::point]::coord] {0 0}
        unitt::assert_eq [set [set [lindex $r1 3]::point]::coord] {0 10}
        unitt::assert_eq [set [set [lindex $r1 4]::point]::coord] {0 10}
        unitt::assert_eq [set [set [lindex $r1 5]::point]::coord] {10 10}
        unitt::assert_eq [set [set [lindex $r1 6]::point]::coord] {10 10}
        unitt::assert_eq [set [set [lindex $r1 7]::point]::coord] {10 0}

        unitt::assert_eq [set [set [lindex $r2 0]::point]::coord] {10 0}
        unitt::assert_eq [set [set [lindex $r2 1]::point]::coord] {0 0}
        unitt::assert_eq [set [set [lindex $r2 2]::point]::coord] {0 0}
        unitt::assert_eq [set [set [lindex $r2 3]::point]::coord] {0 10}
        unitt::assert_eq [set [set [lindex $r2 4]::point]::coord] {0 10}
        unitt::assert_eq [set [set [lindex $r2 5]::point]::coord] {10 10}
        unitt::assert_eq [set [set [lindex $r2 6]::point]::coord] {10 10}
        unitt::assert_eq [set [set [lindex $r2 7]::point]::coord] {10 0}

        set r {}
        lappend r {*}$r1
        lappend r {*}$r2

        #set order {1 2 3 4 0 7 6 5}
        set order {1 9 2 10 3 11 4 12 0 8 7 15 6 5 14 13}
        set i -1
        while {[set node [$mclip::queue pop_leftmost]] ne "NULL"} {
            unitt::assert_eq $node [lindex $r [lindex $order [incr i]]]
        }

        # number of points should equal number of coordinates
        # provided to create_poly proc
        set points {}
        foreach event $r {
            lappend points [set ${event}::point]
        }
        # Number of points currently should be 8, but after merging
        # should be 6
        unitt::assert_eq [llength [lsort -unique $points]] 4
        #unitt::assert_eq [llength [lsort -unique $points]] 8
    }
}

unitt::suite "set_inside_flags" {
    {
        # Assume this is S: [e1, e2]
        set e1 [mclip::create_edge [mclip::point init {0 0}] [mclip::point init {10 0}]  SUBJECT]
        set e2 [mclip::create_edge [mclip::point init {0 0}] [mclip::point init {10 10}] SUBJECT]
        set e3 [mclip::create_edge [mclip::point init {0 5}] [mclip::point init {10 20}] CLIPPING]
        mclip::set_inside_flags [lindex $e1 0] ""
        mclip::set_inside_flags [lindex $e2 0] [lindex $e1 0]
        mclip::set_inside_flags [lindex $e3 0] [lindex $e2 0]

        unitt::assert_eq [set [lindex $e1 0]::inside] 0
        unitt::assert_eq [set [lindex $e1 0]::inout] 0
        unitt::assert_eq [set [lindex $e2 0]::inside] 0
        unitt::assert_eq [set [lindex $e2 0]::inout] 1
        unitt::assert_eq [set [lindex $e3 0]::inside] 0
        unitt::assert_eq [set [lindex $e3 0]::inout] 0
    }
}

unitt::suite "point_above_line" {
    {
        # Flat line above
        set point {1 1}
        set line {0 0 10 0}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 1
    }
    {
        # Flat line below
        set point {1 -1}
        set line {0 0 10 0}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] -1
    }
    {
        # Flat line on
        set point {1 0}
        set line {0 0 10 0}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 0
    }
    {
        # Positive slope below
        set point {5 1}
        set line {0 0 10 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] -1
    }
    {
        # Positive slope above
        set point {5 6}
        set line {0 0 10 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 1
    }
    {
        # Positive slope above - reverse coords
        set point {5 6}
        set line {10 10 0 0}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 1
    }
    {
        # Negative slope below
        set point {5 1}
        set line {0 10 10 0}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] -1
    }
    {
        # Negative slope above
        set point {5 6}
        set line {0 10 10 0}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 1
    }
    {
        # Negative slope above - reverse coords
        set point {5 6}
        set line {10 0 0 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 1
    }
    {
        # Negative slope above - floating point
        set point {5.0 5.0001}
        set line {10.0 0.0 0.0 10.0}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 1
    }
    {
        # Negative slope above - outside x coords
        set point {15 6}
        set line {0 10 10 0}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 1
    }
    {
        # Negative slope below - outside x coords
        set point {-15 6}
        set line {0 10 10 0}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] -1
    }
    {
        # Vertical line
        set point {0 5}
        set line {0 0 0 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 0
    }
    {
        # Vertical line - left
        set point {-1 5}
        set line {0 0 0 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] -1
    }
    {
        # Vertical line - right
        set point {1 5}
        set line {0 0 0 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] -1
    }
    {
        # Vertical line - common point
        set point {0 0}
        set line {0 0 0 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 0
    }
    {
        # Nearly vertical line - above
        set point {0.00001 10.001}
        set line {0 0 0.00001 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 1
    }
    {
        # Nearly vertical line - below
        set point {0.00001 9.999}
        set line {0 0 0.00001 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] -1
    }
    {
        # Nearly vertical line - on
        set point {0.00002 20}
        set line {0 0 0.00001 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] 0
    }
    {
        # vertical line
        set point {15 20}
        set line {0 0 0 10}
        unitt::assert_eq [mclip::point_above_line {*}$point {*}$line] -1
    }
}

unitt::suite "S_point_compare" {
    {
        # e1 above e3, should sort bottom->top
        set e1 [mclip::event init [::mclip::point init {5 6}] true SUBJECT]
        set e2 [mclip::event init [::mclip::point init {10 20}] false SUBJECT]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::S_point_compare $e1 $e3] 1
    }
    {
        # e1 below e3, should sort bottom->top
        set e1 [mclip::event init [::mclip::point init {5 4}] true SUBJECT]
        set e2 [mclip::event init [::mclip::point init {10 20}] false SUBJECT]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::S_point_compare $e1 $e3] -1
    }
    {
        # e1 on e3, but e1 other point above e3 other point
        set e1 [mclip::event init [::mclip::point init {5 5}] true SUBJECT]
        set e2 [mclip::event init [::mclip::point init {10 20}] false SUBJECT]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::S_point_compare $e1 $e3] 1
    }
    {
        # e1 on e3, but e1 other point below e3 other point
        set e1 [mclip::event init [::mclip::point init {5 5}] true SUBJECT]
        set e2 [mclip::event init [::mclip::point init {10 0}] false SUBJECT]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::S_point_compare $e1 $e3] -1
    }
    {
        # e1 on e3, and other points collinear, subject first
        set e1 [mclip::event init [::mclip::point init {5 5}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {15 15}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::S_point_compare $e1 $e3] 1
        unitt::assert_eq [mclip::S_point_compare $e3 $e1] -1
    }
    {
        # e1 and e3 are identical segments, subject first ?
        set e1 [mclip::event init [::mclip::point init {0 0}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {10 10}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::S_point_compare $e1 $e3] 1
        unitt::assert_eq [mclip::S_point_compare $e3 $e1] -1
    }
    {
        # vertical line, same left endpoint
        set e1 [mclip::event init [::mclip::point init {0 0}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {0 10}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {20 15}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::S_point_compare $e1 $e3] 1
        unitt::assert_eq [mclip::S_point_compare $e3 $e1] -1
    }
    {
        # vertical line, above/below, same x-coord
        set e1 [mclip::event init [::mclip::point init {0 5}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {0 10}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {20 15}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::S_point_compare $e1 $e3] 1
        unitt::assert_eq [mclip::S_point_compare $e3 $e1] -1
    }
    {
        # vertical line, above/below, diff x-coord
        set e1 [mclip::event init [::mclip::point init {5 6}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {5 10}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::S_point_compare $e1 $e3] 1
        # second assertion questionable?
        unitt::assert_eq [mclip::S_point_compare $e3 $e1] -1
    }
    {
        # vertical line, on, diff x-coord
        # this should theoretically not happen, because e3e4 would have been
        # subdivided before this comparison
        set e1 [mclip::event init [::mclip::point init {5 5}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {5 10}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::S_point_compare $e1 $e3] 1
    }
}

unitt::suite "compare_events" {
    {
        # e1 left of e3, process e1 first
        # e2 left of e4, process e2 first
        set e1 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e2 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {5 15}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {15 15}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::compare_events $e1 $e2] -1
        unitt::assert_eq [mclip::compare_events $e1 $e3] -1
        unitt::assert_eq [mclip::compare_events $e1 $e4] -1
        unitt::assert_eq [mclip::compare_events $e2 $e1] 1
        unitt::assert_eq [mclip::compare_events $e2 $e3] 1
        unitt::assert_eq [mclip::compare_events $e2 $e4] -1
        unitt::assert_eq [mclip::compare_events $e3 $e1] 1
        unitt::assert_eq [mclip::compare_events $e3 $e2] -1
        unitt::assert_eq [mclip::compare_events $e3 $e4] -1
        unitt::assert_eq [mclip::compare_events $e4 $e1] 1
        unitt::assert_eq [mclip::compare_events $e4 $e2] 1
        unitt::assert_eq [mclip::compare_events $e4 $e3] 1
        unitt::assert_eq [mclip::compare_events $e1 $e1] 0
    }
    {
        # Same x-coordinate, process bottom to top
        set e1 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e2 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 15}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {15 15}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::compare_events $e1 $e3] -1
        unitt::assert_eq [mclip::compare_events $e3 $e1] 1
    }
    {
        # Same right endpoints, subject first
        set e1 [mclip::event init [::mclip::point init {0 0}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {10 10}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {5 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {10 10}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::compare_events $e2 $e4] 1
        unitt::assert_eq [mclip::compare_events $e4 $e2] -1
    }
    {
        # One right, one left, same point -> right first
        set e1 [mclip::event init [::mclip::point init {0 0}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {10 10}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {10 10}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {20 10}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::compare_events $e2 $e3] -1
        unitt::assert_eq [mclip::compare_events $e3 $e2] 1
    }
    {
        # Same left endpoint, collinear, subject first
        set e1 [mclip::event init [::mclip::point init {0 0}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {10 10}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {15 15}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::compare_events $e1 $e3] 1
        unitt::assert_eq [mclip::compare_events $e3 $e1] -1
    }
    {
        # Same left endpoint, one line above the other
        set e1 [mclip::event init [::mclip::point init {0 0}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {10 10}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {20 15}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::compare_events $e1 $e3] 1
        unitt::assert_eq [mclip::compare_events $e3 $e1] -1
    }
    {
        # Same left endpoint, vertical line
        set e1 [mclip::event init [::mclip::point init {0 0}] true CLIPPING]
        set e2 [mclip::event init [::mclip::point init {0 10}] false CLIPPING]
        set ${e1}::other $e2
        set ${e2}::other $e1
        set e3 [mclip::event init [::mclip::point init {0 0}] true SUBJECT]
        set e4 [mclip::event init [::mclip::point init {20 15}] false SUBJECT]
        set ${e3}::other $e4
        set ${e4}::other $e3

        unitt::assert_eq [mclip::compare_events $e1 $e3] 1
        unitt::assert_eq [mclip::compare_events $e3 $e1] -1
    }
}

unitt::summarize
