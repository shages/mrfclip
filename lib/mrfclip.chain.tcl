
package provide mrfclip::chain 1.1

namespace eval mrfclip {
    namespace eval chain {
        namespace export init
        namespace ensemble create
        variable counter -1
    }
}

proc mrfclip::chain::init {} {
    # Create a chain object (doubly-linked list)
    #
    # Arguments:
    # point     Point object corresponding to chis chain point
    variable counter

    set name "C[incr counter]"
    namespace eval $name {
        variable points {};      # List of points
        variable left NULL;     # Left end point
        variable right NULL;    # Right end point
    }

    return "::mrfclip::chain::$name"
}
