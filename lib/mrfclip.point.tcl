
package provide mrfclip::point 1.1

namespace eval mrfclip {
    namespace eval point {
        namespace export init
        namespace ensemble create
        variable counter -1
    }
}

proc mrfclip::point::init {coord} {
    # Create a point object.
    #
    # Really only necessary for dictionary of chain endpoints
    #
    # Arguments:
    # coord     Coordinate of the point
    variable counter

    set name "P[incr counter]"
    namespace eval $name {
        variable coord      ; # x,y coordinate
        variable events     ; # list of associated events
    }

    set ${name}::coord $coord
    set ${name}::events {}

    return "::mrfclip::point::$name"
}
