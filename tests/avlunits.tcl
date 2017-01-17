#!/usr/bin/env tclsh

set dir [file dirname [info script]]

lappend auto_path $dir
package require unitt
lappend auto_path [file normalize [file join $dir .. lib]]
package require avltree

unitt init

unitt suite "create_tree" {
    {
        set tree [avltree::create]
        unitt assert_eq [set ${tree}::root] 0
    }
}

unitt suite "insert" {
    {
        set T [avltree::create]
        set n1 [$T insert 1]
        #$T draw
        set n2 [$T insert 2]
        #$T draw
        set n3 [$T insert 3]
        #$T draw

        set nodes [set ${T}::nodes]

        # simple values with direct access
        unitt assert_eq [lindex $nodes 1 0] 1
        unitt assert_eq [lindex $nodes 2 0] 2
        unitt assert_eq [lindex $nodes 3 0] 3

        # values continued
        set root [set ${T}::root]
        unitt assert_eq [lindex $nodes $root 0] 2
        unitt assert_eq [lindex $nodes [lindex $nodes $root 3] 0] 1
        unitt assert_eq [lindex $nodes [lindex $nodes $root 4] 0] 3

        # parents
        unitt assert_eq [lindex $nodes $root 2] "root"
        unitt assert_eq [lindex $nodes [lindex $nodes $root 3] 2] $root
        unitt assert_eq [lindex $nodes [lindex $nodes $root 4] 2] $root
    }
}

unitt suite "delete" {
    {
        # simple 3 node tree
        set T [avltree::create]
        $T insert 1
        $T insert 2
        $T insert 3

        unitt assert_eq [$T delete 1] 1
        unitt assert_eq [$T delete 1] 0
        unitt assert_eq [$T delete 3] 1
        unitt assert_eq [$T delete 3] 0
        unitt assert_eq [$T delete 2] 1
        unitt assert_eq [$T delete 2] 0

        # check actual node values
        set null [lindex [set ${T}::nodes] 0]
        unitt assert_eq [lindex [set ${T}::nodes] 1] $null
        unitt assert_eq [lindex [set ${T}::nodes] 2] $null
        unitt assert_eq [lindex [set ${T}::nodes] 3] $null
        unitt assert_eq [set ${T}::free_nodes] {1 3 2}

        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # orig
        # ----
        #   B
        #  / \
        # A   C <- del
        #    /
        #   D
        #
        # new
        # ---
        #   B
        #  / \
        # A   D
        #
        set T [avltree::create]
        $T insert 1
        $T insert 2
        $T insert 3
        $T insert 2.5

        # delete
        unitt assert_eq [$T delete 3] 1

        set nodes [set ${T}::nodes]
        set null [lindex [set ${T}::nodes] 0]
        set A [lindex $nodes 1]
        set B [lindex $nodes 2]
        set C [lindex $nodes 3]
        set D [lindex $nodes 4]

        # structural integrity
        # values
        unitt assert_eq [lindex $A 0] 1
        unitt assert_eq [lindex $B 0] 2
        unitt assert_eq [lindex $C 0] "NULL"
        unitt assert_eq [lindex $D 0] 2.5
        # balance factors
        unitt assert_eq [lindex $A 1] 0
        unitt assert_eq [lindex $B 1] 0
        unitt assert_eq [lindex $C 1] 0
        unitt assert_eq [lindex $D 1] 0
        # parents
        unitt assert_eq [lindex $A 2] 2
        unitt assert_eq [lindex $B 2] "root"
        unitt assert_eq [lindex $C 2] 0
        unitt assert_eq [lindex $D 2] 2
        # children
        unitt assert_eq [lindex $A 3] 0
        unitt assert_eq [lindex $A 4] 0
        unitt assert_eq [lindex $B 3] 1
        unitt assert_eq [lindex $B 4] 4
        unitt assert_eq [lindex $C 3] 0
        unitt assert_eq [lindex $C 4] 0
        unitt assert_eq [lindex $D 3] 0
        unitt assert_eq [lindex $D 4] 0

        # free nodes
        unitt assert_eq [set ${T}::free_nodes] 3
        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # orig
        # ----
        #   B
        #  / \
        # A   C    <- (del A)
        #    / \
        #   D   E
        #
        # new
        # ---
        #   C
        #  / \
        # B   E
        #  \
        #   D
        #
        set T [avltree::create]
        $T insert 1
        $T insert 2
        $T insert 3
        $T insert 2.5
        $T insert 3.5

        # delete
        unitt assert_eq [$T delete 1] 1

        set nodes [set ${T}::nodes]
        set null [lindex [set ${T}::nodes] 0]
        set A [lindex $nodes 1]
        set B [lindex $nodes 2]
        set C [lindex $nodes 3]
        set D [lindex $nodes 4]
        set E [lindex $nodes 5]

        # structural integrity
        unitt assert_eq $A $null
        unitt assert_eq $B {2 1 3 0 4}
        unitt assert_eq $C {3 -1 root 2 5}
        unitt assert_eq $D {2.5 0 2 0 0}
        unitt assert_eq $E {3.5 0 3 0 0}

        # free nodes
        unitt assert_eq [set ${T}::free_nodes] 1
        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # orig
        # ----
        #   B
        #  / \
        # A   C <- del
        #      \
        #       D
        #
        # new
        # ---
        #   B
        #  / \
        # A   D
        #
        set T [avltree::create]
        $T insert 1
        $T insert 2
        $T insert 3
        $T insert 3.5

        # delete
        unitt assert_eq [$T delete 3] 1

        set nodes [set ${T}::nodes]
        set null [lindex [set ${T}::nodes] 0]
        set A [lindex $nodes 1]
        set B [lindex $nodes 2]
        set C [lindex $nodes 3]
        set D [lindex $nodes 4]

        # structural integrity
        # values
        unitt assert_eq [lindex $A 0] 1
        unitt assert_eq [lindex $B 0] 2
        unitt assert_eq [lindex $C 0] "NULL"
        unitt assert_eq [lindex $D 0] 3.5
        # balance factors
        unitt assert_eq [lindex $A 1] 0
        unitt assert_eq [lindex $B 1] 0
        unitt assert_eq [lindex $C 1] 0
        unitt assert_eq [lindex $D 1] 0
        # parents
        unitt assert_eq [lindex $A 2] 2
        unitt assert_eq [lindex $B 2] "root"
        unitt assert_eq [lindex $C 2] 0
        unitt assert_eq [lindex $D 2] 2
        # children
        unitt assert_eq [lindex $A 3] 0
        unitt assert_eq [lindex $A 4] 0
        unitt assert_eq [lindex $B 3] 1
        unitt assert_eq [lindex $B 4] 4
        unitt assert_eq [lindex $C 3] 0
        unitt assert_eq [lindex $C 4] 0
        unitt assert_eq [lindex $D 3] 0
        unitt assert_eq [lindex $D 4] 0

        # free nodes
        unitt assert_eq [set ${T}::free_nodes] 3
        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # orig
        # ----
        #        A  <- (del A)
        #      /   \
        #     B     C
        #    / \   / \
        #   D   E F   G
        #          \
        #           H
        #
        # new
        # ---
        #        F
        #      /   \
        #     B     C
        #    / \   / \
        #   D   E H   G
        #
        set T [avltree::create]
        $T insert 5         ; # A
        $T insert 2.5       ; # B
        $T insert 7.5       ; # C
        $T insert 1         ; # D
        $T insert 4         ; # E
        $T insert 6         ; # F
        $T insert 9         ; # G
        $T insert 7         ; # H

        # delete
        unitt assert_eq [$T delete 5] 1

        set nodes [set ${T}::nodes]
        set null [lindex [set ${T}::nodes] 0]
        set A [lindex $nodes 1]
        set B [lindex $nodes 2]
        set C [lindex $nodes 3]
        set D [lindex $nodes 4]
        set E [lindex $nodes 5]
        set F [lindex $nodes 6]
        set G [lindex $nodes 7]
        set H [lindex $nodes 8]

        # structural integrity
        unitt assert_eq $A $null
        unitt assert_eq $B {2.5 0 6 4 5}
        unitt assert_eq $C {7.5 0 6 8 7}
        unitt assert_eq $D {1 0 2 0 0}
        unitt assert_eq $E {4 0 2 0 0}
        unitt assert_eq $F {6 0 root 2 3}
        unitt assert_eq $G {9 0 3 0 0}
        unitt assert_eq $H {7 0 3 0 0}

        # free nodes
        unitt assert_eq [set ${T}::free_nodes] 1
        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # orig
        # ----
        #        A
        #      /   \
        #     B     C
        #    / \   / \
        #   D   E F   G  <- (del G)
        #          \
        #           H
        #
        # new
        # ---
        #        A
        #      /   \
        #     B     H
        #    / \   / \
        #   D   E F   C
        #
        set T [avltree::create]
        $T insert 5         ; # A
        $T insert 2.5       ; # B
        $T insert 7.5       ; # C
        $T insert 1         ; # D
        $T insert 4         ; # E
        $T insert 6         ; # F
        $T insert 9         ; # G
        $T insert 7         ; # H

        # delete
        unitt assert_eq [$T delete 9] 1

        set nodes [set ${T}::nodes]
        set null [lindex [set ${T}::nodes] 0]
        set A [lindex $nodes 1]
        set B [lindex $nodes 2]
        set C [lindex $nodes 3]
        set D [lindex $nodes 4]
        set E [lindex $nodes 5]
        set F [lindex $nodes 6]
        set G [lindex $nodes 7]
        set H [lindex $nodes 8]

        # structural integrity
        unitt assert_eq $A {5 0 root 2 8}
        unitt assert_eq $B {2.5 0 1 4 5}
        unitt assert_eq $C {7.5 0 8 0 0}
        unitt assert_eq $D {1 0 2 0 0}
        unitt assert_eq $E {4 0 2 0 0}
        unitt assert_eq $F {6 0 8 0 0}
        unitt assert_eq $G $null
        unitt assert_eq $H {7 0 1 6 3}

        # free nodes
        unitt assert_eq [set ${T}::free_nodes] 7
        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # Random catch-all test
        set T [avltree::create]
        set N 1000
        set vals [list]
        for {set i 0} {$i < $N} {incr i} {
            while {[lsearch $vals [set v [format "%.3f" [expr {rand()*10}]]]] != -1} {}
            lappend vals $v
            $T insert $v
        }
        for {set i 0} {$i < $N} {incr i} {
            set index [expr {round(floor([llength $vals] * rand()))}]
            set v [lindex $vals $index]
            #puts "DEBUG: DELETING VALUE($index) $v"
            #$T draw
            unitt assert_eq [$T delete $v] 1
            set vals [lreplace $vals $index $index]
        }
        unitt assert_eq [llength [set ${T}::free_nodes]] $N
        for {set i 0} {$i < $N} {incr i} {
            unitt assert_eq [lindex [set ${T}::nodes] [expr {$i + 1}]] \
                [lindex [set ${T}::nodes] 0]
        }
    }
}

unitt suite "delete_node" {
    {
        # simple 3 node tree
        set T [avltree::create]
        $T insert 1
        $T insert 2
        $T insert 3

        unitt assert_eq [$T delete_node 1] 1
        unitt assert_eq [$T delete_node 1] 0
        unitt assert_eq [$T delete_node 3] 1
        unitt assert_eq [$T delete_node 3] 0
        unitt assert_eq [$T delete_node 2] 1
        unitt assert_eq [$T delete_node 2] 0

        # check actual node values
        set null [lindex [set ${T}::nodes] 0]
        unitt assert_eq [lindex [set ${T}::nodes] 1] $null
        unitt assert_eq [lindex [set ${T}::nodes] 2] $null
        unitt assert_eq [lindex [set ${T}::nodes] 3] $null
        unitt assert_eq [set ${T}::free_nodes] {1 3 2}

        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # orig
        # ----
        #   B
        #  / \
        # A   C <- del
        #    /
        #   D
        #
        # new
        # ---
        #   B
        #  / \
        # A   D
        #
        set T [avltree::create]
        $T insert 1
        $T insert 2
        $T insert 3
        $T insert 2.5

        # delete
        unitt assert_eq [$T delete_node 3] 1

        set nodes [set ${T}::nodes]
        set null [lindex [set ${T}::nodes] 0]
        set A [lindex $nodes 1]
        set B [lindex $nodes 2]
        set C [lindex $nodes 3]
        set D [lindex $nodes 4]

        # structural integrity
        # values
        unitt assert_eq [lindex $A 0] 1
        unitt assert_eq [lindex $B 0] 2
        unitt assert_eq [lindex $C 0] "NULL"
        unitt assert_eq [lindex $D 0] 2.5
        # balance factors
        unitt assert_eq [lindex $A 1] 0
        unitt assert_eq [lindex $B 1] 0
        unitt assert_eq [lindex $C 1] 0
        unitt assert_eq [lindex $D 1] 0
        # parents
        unitt assert_eq [lindex $A 2] 2
        unitt assert_eq [lindex $B 2] "root"
        unitt assert_eq [lindex $C 2] 0
        unitt assert_eq [lindex $D 2] 2
        # children
        unitt assert_eq [lindex $A 3] 0
        unitt assert_eq [lindex $A 4] 0
        unitt assert_eq [lindex $B 3] 1
        unitt assert_eq [lindex $B 4] 4
        unitt assert_eq [lindex $C 3] 0
        unitt assert_eq [lindex $C 4] 0
        unitt assert_eq [lindex $D 3] 0
        unitt assert_eq [lindex $D 4] 0

        # free nodes
        unitt assert_eq [set ${T}::free_nodes] 3
        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # orig
        # ----
        #   B
        #  / \
        # A   C    <- (del A)
        #    / \
        #   D   E
        #
        # new
        # ---
        #   C
        #  / \
        # B   E
        #  \
        #   D
        #
        set T [avltree::create]
        $T insert 1
        $T insert 2
        $T insert 3
        $T insert 2.5
        $T insert 3.5

        # delete
        unitt assert_eq [$T delete_node 1] 1

        set nodes [set ${T}::nodes]
        set null [lindex [set ${T}::nodes] 0]
        set A [lindex $nodes 1]
        set B [lindex $nodes 2]
        set C [lindex $nodes 3]
        set D [lindex $nodes 4]
        set E [lindex $nodes 5]

        # structural integrity
        unitt assert_eq $A $null
        unitt assert_eq $B {2 1 3 0 4}
        unitt assert_eq $C {3 -1 root 2 5}
        unitt assert_eq $D {2.5 0 2 0 0}
        unitt assert_eq $E {3.5 0 3 0 0}

        # free nodes
        unitt assert_eq [set ${T}::free_nodes] 1
        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # orig
        # ----
        #   B
        #  / \
        # A   C <- del
        #      \
        #       D
        #
        # new
        # ---
        #   B
        #  / \
        # A   D
        #
        set T [avltree::create]
        $T insert 1
        $T insert 2
        $T insert 3
        $T insert 3.5

        # delete
        unitt assert_eq [$T delete_node 3] 1

        set nodes [set ${T}::nodes]
        set null [lindex [set ${T}::nodes] 0]
        set A [lindex $nodes 1]
        set B [lindex $nodes 2]
        set C [lindex $nodes 3]
        set D [lindex $nodes 4]

        # structural integrity
        # values
        unitt assert_eq [lindex $A 0] 1
        unitt assert_eq [lindex $B 0] 2
        unitt assert_eq [lindex $C 0] "NULL"
        unitt assert_eq [lindex $D 0] 3.5
        # balance factors
        unitt assert_eq [lindex $A 1] 0
        unitt assert_eq [lindex $B 1] 0
        unitt assert_eq [lindex $C 1] 0
        unitt assert_eq [lindex $D 1] 0
        # parents
        unitt assert_eq [lindex $A 2] 2
        unitt assert_eq [lindex $B 2] "root"
        unitt assert_eq [lindex $C 2] 0
        unitt assert_eq [lindex $D 2] 2
        # children
        unitt assert_eq [lindex $A 3] 0
        unitt assert_eq [lindex $A 4] 0
        unitt assert_eq [lindex $B 3] 1
        unitt assert_eq [lindex $B 4] 4
        unitt assert_eq [lindex $C 3] 0
        unitt assert_eq [lindex $C 4] 0
        unitt assert_eq [lindex $D 3] 0
        unitt assert_eq [lindex $D 4] 0

        # free nodes
        unitt assert_eq [set ${T}::free_nodes] 3
        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # orig
        # ----
        #        A  <- (del A)
        #      /   \
        #     B     C
        #    / \   / \
        #   D   E F   G
        #          \
        #           H
        #
        # new
        # ---
        #        F
        #      /   \
        #     B     C
        #    / \   / \
        #   D   E H   G
        #
        set T [avltree::create]
        $T insert 5         ; # A
        $T insert 2.5       ; # B
        $T insert 7.5       ; # C
        $T insert 1         ; # D
        $T insert 4         ; # E
        $T insert 6         ; # F
        $T insert 9         ; # G
        $T insert 7         ; # H

        # delete
        unitt assert_eq [$T delete_node 1] 1

        set nodes [set ${T}::nodes]
        set null [lindex [set ${T}::nodes] 0]
        set A [lindex $nodes 1]
        set B [lindex $nodes 2]
        set C [lindex $nodes 3]
        set D [lindex $nodes 4]
        set E [lindex $nodes 5]
        set F [lindex $nodes 6]
        set G [lindex $nodes 7]
        set H [lindex $nodes 8]

        # structural integrity
        unitt assert_eq $A $null
        unitt assert_eq $B {2.5 0 6 4 5}
        unitt assert_eq $C {7.5 0 6 8 7}
        unitt assert_eq $D {1 0 2 0 0}
        unitt assert_eq $E {4 0 2 0 0}
        unitt assert_eq $F {6 0 root 2 3}
        unitt assert_eq $G {9 0 3 0 0}
        unitt assert_eq $H {7 0 3 0 0}

        # free nodes
        unitt assert_eq [set ${T}::free_nodes] 1
        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # orig
        # ----
        #        A
        #      /   \
        #     B     C
        #    / \   / \
        #   D   E F   G  <- (del G)
        #          \
        #           H
        #
        # new
        # ---
        #        A
        #      /   \
        #     B     H
        #    / \   / \
        #   D   E F   C
        #
        set T [avltree::create]
        $T insert 5         ; # A
        $T insert 2.5       ; # B
        $T insert 7.5       ; # C
        $T insert 1         ; # D
        $T insert 4         ; # E
        $T insert 6         ; # F
        $T insert 9         ; # G
        $T insert 7         ; # H

        # delete
        unitt assert_eq [$T delete_node 7] 1

        set nodes [set ${T}::nodes]
        set null [lindex [set ${T}::nodes] 0]
        set A [lindex $nodes 1]
        set B [lindex $nodes 2]
        set C [lindex $nodes 3]
        set D [lindex $nodes 4]
        set E [lindex $nodes 5]
        set F [lindex $nodes 6]
        set G [lindex $nodes 7]
        set H [lindex $nodes 8]

        # structural integrity
        unitt assert_eq $A {5 0 root 2 8}
        unitt assert_eq $B {2.5 0 1 4 5}
        unitt assert_eq $C {7.5 0 8 0 0}
        unitt assert_eq $D {1 0 2 0 0}
        unitt assert_eq $E {4 0 2 0 0}
        unitt assert_eq $F {6 0 8 0 0}
        unitt assert_eq $G $null
        unitt assert_eq $H {7 0 1 6 3}

        # free nodes
        unitt assert_eq [set ${T}::free_nodes] 7
        # null should be preserved
        unitt assert_eq [lindex [set ${T}::nodes] 0] {NULL 0 0 0 0}
    }
    {
        # Random catch-all test
        set T [avltree::create]
        set N 1000
        set vals [list]
        for {set i 0} {$i < $N} {incr i} {
            while {[lsearch $vals [set v [format "%.5f" [expr {rand()*10}]]]] != -1} {}
            lappend vals $v
            $T insert $v
        }
        set deleted_vals [list]
        while {[llength $deleted_vals] < [llength $vals]} {
            set index 10000000
            while {
                [lsearch $deleted_vals \
                [set index [expr {round(floor([llength $vals] * rand()))}]] \
                ] != -1} {}
            lappend deleted_vals $index
            set v [lindex $vals $index]
            unitt assert_eq [$T delete_node [expr {$index + 1}]] 1
        }
        unitt assert_eq [llength [set ${T}::free_nodes]] $N
        for {set i 0} {$i < $N} {incr i} {
            unitt assert_eq [lindex [set ${T}::nodes] [expr {$i + 1}]] \
                [lindex [set ${T}::nodes] 0]
        }
    }
}

unitt suite "find" {
    {
        # find function
        set T [avltree::create]
        $T insert 1
        $T insert 3
        $T insert 2

        unitt assert_eq [$T find 1] 1
        unitt assert_eq [$T find 3] 2
        unitt assert_eq [$T find 2] 3
    }
    {
        # Random catch-all test
        set T [avltree::create]
        set N 1000
        set vals [list]
        for {set i 0} {$i < $N} {incr i} {
            while {[lsearch $vals [set v [format "%.4f" [expr {rand()*10}]]]] != -1} {}
            lappend vals $v
            $T insert $v
        }
        set found_vals [list]
        while {[llength $found_vals] < [llength $vals]} {
            set index [expr {round(floor([llength $vals] * rand()))}]
            set v [lindex $vals $index]
            unitt assert_eq [$T find $v] [expr {$index + 1}]
            lappend found_vals $v
        }
    }
}

unitt suite "xmost_node_value" {
    {
        # random
        set T [avltree::create]
        set N 1000
        set vals [list]
        foreach i [lrepeat $N 0] {
            set v [expr {rand()}]
            $T insert $v
            lappend vals $v
        }
        set sorted_vals [lsort -real -increasing $vals]
        unitt assert_eq [$T leftmost_node] [expr {
            [lsearch $vals [lindex $sorted_vals 0]] + 1
        }]
        unitt assert_eq [$T rightmost_node] [expr {
            [lsearch $vals [lindex $sorted_vals end]] + 1
        }]
        unitt assert_eq [$T leftmost_value] [lindex $sorted_vals 0]
        unitt assert_eq [$T rightmost_value] [lindex $sorted_vals end]
    }
}

unitt suite "node_value_x_of" {
    {
        # node_left_of/right_of
        #
        #        A
        #      /   \
        #     B     C
        #    / \   / \
        #   D   E F   G
        #      /   \
        #     H     I

        set T [avltree::create]
        $T insert 5         ; # A - 1
        $T insert 2         ; # B - 2
        $T insert 8         ; # C - 3
        $T insert 1         ; # D - 4
        $T insert 4         ; # E - 5
        $T insert 6         ; # F - 6
        $T insert 10        ; # G - 7
        $T insert 3         ; # H - 8
        $T insert 7         ; # I - 9

        # node left node
        unitt assert_eq [$T node_left_of_node 7] 3
        unitt assert_eq [$T node_left_of_node 3] 9
        unitt assert_eq [$T node_left_of_node 9] 6
        unitt assert_eq [$T node_left_of_node 6] 1
        unitt assert_eq [$T node_left_of_node 1] 5
        unitt assert_eq [$T node_left_of_node 5] 8
        unitt assert_eq [$T node_left_of_node 8] 2
        unitt assert_eq [$T node_left_of_node 2] 4
        unitt assert_eq [$T node_left_of_node 4] 0

        # node right node
        unitt assert_eq [$T node_right_of_node 4] 2
        unitt assert_eq [$T node_right_of_node 2] 8
        unitt assert_eq [$T node_right_of_node 8] 5
        unitt assert_eq [$T node_right_of_node 5] 1
        unitt assert_eq [$T node_right_of_node 1] 6
        unitt assert_eq [$T node_right_of_node 6] 9
        unitt assert_eq [$T node_right_of_node 9] 3
        unitt assert_eq [$T node_right_of_node 3] 7
        unitt assert_eq [$T node_right_of_node 7] 0

        # value left node
        unitt assert_eq [$T value_left_of_node 7] 8
        unitt assert_eq [$T value_left_of_node 3] 7
        unitt assert_eq [$T value_left_of_node 9] 6
        unitt assert_eq [$T value_left_of_node 6] 5
        unitt assert_eq [$T value_left_of_node 1] 4
        unitt assert_eq [$T value_left_of_node 5] 3
        unitt assert_eq [$T value_left_of_node 8] 2
        unitt assert_eq [$T value_left_of_node 2] 1
        unitt assert_eq [$T value_left_of_node 4] "NULL"

        # value right node
        unitt assert_eq [$T value_right_of_node 4] 2
        unitt assert_eq [$T value_right_of_node 2] 3
        unitt assert_eq [$T value_right_of_node 8] 4
        unitt assert_eq [$T value_right_of_node 5] 5
        unitt assert_eq [$T value_right_of_node 1] 6
        unitt assert_eq [$T value_right_of_node 6] 7
        unitt assert_eq [$T value_right_of_node 9] 8
        unitt assert_eq [$T value_right_of_node 3] 10
        unitt assert_eq [$T value_right_of_node 7] "NULL"

        # value left value
        unitt assert_eq [$T value_left_of_value 10] 8
        unitt assert_eq [$T value_left_of_value 8] 7
        unitt assert_eq [$T value_left_of_value 7] 6
        unitt assert_eq [$T value_left_of_value 6] 5
        unitt assert_eq [$T value_left_of_value 5] 4
        unitt assert_eq [$T value_left_of_value 4] 3
        unitt assert_eq [$T value_left_of_value 3] 2
        unitt assert_eq [$T value_left_of_value 2] 1
        unitt assert_eq [$T value_left_of_value 1] "NULL"

        # value right value
        unitt assert_eq [$T value_right_of_value 1] 2
        unitt assert_eq [$T value_right_of_value 2] 3
        unitt assert_eq [$T value_right_of_value 3] 4
        unitt assert_eq [$T value_right_of_value 4] 5
        unitt assert_eq [$T value_right_of_value 5] 6
        unitt assert_eq [$T value_right_of_value 6] 7
        unitt assert_eq [$T value_right_of_value 7] 8
        unitt assert_eq [$T value_right_of_value 8] 10
        unitt assert_eq [$T value_right_of_value 10] "NULL"
    }
}

unitt suite "pop" {
    {
        # pop left
        set T [avltree::create]
        set N 1000
        set vals [list]
        foreach i [lrepeat $N 0] {
            set v [expr {rand()}]
            $T insert $v
            lappend vals $v
        }
        set sorted_vals [lsort -real -increasing $vals]
        while {[set val [$T pop_leftmost_value]] != "NULL"} {
            unitt assert_eq $val [lindex $sorted_vals 0]
            set sorted_vals [lreplace $sorted_vals 0 0]
        }
        unitt assert_eq [$T pop_leftmost_value] "NULL"
    }
    {
        # pop right
        set T [avltree::create]
        set N 1000
        set vals [list]
        foreach i [lrepeat $N 0] {
            set v [expr {rand()}]
            $T insert $v
            lappend vals $v
        }
        set sorted_vals [lsort -real -increasing $vals]
        while {[set val [$T pop_rightmost_value]] != "NULL"} {
            unitt assert_eq $val [lindex $sorted_vals end]
            set sorted_vals [lreplace $sorted_vals end end]
        }
        unitt assert_eq [$T pop_rightmost_value] "NULL"
    }
    {
        # pop_to_list ascending
        set T [avltree::create]
        set N 1000
        set vals [list]
        foreach i [lrepeat $N 0] {
            set v [expr {rand()}]
            $T insert $v
            lappend vals $v
        }
        set sorted_vals [lsort -real -increasing $vals]
        unitt assert_eq [$T pop_to_list "ascending"] $sorted_vals
        unitt assert_eq [$T pop_to_list] "NULL"
    }
    {
        # pop_to_list descending
        set T [avltree::create]
        set N 1000
        set vals [list]
        foreach i [lrepeat $N 0] {
            set v [expr {rand()}]
            $T insert $v
            lappend vals $v
        }
        set sorted_vals [lsort -real -decreasing $vals]
        unitt assert_eq [$T pop_to_list "descending"] $sorted_vals
        unitt assert_eq [$T pop_to_list] "NULL"
    }
}

unitt suite "to_list" {
    {
        # ascending
        set T [avltree::create]
        set N 1000
        set vals [list]
        foreach i [lrepeat $N 0] {
            set v [expr {rand()}]
            $T insert $v
            lappend vals $v
        }
        set sorted_vals [lsort -real -increasing $vals]
        unitt assert_eq [$T to_list "ascending"] $sorted_vals
        unitt assert_eq [$T leftmost_value] [lindex $sorted_vals 0]
        unitt assert_eq [$T rightmost_value] [lindex $sorted_vals end]
    }
    {
        # descending
        set T [avltree::create]
        set N 1000
        set vals [list]
        foreach i [lrepeat $N 0] {
            set v [expr {rand()}]
            $T insert $v
            lappend vals $v
        }
        set sorted_vals [lsort -real -decreasing $vals]
        unitt assert_eq [$T to_list "descending"] $sorted_vals
        unitt assert_eq [$T leftmost_value] [lindex $sorted_vals end]
        unitt assert_eq [$T rightmost_value] [lindex $sorted_vals 0]
    }
}

unitt summarize
