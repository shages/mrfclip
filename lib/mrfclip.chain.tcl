
package provide mclip::chain 1.0

namespace eval mclip {
    namespace eval chain {
        namespace export init
        namespace ensemble create
        variable counter -1
    }
}

proc mclip::chain::init {} {
    # Create a chain object (doubly-linked list)
    #
    # Arguments:
    # point     Point object corresponding to chis chain point
    variable counter

    set name "C[incr counter]"
    namespace eval $name {
        variable points {};        # List of points
        variable left NULL;     # Left end point
        variable right NULL;    # Right end point
    }

    return "::mclip::chain::$name"
}
