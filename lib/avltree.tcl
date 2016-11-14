
package require Tcl 8.5

package provide avltree 1.0

namespace eval avltree {
    variable __doc__ "Package for creating and manipulating AVL trees"

    namespace export create
    namespace ensemble create

    variable counter -1

    proc create {} {
        # Instantiate a new Node with value NIL, then return it
        variable counter
        set treename "::avltree::T[incr counter]"
        namespace eval $treename {
            # core API
            namespace export init
            namespace export destroy
            namespace export compare
            namespace export insert
            namespace export delete
            namespace export find
            namespace export find_nearest

            # extras
            namespace export node_left_of
            namespace export node_right_of
            namespace export value_left_of
            namespace export value_right_of
            namespace export leftmost_node
            namespace export rightmost_node
            namespace export pop_leftmost
            namespace export pop_rightmost
            namespace export pop_to_list
            namespace export to_list

            # utility
            namespace export getp
            namespace export draw
            namespace export verify
            namespace ensemble create

            variable tree_root

            proc draw {{leaf false}} {
                variable tree_root
                foreach line [get_tree_strings $leaf $tree_root] {
                    puts $line
                }
            }

            proc get_tree_strings {{leaf false} {node NULL}} {
                if {$leaf} {
                    if {$node ne "::avltree::node::NIL"} {
                        set left_str_list [get_tree_strings $leaf [set ${node}::child_left]]
                        set right_str_list [get_tree_strings $leaf [set ${node}::child_right]]
                    }
                } else {
                    if {[set CL [set ${node}::child_left]] ne "::avltree::node::NIL"} {
                        set left_str_list [get_tree_strings $leaf $CL]
                    }
                    if {[set CR [set ${node}::child_right]] ne "::avltree::node::NIL"} {
                        set right_str_list [get_tree_strings $leaf $CR]
                    }
                }

                set r {}
                if {[info exists left_str_list]} {
                    set p " "
                    foreach str $left_str_list {
                        if {[regexp {^-} $str]} { set p "." }
                        lappend r "   ${p}${str}"
                        if {[regexp {^-} $str]} { set p "|" }
                    }
                }
                lappend r "---[namespace tail $node]:[set ${node}::height]:[get_balance $node]:[set ${node}::value]"
                if {[info exists right_str_list]} {
                    set p "|"
                    foreach str $right_str_list {
                        if {[regexp {^-} $str]} { set p "`" }
                        lappend r "   ${p}${str}"
                        if {[regexp {^-} $str]} { set p " " }
                    }
                }

                return $r
            }

            proc verify {node} {
                if {$node eq "::avltree::node::NIL"} {
                    return 1
                }
                set cl [set ${node}::child_left]
                set cr [set ${node}::child_right]
                set hl [set ${cl}::height]
                set hr [set ${cr}::height]
                set b [expr {$hr - $hl}]

                if {$b < -1 || $b > 1} {
                    puts "ERROR: Node ($node) has balance = $b"
                }
                if {[set ${node}::height] != (1 + max($hl, $hr))} {
                    puts "ERROR: Node ($node) has incorrect height ([set ${node}::height])"
                }

                return [expr {[verify [set ${node}::child_left]] && [verify [set ${node}::child_right]]}]
            }

            proc getp {prop} {
                variable $prop
                return [set $prop]
            }

            proc init {} {
                variable tree_root
                set tree_root ::avltree::node::NIL
            }

            proc get_balance {node} {
                # Return the balance of a given node
                set cl [set ${node}::child_left]
                set cr [set ${node}::child_right]
                return [expr {[set ${cr}::height] - [set ${cl}::height]}]
            }

            proc get_height {node} {
                # Update the height of this node
                return [expr {1 + max( \
                    [set [set ${node}::child_left]::height], \
                    [set [set ${node}::child_right]::height])}]
                }

                proc rotate {root_node LR} {
                    # Rotate a sub-tree

                    set nLR [expr {$LR eq "left" ? "right" : "left"}]
                    set parent      [set ${root_node}::parent]
                    set child       [set ${root_node}::child_${nLR}]
                    set child_child [set [set ${root_node}::child_${nLR}]::child_${LR}]
                    if {$child eq "::avltree::node::NIL"} {
                        # Deleted off the tree
                        #$root_node destroy
                        namespace delete $root_node
                    } else {
                        set ${root_node}::child_${nLR} $child_child
                        set ${child_child}::parent $root_node
                        # update its new height
                        set ${root_node}::height [get_height $root_node]
                        set ${child}::child_${LR} $root_node
                        set ${root_node}::parent $child
                    }
                    set ${child}::parent $parent
                    return $child
                }

                proc adjust_balance {root_node parent_node parent_side} {
                    set bf2 [expr {[get_balance $root_node]/2}]
                    if {$bf2 == -1 || $bf2 == 1} {
                        set LR [expr {$bf2 > 0 ? "left" : "right"}]
                        set nLR [expr {$LR eq "left" ? "right" : "left"}]
                        if {[get_balance [set ${root_node}::child_${nLR}]] == -$bf2} {
                            set ${root_node}::child_${nLR} [rotate [set ${root_node}::child_${nLR}] $nLR]
                        }
                        # Update parent pointer to new, rotated root node
                        if {$parent_node ne "NULL"} {
                            set r [rotate $root_node $LR]
                            if {$parent_side ne "NULL"} {
                                set root_node [set ${parent_node}::child_${parent_side} $r]
                            } else {
                                # Updating the tree root
                                set root_node [set $parent_node $r]
                            }
                        }
                    }
                    if {$root_node ne "::avltree::node::NIL"} {
                        set ${root_node}::height [get_height $root_node]
                    }
                }

                proc compare {a b} {
                    # Compare two values. Return 0 if equal, -1 if a < b, and +1 otherwise
                    return [expr {$a == $b ? 0 : $a < $b ? -1 : 1}]
                }

                proc insert {value {root_node "NULL"} {parent_node "NULL"} {parent_side "NULL"}} {
                    # Insert new node with the specified value
                    #
                    # Arguments:
                    # root_node     The root of the tree to search for elements
                    # value         The value to insert
                    #
                    # Return the new node, otherwise 0 if duplicate value
                    if {$root_node eq "NULL"} {
                        set root_node [namespace current]
                    }
                    if {$root_node eq [namespace current]} {
                        variable tree_root
                        set root_node $tree_root
                        set parent_node [namespace current]::tree_root
                    }
                    set r 0
                    if {$root_node eq "::avltree::node::NIL"} {
                        set root_node [avltree::node init $value]
                        if {$parent_side eq "NULL"} {
                            # tree root
                            set ${parent_node} $root_node
                        } else {
                            # otherwise, update the parent
                            set ${parent_node}::child_${parent_side} $root_node
                        }
                        set ${root_node}::parent $parent_node
                        return $root_node
                    } elseif {[set ${root_node}::value] != $value} {
                        # insert left/right
                        set LR [expr { \
                            [compare $value [set ${root_node}::value]] < 0 ? \
                            "left" : "right"}]
                        set r [insert $value [set ${root_node}::child_${LR}] \
                        $root_node $LR]
                        adjust_balance $root_node $parent_node $parent_side
                    }
                    return $r
                }

                proc find {value {root_node "NULL"}} {
                    if {$root_node eq "NULL"} {
                        set root_node [namespace current]
                    }
                    if {$root_node eq [namespace current]} {
                        variable tree_root
                        set root_node $tree_root
                    }

                    if {$root_node eq "::avltree::node::NIL"} {
                        return ""
                    }
                    return [expr { \
                        [compare $value [set ${root_node}::value]] == 0 ? \
                        $root_node : \
                        [compare $value [set ${root_node}::value]] < 0 ? \
                        [find $value [set ${root_node}::child_left]] : \
                        [find $value [set ${root_node}::child_right]]}]
                }

                proc find_nearest {value {root_node "NULL"} {parent_node "NULL"}} {
                    if {$root_node eq "NULL"} {
                        set root_node [namespace current]
                    }
                    if {$root_node eq [namespace current]} {
                        variable tree_root
                        set root_node $tree_root
                    }

                    if {$root_node eq "::avltree::node::NIL"} {
                        return $parent_node
                    }
                    return [expr { \
                        [compare $value [set ${root_node}::value]] == 0 ? \
                        $root_node : \
                        [compare $value [set ${root_node}::value]] < 0 ? \
                        [find_nearest $value [set ${root_node}::child_left] $root_node] : \
                        [find_nearest $value [set ${root_node}::child_right] $root_node]}]
                }

                proc destroy {} {
                    variable tree_root
                    while {$tree_root ne "::avltree::node::NIL"} {
                        delete [set ${tree_root}::value]
                    }
                    namespace delete [namespace current]
                }

                proc delete {value {root_node "NULL"} {parent_node "NULL"} {parent_side "NULL"}} {
                    # Delete node with matching value within the tree with root root_node
                    #
                    # Arguments:
                    # root_node     The root of the tree to search for elements
                    # value         The value to match for deletion
                    #
                    # Returns 0 if node wasn't found and 1 if node was deleted

                    if {$root_node eq "NULL"} {
                        set root_node [namespace current]
                    }

                    if {$root_node eq [namespace current]} {
                        variable tree_root
                        set root_node $tree_root
                        set parent_node [namespace current]::tree_root
                    }

                    if {${root_node} eq "::avltree::node::NIL"} {
                        # Node wasn't found
                        return 0
                    }

                    set LR "NULL"
                    if {[compare $value [set ${root_node}::value]] == 0} {
                        # rotate
                        set LR [expr {[get_balance $root_node] < 0 ? "right" : "left"}]
                        set root_node [rotate $root_node $LR]
                        if {$parent_side ne "NULL"} {
                            set ${parent_node}::child_${parent_side} $root_node
                        } else {
                            set $parent_node $root_node
                        }
                        if {$root_node eq "::avltree::node::NIL"} {
                            # deleted
                            return 1
                        }
                    }
                    if {$LR eq "NULL"} {
                        set LR [expr {[compare $value [set ${root_node}::value]] < 0 ? "left" : "right"}]
                    }
                    set r [delete $value [set ${root_node}::child_${LR}] $root_node $LR]
                    adjust_balance $root_node $parent_node $parent_side
                    return $r
                }

                proc node_right_of {node} {
                    # Get the node immediate to the right of this node
                    #
                    # Arguments:
                    # node      The node to start from
                    #
                    # Return the immediate right node, otherwise NIL

                    # Search in right child
                    if {[set right [set ${node}::child_right]] ne "::avltree::node::NIL"} {
                        return [leftmost_node $right]
                    }

                    # Search for a parent with a left child and return it
                    set parent $node
                    while {[set parent [set [set node $parent]::parent]] ne "[namespace current]::tree_root"} {
                        if {[set ${parent}::child_left] eq $node} {
                            return $parent
                        }
                    }

                    return "::avltree::node::NIL"
                }

                proc node_left_of {node} {
                    # Get the node immediate to the left of this node
                    #
                    # Arguments:
                    # node      The node to start from
                    #
                    # Return the immediate left node, otherwise NIL

                    if {[set left [set ${node}::child_left]] ne "::avltree::node::NIL"} {
                        # Get the rightmost of this node
                        return [rightmost_node $left]
                    }

                    # Search for a parent with a right child and return it
                    set parent $node
                    while {[set parent [set [set node $parent]::parent]] ne "[namespace current]::tree_root"} {
                        if {[set ${parent}::child_right] eq $node} {
                            return $parent
                        }
                    }

                    return "::avltree::node::NIL"
                }

                proc value_left_of {value} {
                    # Find the node of the specified value, then return its
                    # left node's value
                    set val [find $value]
                    if {$val eq ""} { return }
                    return [set [node_left_of $val]::value]
                }

                proc value_right_of {value} {
                    # Find the node of the specified value, then return its
                    # left node's value
                    set val [find $value]
                    if {$val eq ""} { return }
                    return [set [node_right_of $val]::value]
                }

                proc leftmost_node {{node "NULL"}} {
                    # Return the leftmost node in the tree
                    variable tree_root
                    if {$node eq "NULL"} {
                        set node $tree_root
                    }
                    while {[set [set ${node}::child_left]::value] ne "NULL"} { set node [set ${node}::child_left] }
                    return $node
                }

                proc rightmost_node {{node "NULL"}} {
                    # Return the leftmost node in the tree
                    variable tree_root
                    if {$node eq "NULL"} {
                        set node $tree_root
                    }
                    while {[set [set ${node}::child_right]::value] ne "NULL"} { set node [set ${node}::child_right] }
                    return $node
                }

                proc pop_leftmost {} {
                    return [pop "left"]
                }

                proc pop_rightmost {} {
                    return [pop "right"]
                }

                proc pop {dir {root_node "NULL"} {parent_node "NULL"} {parent_side "NULL"}} {
                    # Delete leftmost node in this tree and return its value
                    #
                    # Arguments:
                    # root_node     The root of the tree to search for elements
                    # value         The value to match for deletion
                    #
                    # Returns 0 if node wasn't found and 1 if node was deleted

                    if {$root_node eq "NULL"} {
                        set root_node [namespace current]
                    }

                    if {$root_node eq [namespace current]} {
                        variable tree_root
                        set root_node $tree_root
                        set parent_node [namespace current]::tree_root
                    }

                    if {${root_node} eq "::avltree::node::NIL"} {
                        # Node wasn't found
                        return "NULL"
                    }

                    if {[set ${root_node}::child_${dir}] eq "::avltree::node::NIL"} {
                        # rotate, but save value first
                        set value [set ${root_node}::value]
                        set LR [expr {[get_balance $root_node] < 0 ? "right" : "left"}]
                        set root_node [rotate $root_node $LR]
                        if {$parent_side ne "NULL"} {
                            set ${parent_node}::child_${parent_side} $root_node
                        } else {
                            set $parent_node $root_node
                        }
                        if {$root_node eq "::avltree::node::NIL"} {
                            # deleted
                            return $value
                        }
                    }

                    set r [pop $dir [set ${root_node}::child_${dir}] $root_node $dir]
                    adjust_balance $root_node $parent_node $parent_side
                    return $r
                }

                proc pop_to_list {{ascending true}} {
                    # Pop the tree into a list and return the list. This
                    # destroys the tree!
                    set this [namespace current]
                    set LR [expr {$ascending == true ? "left" : "right"}]
                    set sorted {}
                    while {[set node [$this pop_${LR}most]] ne "NULL"} {
                        lappend sorted $node
                    }
                    return $sorted
                }

                proc to_list {{root_node "NULL"}} {
                    # Return a list of all nodes' values in their sorted order
                    if {$root_node eq "NULL"} {
                        set root_node [set [namespace current]::tree_root]
                    }

                    if {$root_node eq "::avltree::node::NIL"} {
                        return {}
                    } else {
                        return [list \
                            {*}[to_list [set ${root_node}::child_left]] \
                            [set ${root_node}::value] \
                            {*}[to_list [set ${root_node}::child_right]] \
                        ]
                    }
                }

            }
            $treename init
            return $treename
        }

        namespace eval node {
            namespace export init
            namespace ensemble create
            variable counter -1

            namespace eval NIL {
                variable value NULL
                variable height 0
                variable parent "::avltree::node::NIL"
                variable child_left "::avltree::node::NIL"
                variable child_right "::avltree::node::NIL"
            }

            proc init {value} {
                # Initialize a new node object with the provided value
                #
                # Arguments:
                # value     Initialized value
                variable counter
                set name "N[incr counter]"

                namespace eval $name {
                    variable value
                    variable height      1
                    variable parent "::avltree::node::NIL"
                    variable child_left  "::avltree::node::NIL"
                    variable child_right "::avltree::node::NIL"
                }
                set ${name}::value $value
                return "[namespace current]::$name"
            }
        }
    }
