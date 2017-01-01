#!/usr/bin/env tclsh

set dir [file dirname [info script]]

lappend auto_path $dir
package require unitt
lappend auto_path [file normalize [file join $dir ..]]
package require avltree

unitt init

unitt suite "create_tree" {
    {
        set tree [avltree::create]
        unitt assert_eq [set ${tree}::tree_root] "::avltree::node::NIL"
    }
}

unitt suite "insert" {
    {
        set T [avltree::create]
        set n1 [$T insert 1]
        set n2 [$T insert 2]
        set n3 [$T insert 3]

        unitt assert_eq [set ${n1}::value] 1
        unitt assert_eq [set ${n2}::value] 2
        unitt assert_eq [set ${n3}::value] 3

        unitt assert_eq [set ${n1}::parent] $n2
        unitt assert_eq [set ${n2}::parent] "${T}::tree_root"
        unitt assert_eq [set ${n3}::parent] $n2
    }
}

unitt suite "get_leftright" {
    {
        set T [avltree::create]
        foreach n {0 1 2 3 4 5 6 7 8 9} {
            set node${n} [$T insert $n]
        }

        # $T draw
        #        .---N3:1:0:1
        #   .---N4:2:0:2
        #   |   `---N5:1:0:3
        #---N6:4:1:4
        #   |       .---N7:1:0:5
        #   |   .---N8:2:0:6
        #   |   |   `---N9:1:0:7
        #   `---N10:3:0:8
        #       `---N11:2:1:9
        #           `---N12:1:0:10

        unitt assert_eq [set [$T node_left_of  $node0]::value] "NULL"
        unitt assert_eq [set [$T node_right_of $node0]::value] 1
        for {set i 1} {$i < 9} {incr i} {
            unitt assert_eq [set [$T node_left_of [set node${i}]]::value] [expr {$i-1}]
            unitt assert_eq [set [$T node_right_of [set node${i}]]::value] [expr {$i+1}]
        }
        unitt assert_eq [set [$T node_left_of  $node9]::value] 8
        unitt assert_eq [set [$T node_right_of $node9]::value] "NULL"
        unitt assert_eq [$T value_left_of 8] 7
        unitt assert_eq [$T value_right_of 8] 9
        unitt assert_eq [$T value_left_of 9] 8
        unitt assert_eq [$T value_right_of 9] "NULL"
    }
}

unitt suite "to_list" {
    {
        # Insert 100 random numbers and the output list should be equal
        # to the sorted numbers
        # Should run in linear time
        set T [avltree::create]
        set values {}
        for {set i 0} {$i < 100} {incr i} {
            set v [expr {rand()}]
            $T insert $v
            lappend values $v
        }
        unitt assert_eq [$T to_list] [lsort -real -increasing $values]
    }
}

unitt suite "delete" {
    {
        set T [avltree::create]
        unitt assert_eq [set [$T insert 1]::value] 1
        unitt assert_eq [set [$T insert 2]::value] 2
        unitt assert_eq [set [$T insert 3]::value] 3

        unitt assert_eq [$T delete 1] 1
        unitt assert_eq [$T delete 1] 0
        unitt assert_eq [$T delete 3] 1
        unitt assert_eq [$T delete 3] 0
        unitt assert_eq [$T delete 2] 1
        unitt assert_eq [$T delete 2] 0
    }
}

unitt suite "find" {
    {
        # find function
        set T [avltree::create]
        $T insert 1
        $T insert 3
        $T insert 2

        unitt assert_eq [set [$T find 1]::value] 1
        unitt assert_eq [set [$T find 2]::value] 2
        unitt assert_eq [set [$T find 3]::value] 3
    }
    {
        # find_nearest
        set T [avltree::create]
        $T insert 1
        $T insert 3
        $T insert 2

        unitt assert_eq [set [$T find_nearest 0.5]::value] 1
        unitt assert_eq [set [$T find_nearest 1.5]::value] 1
        unitt assert_eq [set [$T find_nearest 2.5]::value] 3
        unitt assert_eq [set [$T find_nearest 3.5]::value] 3
    }
}

unitt suite "getpop_leftrightmost" {
    {
        set T [avltree::create]
        for {set i 0} {$i < 10} {incr i} {
            $T insert [expr {rand()+1}]
        }
        set node2 [$T insert 2]
        set node1 [$T insert 0]
        unitt assert_eq [$T leftmost_node] $node1
        unitt assert_eq [$T rightmost_node] $node2
    }
    {
        set T [avltree::create]
        set nodes {}
        for {set i 0} {$i < 10} {incr i} {
            lappend nodes [set [$T insert [expr {rand()}]]::value]
        }
        set nodes [lsort -real -increasing $nodes]
        for {set i 0} {$i < 10} {incr i} {
            unitt assert_eq [$T pop_leftmost] [lindex $nodes $i]
        }
        unitt assert_eq [$T pop_leftmost] "NULL"
    }
    {
        set T [avltree::create]
        set nodes {}
        for {set i 0} {$i < 10} {incr i} {
            lappend nodes [set [$T insert [expr {rand()}]]::value]
        }
        set nodes [lsort -real -decreasing $nodes]
        for {set i 0} {$i < 10} {incr i} {
            unitt assert_eq [$T pop_rightmost] [lindex $nodes $i]
        }
        unitt assert_eq [$T pop_rightmost] "NULL"
    }
}

unitt summarize
unitt exit
