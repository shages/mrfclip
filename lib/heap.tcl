
package require Tcl 8.5

package provide heap 1.0

namespace eval heap {
    variable __doc__ "
    Heap package

    Create and destroy binary heap data structures
    "
    namespace export create
    variable counter -1
}

proc heap::create {} {
    # Create a heap data structure object and return its name
    #
    # Arguments: None
    variable counter
    set name "::heap::H[incr counter]"
    namespace eval $name {
        variable __doc__ "
        Heap object
        "
        namespace export insert
        namespace export pop
        namespace export peek
        namespace export compare
        namespace export destroy

        namespace ensemble create

        variable priority_value_separate 1
        variable data {0}           ; # List where data is stored in
        variable len 0              ; # Current length of the heap

        proc insert {args} {
            # Insert a value into the heap based on its priority
            #
            # If [namespace current]::priority_value_separate == 0,
            # then use the value as the priority (similar to BST)
            variable data
            variable len
            variable priority_value_separate

            set value [lindex $args 0]
            set priority [lindex $args $priority_value_separate]

            # Increase heap length now that we're inserting
            incr len
            # Store the new value/priority in the heap at the end
            # Note that ($len-1) is not used because the first value in the
            # heap is index 1, not 0
            # lset data $len $args
            lappend data $args

            # Now traverse 'up' to find the correct index i to insert this data at
            for {set i $len; set j [expr {$i / 2}]} {$i > 1 && [compare $priority [lindex $data $j $priority_value_separate]] < 0} {set i $j; set j [expr {$j / 2}]} {
                # parent node down
                lset data $i [lindex $data $j]
            }
            lset data $i $args
        }

        proc pop {} {
            # Remove the value from the top of the heap and return it
            #
            # Arguments: None
            #
            # Return empty string if heap is empty
            variable priority_value_separate
            variable data
            variable len

            # Return early if heap is empty
            if {$len == 0} {
                return ""
            }

            # Move the last leaf element to the top
            set r [lindex $data 1]
            lset data 1 [lindex $data $len]
            incr len -1
            set i 1
            set k $i
            set j [expr {$i * 2}]
            while {1} {
                if {$j <= $len && [compare [lindex $data $j] [lindex $data $k]] < 0} {
                    set k $j
                }
                if {$j + 1 <= $len && [compare [lindex $data [expr {$j + 1}]] [lindex $data $k]] < 0} {
                    set k [expr {$j + 1}]
                }
                if {$i == $k} {
                    # we're in the right place
                    break
                }
                # Swap i with j
                set tmp [lindex $data $k]
                lset data $k [lindex $data $i]
                lset data $i $tmp
                set i $k
                set j [expr {$i * 2}]
            }
            set data [lreplace $data[set data {}] end end]
            return $r
        }

        proc peek {} {
            # Get the value of the top of this heap and return it
            #
            # Arguments: None
            variable priority_value_separate
            variable data
            return [lindex $data 1 0]
        }

        proc compare {a b} {
            # Compare two values and return whether a is <, >, or = to b
            #
            # Arguments:
            # a     Value to compare with
            # b     Value to compare against
            #
            # Return:
            #  -1   a < b
            #   0   a == b
            #   1   a > b
            return [expr {$a < $b ? -1 : $a == $b ? 0 : 1}]
        }

        proc destroy {} {
            set ns [namespace current]
            namespace delete $ns
        }
    }
    return $name
}
