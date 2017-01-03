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
        set tname "::avltree::T[incr counter]"
        namespace eval $tname {
            # core functions
            namespace export destroy
            namespace export compare
            namespace export insert
            namespace export delete
            namespace export find

            # additional functionality
            namespace export rightmost_node
            namespace export leftmost_node
            namespace export rightmost_value
            namespace export leftmost_value

            namespace export pop_leftmost
            #namespace export pop_rightmost
            #namespace export pop_to_list

            #namespace export to_list

            namespace export node_left_of_node
            namespace export node_right_of_node
            namespace export value_left_of_node
            namespace export value_right_of_node
            namespace export value_left_of_value
            namespace export value_right_of_value

            # utility
            namespace export draw
            namespace export get_tree_strings

            namespace ensemble create

            variable root
            variable free_nodes
            variable nodes
            variable NIL

             ######   #######  ########  ########
            ##    ## ##     ## ##     ## ##
            ##       ##     ## ##     ## ##
            ##       ##     ## ########  ######
            ##       ##     ## ##   ##   ##
            ##    ## ##     ## ##    ##  ##
             ######   #######  ##     ## ########

            proc destroy {} {
                namespace delete [namespace current]
            }

            proc compare {a b} {
                # Compare two values. Return 0 if equal, -1 if a < b, and +1 otherwise
                return [expr {$a == $b ? 0 : $a < $b ? -1 : 1}]
            }

            proc rotate {node dir} {
                # Rotate a node left or right
                variable nodes

                set ndir [expr {$dir == 3 ? 4 : 3}]
                set node_data [lindex $nodes $node]
                set parent [lindex $node_data 2]
                set child [lindex $node_data $ndir]
                set child_data [lindex $nodes $child]
                if {$child eq 0} {
                    # this node will be removed from the tree

                    # store this node as a new free node
                    variable free_nodes
                    lappend free_nodes $node

                    # delete it
                    lset nodes $node []
                } else {
                    set grandchild [lindex $nodes $child $dir]

                    set node_data [lreplace $node_data $ndir $ndir $grandchild]
                    lset nodes $node $node_data
                    if {$grandchild ne 0} {
                        set grandchild_data [lindex $nodes $grandchild]
                        lset nodes $grandchild [lreplace $grandchild_data 2 2 $node]
                    }
                    # Don't need to update height since we're now using balance
                    # factor. Don't need to update BF because it's already
                    # been updated
                    #set node_data [lreplace $node_data 1 1 [get_height $node]]
                    set node_data [lreplace $node_data 2 2 $child]
                    lset nodes $node $node_data
                    lset nodes $child [set child_data [lreplace $child_data $dir $dir $node]]
                }
                # Update new root's parent to be the original node's parent
                set child_data [lreplace $child_data 2 2 $parent]
                lset nodes $child $child_data
                # Update original node's parent's child to be new root node
                # find dir first
                if {$parent eq "root"} {
                    variable root
                    set root $child
                } else {
                    set parent_data [lindex $nodes $parent]
                    if {[lindex $nodes $parent 3] == $node} {
                        lset nodes $parent [lreplace $parent_data 3 3 $child]
                    } else {
                        lset nodes $parent [lreplace $parent_data 4 4 $child]
                    }
                }
                return $child
            }

            proc insert_adjust_balance {node dir} {
                # re-balance the tree on insertion
                variable nodes

                # Get child and data
                set node_data [lindex $nodes $node]
                set child [lindex $nodes $node $dir]
                set child_data [lindex $nodes $child]

                set dir_map [expr {$dir == 3 ? -1 : 1}]

                # If the child's balance is tilting the same direction we
                # inserted from here, then we only need to do a single rotation
                set ndir [expr {$dir == 3 ? 4 : 3}]
                if {[lindex $child_data 1] == $dir_map} {
                    # do single rotation
                    lset node_data 1 0
                    lset child_data 1 0
                    lset nodes $node $node_data
                    lset nodes $child $child_data
                    rotate $node $ndir
                } else {
                    # double rotation

                    # 1 - update balance factors
                    # bal == dir_map
                    # dir == dir
                    set grandchild [lindex $child_data $ndir]
                    set grandchild_data [lindex $nodes $grandchild]
                    if {[lindex $grandchild_data 1] == 0} {
                        # bf of grandchild == 0, so others will also be 0
                        lset node_data 1 0
                        lset child_data 1 0
                    } elseif {[lindex $grandchild_data 1] == $dir_map} {
                        lset node_data 1 [expr {$dir_map == -1 ? 1 : -1}]
                        lset child_data 1 0
                    } else {
                        lset node_data 1 0
                        lset child_data 1 $dir_map
                    }
                    # update grandchild to 0 balance regardless
                    lset grandchild_data 1 0

                    # Commit changes
                    lset nodes $node $node_data
                    lset nodes $child $child_data
                    lset nodes $grandchild $grandchild_data

                    # 2 - do rotations
                    rotate $child $dir
                    rotate $node $ndir
                }
                return ""
            }

            proc insert {value} {
                # Insert new node with the specified value
                #
                # Arguments:
                # value         The value to insert
                #
                # Returns
                # node index        The inserted node's index in avltree::nodes
                # -1                Value already exists in tree
                variable root
                variable free_nodes
                variable nodes

                # search for value, starting at the root
                set parent "root"
                set node $root
                set dir_stack [list]
                while {$node != 0} {
                    # haven't found leaf node yet
                    set cval [lindex $nodes $node 0]
                    if {[set comp [compare $value $cval]] == 0} {
                        # duplicate - return early
                        return -1
                    }
                    # Go to left or right child next
                    if {$comp < 0} {
                        set dir 3
                    } else {
                        set dir 4
                    }
                    lappend dir_stack $dir
                    set parent $node
                    set node [lindex $nodes $node $dir]
                }

                # Found leaf, insert with this data:
                set node_data [list $value 0 $parent 0 0]
                # as a new node with parent $parent:
                if {[llength $free_nodes]} {
                    set free_node [lindex $free_nodes end]
                    set free_nodes [lreplace $free_nodes[set free_nodes {}] end end]
                    lset nodes $free_node $node_data
                } else {
                    set free_node [llength $nodes]
                    lappend nodes $node_data
                }
                # and update the parent for this new node
                if {$parent eq "root"} {
                    set root $free_node
                    return $free_node
                } else {
                    set parent_data [lindex $nodes $parent]
                    lset nodes $parent [lreplace $parent_data $dir $dir $free_node]
                }

                # re-balance the tree going up to the root starting at the
                # immediate parent
                set node $parent
                while {$node ne "root"} {
                    # Update balance factor first
                    set node_data [lindex $nodes $node]
                    set bf [lindex $node_data 1]
                    # Based on the direction we came from, update balance factor
                    set dir [lindex $dir_stack end]
                    set dir_stack [lreplace $dir_stack[set dir_stack {}] end end]
                    if {$dir == 3} {
                        # left
                        set nbf [expr {$bf - 1}]
                    } else {
                        set nbf [expr {$bf + 1}]
                    }
                    lset node_data 1 $nbf
                    lset nodes $node $node_data

                    # capture parent index before any tree modification in
                    # case it is re-balanced and changes
                    set parent [lindex $nodes $node 2]

                    if {$nbf == 0} {
                        # Balance factor is now 0, we're done
                        break
                    } elseif {abs($nbf) > 1} {
                        # Re-balance this node and then we'll be done
                        insert_adjust_balance $node $dir
                        break
                    }

                    set node $parent
                }

                # return index of new node
                return $free_node
            }

            proc remove_adjust_balance {node dir} {
                # re-balance the tree on deletion
                variable nodes

                set ndir [expr {$dir == 3 ? 4 : 3}]

                # Get child of opposite direction we went, and data
                set node_data [lindex $nodes $node]
                set child [lindex $nodes $node $ndir]
                set child_data [lindex $nodes $child]

                # flag for early exit
                set done 0

                # map dir to "balance"
                set dir_map [expr {$dir == 3 ? -1 : 1}]
                set ndir_map [expr {$ndir == 3 ? -1 : 1}]

                if {[lindex $child_data 1] == $ndir_map} {
                    # change root balance and n->balance to 0
                    # root = rotate(root, dir)
                    lset node_data 1 0
                    lset child_data 1 0
                    lset nodes $node $node_data
                    lset nodes $child $child_data
                    rotate $node $dir
                } elseif {[lindex $child_data 1] == $dir_map} {
                    # jsw_adjust_balance(root, !dir, -bal)
                    # root = jsw_double(root, dir)
                    # double rotation

                    # 1 - update balance factors
                    set grandchild [lindex $child_data $dir]
                    set grandchild_data [lindex $nodes $grandchild]
                    if {[lindex $grandchild_data 1] == 0} {
                        # bf of grandchild == 0, so others will also be 0
                        lset node_data 1 0
                        lset child_data 1 0
                    } elseif {[lindex $grandchild_data 1] == $ndir_map} {
                        lset node_data 1 $dir_map
                        lset child_data 1 0
                    } else {
                        lset node_data 1 0
                        lset child_data 1 $ndir_map
                    }
                    # update grandchild to 0 balance regardless
                    lset grandchild_data 1 0

                    # Commit changes
                    lset nodes $node $node_data
                    lset nodes $child $child_data
                    lset nodes $grandchild $grandchild_data

                    # 2 - do rotations
                    rotate $child $ndir
                    rotate $node $dir
                } else {
                    # opposite child is already balanced, but will become
                    # unbalanced
                    lset node_data 1 $ndir_map
                    lset child_data 1 $dir_map
                    lset nodes $node $node_data
                    lset nodes $child $child_data
                    rotate $node $dir
                    set done 1
                }

                return $done
            }

            proc delete {value} {
                # Delete a value from the tree
                #
                # Argumets:
                # value         The value to delete
                #
                # Returns:
                # 1             Value was deleted
                # 0             Value was not found
                variable root
                variable free_nodes
                variable nodes

                # search for value, starting at the root
                set parent "root"
                set node $root
                set dir_stack [list]
                while {$node != 0} {
                    set cval [lindex $nodes $node 0]
                    if {[set comp [compare $value $cval]] == 0} {
                        # found
                        break
                    }

                    # Go left or right
                    if {$comp < 0} {
                        set dir 3
                    } else {
                        set dir 4
                    }
                    lappend dir_stack $dir
                    set parent $node
                    set node [lindex $nodes $node $dir]
                }

                # Check if node is 0, and if yes, return early because the
                # value wasn't found
                if {$node == 0} {
                    return 0
                }

                # Remove the node (n_del) with two methods:
                # 1. If one of the children of n_del is NIL, then we simply
                #    need to connect its other child to the parent of n_del
                # 2. If n_del has two real children, find its inorder
                #    successor, swap the values, and reconnect the successor's
                #    child(ren) to its parent
                set node_data [lindex $nodes $node]
                if {[lindex $node_data 3] == 0 || [lindex $node_data 4] == 0} {
                    set dir [expr {[lindex $node_data 3] == 0 ? 4 : 3}]

                    if {[lindex $node_data 2] == "root"} {
                        # Deleting the root node, so reconnect the tree root
                        # pointer
                        set root [lindex $node_data $dir]

                        # update child pointer, but only if not null
                        if {$root != 0} {
                            set child_data [lindex $nodes $root]
                            lset child_data 2 "root"
                            lset nodes $root $child_data
                        }
                    } else {
                        set parent [lindex $node_data 2]
                        set parent_data [lindex $nodes $parent]
                        set child [lindex $node_data $dir]
                        set child_data [lindex $nodes $child]
                        lset parent_data [lindex $dir_stack end] \
                                         $child
                        lset nodes $parent $parent_data
                        if {$child != 0} {
                            lset child_data 2 $parent
                            lset nodes $child $child_data
                        }
                    }
                } else {
                    # get first right child
                    set successor [lindex $node_data 4]
                    # keep tracking directions
                    lappend dir_stack 4

                    # now go left until we hit NULL
                    set successor_data [lindex $nodes $successor]
                    while {[lindex $successor_data 3] != 0} {
                        lappend dir_stack 3
                        set successor [lindex $successor_data 3]
                        set successor_data [lindex $nodes $successor]
                    }

                    # swap the data
                    # NOTE: Take care to not simply swap the data, but rather
                    # to preserve the node pointers so that a user can cache
                    # the node pointer on insertion, and then refer to it
                    # directly at a later time after deletions have occurred
                    # This means we must re-stitch the tree carefully

                    # Reconnect children of $node to $successor
                    set node_cl [lindex $node_data 3]
                    set node_cr [lindex $node_data 4]
                    if {$node_cl != 0} {
                        set node_cl_data [lindex $nodes $node_cl]
                        lset node_cl_data 2 $successor
                        lset nodes $node_cl $node_cl_data
                    }
                    if {$node_cr != 0} {
                        set node_cr_data [lindex $nodes $node_cr]
                        lset node_cr_data 2 $successor
                        lset nodes $node_cr $node_cr_data
                    }

                    # store successor's original parent before we modify it
                    set successor_parent [lindex $successor_data 2]
                    set successor_parent_data [lindex $nodes $successor_parent]

                    # Connect inorder successor parent value
                    # This fixes possible modification from previous statements
                    # if the immediate right child of $node is the inorder
                    # successor
                    set successor_data [lindex $nodes $successor]
                    lset successor_data 2 [lindex $node_data 2]
                    lset nodes $successor $successor_data

                    # Reconnect successor's right child to its parent
                    set successor_child [lindex $successor_data 4]
                    set successor_child_data [lindex $nodes $successor_child]
                    # update child's parent pointer
                    if {$successor_child != 0} {
                        # only if it's not null
                        if {$successor_parent == $node} {
                            # successor is the "new" parent
                            lset successor_child_data 2 $successor
                            lset nodes $successor_child $successor_child_data
                        } else {
                            lset successor_child_data 2 $successor_parent
                            lset nodes $successor_child $successor_child_data
                        }
                    }
                    # update parent's child pointer
                    if {$successor_parent == $node} {
                        # sucessor is the "new" parent
                        lset successor_data 3 [lindex $node_data 3]
                        lset successor_data 4 $successor_child
                        lset nodes $successor $successor_data
                    } else {
                        lset successor_parent_data 3 $successor_child
                        lset nodes $successor_parent $successor_parent_data
                        lset successor_data 3 [lindex $node_data 3]
                        lset successor_data 4 [lindex $node_data 4]
                        lset nodes $successor $successor_data
                    }
                    # update node's parent's child pointer
                    set parent [lindex $node_data 2]
                    if {$parent eq "root"} {
                        set root $successor
                    } else {
                        set parent_data [lindex $nodes $parent]
                        if {[lindex $parent_data 3] == $node} {
                            lset parent_data 3 $successor
                        } else {
                            lset parent_data 4 $successor
                        }
                        lset nodes $parent $parent_data
                    }

                    # Copy (initial) balance factor from node
                    set successor_data [lindex $nodes $successor]
                    lset successor_data 1 [lindex $node_data 1]
                    lset nodes $successor $successor_data
                }

                # free the node
                lset nodes $node [lindex $nodes 0]
                lappend free_nodes $node

                # walk back up the tree
                if {[info exists successor_parent]} {
                    if {$successor_parent == $node} {
                        # start at the successor, since it was a direct
                        # child of $node
                        set node $successor
                    } else {
                        # start at successor's parent if it exists
                        set node $successor_parent
                    }
                } else {
                    # otherwise use node's parent
                    set node $parent
                }
                set done 0
                while {$node ne "root" && !$done} {
                    set node_data [lindex $nodes $node]
                    set bf [lindex $node_data 1]
                    # Based on the direction we came from, update balance
                    # factor
                    set dir [lindex $dir_stack end]
                    set dir_stack [lreplace \
                        $dir_stack[set dir_stack {}] end end]
                    if {$dir == 3} {
                        # left
                        set bf [expr {$bf + 1}]
                    } else {
                        set bf [expr {$bf - 1}]
                    }
                    lset node_data 1 $bf
                    lset nodes $node $node_data

                    # capture parent index before any tree modification in
                    # case it is re-balanced and changes
                    set parent [lindex $node_data 2]

                    if {abs($bf) == 1} {
                        break
                    } elseif {abs($bf) > 1} {
                        set done [remove_adjust_balance $node $dir]
                    }

                    set node $parent
                }
                return 1
            }

            proc find {value} {
                # Find the value in the tree and return its index
                #
                # Arguments:
                # value         The value to find
                #
                # Returns
                # positive integer      The index of the node, found
                # 0                     Null pointer (not found)
                variable root
                variable nodes

                set node $root
                while {$node != 0} {
                    # haven't found leaf node yet
                    set cval [lindex $nodes $node 0]
                    if {[set comp [compare $value $cval]] == 0} {
                        # found it
                        return $node
                    }
                    # Go to left or right child next
                    if {$comp < 0} {
                        set dir 3
                    } else {
                        set dir 4
                    }
                    set node [lindex $nodes $node $dir]
                }
                return 0
            }

             ######    #######   #######  ########  #### ########  ######
            ##    ##  ##     ## ##     ## ##     ##  ##  ##       ##    ##
            ##        ##     ## ##     ## ##     ##  ##  ##       ##
            ##   #### ##     ## ##     ## ##     ##  ##  ######    ######
            ##    ##  ##     ## ##     ## ##     ##  ##  ##             ##
            ##    ##  ##     ## ##     ## ##     ##  ##  ##       ##    ##
             ######    #######   #######  ########  #### ########  ######

            proc xmost_node {node dir} {
                # Return the X-most node in this sub-tree, where X is "left" or
                # "right"
                #
                # Arguments:
                # node          Pointer to sub-tree's root node
                # dir           The direction to traverse (3 = left, 4 = right)
                #
                # Returns:
                # node index    Pointer to the x-most node
                variable nodes
                variable root

                if {$node eq "root"} {
                    set node $root
                }

                while {[lindex $nodes $node $dir] != 0} {
                    set node [lindex $nodes $node $dir]
                }
                return $node
            }

            proc leftmost_node {{node "root"}} {
                # Return the leftmost node in this sub-tree
                #
                # If there are no left children of $node, then $node is returned
                # Uses `xmost_node` to do the heavy lifting
                #
                # Arguments:
                # node      Pointer to sub-tree's root node
                #           If not specified, use the root
                #
                # Returns:
                # node index    Pointer to the leftmost node
                return [xmost_node $node 3]
            }

            proc rightmost_node {{node root}} {
                # Return the rightmost node in this sub-tree
                #
                # If there are no right children of $node, then $node is returned
                # Uses `xmost_node` to do the heavy lifting
                #
                # Arguments:
                # node      Pointer to sub-tree's root node
                #           If not specified, use the root
                #
                # Returns:
                # node index    Pointer to the rightmost node
                return [xmost_node $node 4]
            }

            proc leftmost_value {{node root}} {
                # Return the leftmost value in the tree (the minimum value)
                #
                # Arguments:
                # node      Pointer to sub-tree's root node
                #           If not specified, use the root
                #
                # Returns:
                # value     Value of the leftmost node
                variable nodes
                return [lindex $nodes [xmost_node $node 3] 0]
            }

            proc rightmost_value {{node root}} {
                # Return the rightmost value in the tree (the minimum value)
                #
                # Arguments:
                # node      Pointer to sub-tree's root node
                #           If not specified, use the root
                #
                # Returns:
                # value     Value of the rightmost node
                variable nodes
                return [lindex $nodes [xmost_node $node 4] 0]
            }

            proc node_x_of_node {node dir} {
                # Return the inorder predecessor or successor of this node,
                # depending on the direction specified
                #
                # Arguments:
                # node          Pointer to node to reference from
                # dir           the direction to traverse (3 = left, 4 = right)
                #
                # Returns:
                # node index    Pointer to the node left of this node
                # 0             NULL pointer in case there is no node left of
                #               this node
                variable nodes

                set ndir [expr {$dir == 3 ? 4 : 3}]
                if {[set child [lindex $nodes $node $dir]] != 0} {
                    return [xmost_node $child $ndir]
                }

                # Search parents
                set parent $node
                while {[set parent [lindex $nodes [set node $parent] 2]] != "root"} {
                    if {[lindex $nodes $parent $ndir] == $node} {
                        return $parent
                    }
                }

                return 0
            }

            proc node_left_of_node {node} {
                # Return the inorder predecessor of this node
                #
                # Arguments:
                # node          Pointer to node to reference from
                #
                # Returns:
                # node index    Pointer to the node left of this node
                # 0             NULL pointer in case there is no node left of
                #               this node
                return [node_x_of_node $node 3]
            }

            proc node_right_of_node {node} {
                # Return the inorder successor of this node
                #
                # Arguments:
                # node          Pointer to node to reference from
                #
                # Returns:
                # node index    Pointer to the node right of this node
                # 0             NULL pointer in case there is no node right of
                #               this node
                return [node_x_of_node $node 4]
            }

            proc value_left_of_node {node} {
                # Return value of the inorder predecessor of this node
                #
                # Arguments:
                # node          Pointer to node to reference from
                #
                # Returns:
                # value         Value of the node left of this node
                # NULL          If there is no node left of this node, return
                #               "NULL" as the value
                variable nodes
                return [lindex $nodes [node_x_of_node $node 3] 0]
            }

            proc value_right_of_node {node} {
                # Return value of the inorder successor of this node
                #
                # Arguments:
                # node          Pointer to node to reference from
                #
                # Returns:
                # value         Value of the node right of this node
                # NULL          If there is no node left of this node, return
                #               "NULL" as the value
                variable nodes
                return [lindex $nodes [node_x_of_node $node 4] 0]
            }

            proc value_left_of_value {value} {
                # Return value of the inorder predecessor of the node with the
                # specified value
                #
                # Arguments:
                # value         Value of the node to use as reference
                #
                # Returns:
                # value         Value of the node left of this node
                # NULL          If there is no node left of this node, return
                #               "NULL" as the value
                variable nodes
                return [value_left_of_node [find $value]]
            }

            proc value_right_of_value {value} {
                # Return value of the inorder successor of the node with the
                # specified value
                #
                # Arguments:
                # value         Value of the node to use as reference
                #
                # Returns:
                # value         Value of the node right of this node
                # NULL          If there is no node left of this node, return
                #               "NULL" as the value
                variable nodes
                return [value_right_of_node [find $value]]
            }

            proc pop_leftmost {} {
                # Pop the leftmost node in the tree off the tree and return its
                # value
                #
                # Arguments: none
                #
                # Returns:
                # value         Value of the leftmost node
                # "NULL"        If no nodes exist in the tree
                set value [leftmost_value]
                delete $value
                return $value
            }


            ##     ## ######## #### ##       #### ######## ##    ##
            ##     ##    ##     ##  ##        ##     ##     ##  ##
            ##     ##    ##     ##  ##        ##     ##      ####
            ##     ##    ##     ##  ##        ##     ##       ##
            ##     ##    ##     ##  ##        ##     ##       ##
            ##     ##    ##     ##  ##        ##     ##       ##
             #######     ##    #### ######## ####    ##       ##

            proc draw {{leaf false}} {
                variable root
                foreach line [get_tree_strings $leaf $root] {
                    puts $line
                }
            }

            proc get_tree_strings {{leaf false} {node NULL}} {
                variable nodes
                if {$leaf} {
                    if {$node != 0} {
                        set left_str_list [get_tree_strings $leaf [lindex $nodes $node 3]]
                        set right_str_list [get_tree_strings $leaf [lindex $nodes $node 4]]
                    }
                } else {
                    set CL [lindex $nodes $node 3]
                    set CR [lindex $nodes $node 4]
                    if {$CL != 0} {
                        set left_str_list [get_tree_strings $leaf $CL]
                    }
                    if {$CR != 0} {
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
                set data [lindex $nodes $node]
                lappend r "---${node}:(p=[lindex $data 2]):[lindex $data 1]:[lindex $data 0]"
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


        }
        set ${tname}::NIL [list "NULL" 0 "NIL" "NIL" "NIL"]
        set ${tname}::root 0
        set ${tname}::free_nodes [list]
        set ${tname}::nodes [list [list "NULL" 0 0 0 0]]

        return $tname
    }
}

# New data structures
# Node:
#   List: {value balance parent cleft cright}
# initial vals:
#  { $value 0 "NIL" "NIL" "NIL" }
# NIL node:
#  { "NULL" 0 "NIL" "NIL" "NIL" }
#
#
# Tree:
#  Namespace
#   Variables:
#    tree_root      <int>
#    nodes          <list>
#
# Example:
# insert 2
#  tree::root = 0
#  tree::nodes = {
#                   {2 0 "NIL" "NIL" "NIL"}
#                }
#
# insert 3
#  tree::root = 0
#  tree::nodes = {
#                   {2 1 "NIL" "NIL" 1}
#                   {3 0 0 "NIL" "NIL"}
#                }
#
# insert 4
#  tree::root = 1
#  tree::nodes = {
#                   {2 0 1 "NIL" "NIL"}
#                   {3 0 "NIL" 0 2}
#                   {4 0 1 "NIL" "NIL"}
#                }
#
# delete 2
#  tree::root = 1
#  tree::nodes = {
#                   {}
#                   {3 1 "NIL" "NIL" 2}
#                   {4 0 1 "NIL" "NIL"}
#                }
#
# insert 1
#  tree::root = 1
#  tree::nodes = {
#                   {}
#                   {3 0 "NIL" 3 2}
#                   {4 0 1 "NIL" "NIL"}
#                   {1 0 1 "NIL" "NIL"}
#                }
#
# delete 4
#  tree::root = 1
#  tree::free = {0 2}
#  tree::nodes = {
#                   {}
#                   {3 -1 "NIL" 3 "NIL"}
#                   {}
#                   {1 0 1 "NIL" "NIL"}
#                }
#
# insert 0
#  tree::root = 3
#  tree::free = {0}
#  tree::nodes = {
#                   {}
#                   {3 0 3 "NIL" "NIL"}
#                   {0 0 3 "NIL" "NIL"}
#                   {1 0 "NIL" 2 1}
#                }
#  tree::NIL = {"NULL" 0 "NIL" "NIL" "NIL"}
