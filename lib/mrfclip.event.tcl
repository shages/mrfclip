
package provide mclip::event 1.0

namespace eval mclip {
    namespace eval event {
        namespace export init
        namespace ensemble create
        variable counter 0
    }
}

proc mclip::event::init {args} {
    # Create a sweep event object (an edge endpoint)
    #
    # A sweep event object tracks the associated edge and various attributes
    #
    # Arguments:
    # point     Pointer to the associated point object
    variable counter

    set name "E${counter}"
    namespace eval $name {
        variable point      ; # mclip::point : point associated with this event
        variable other      NULL ; # mclip::event : other sweep event on this edge
        variable left       ; # bool: is point left or right endpoint of edge?
        variable polytype   ; # SUBJECT | CLIPPING
        variable inout      false ; # bool: inside-outside transition into the poly
        variable inside     false ; # bool: is the edge inside the other polygon?
        variable edgetype   NULL ; # EdgeType: used for overlapping edges
    }

    set ${name}::point [lindex $args 0]
    set ${name}::left [lindex $args 1]
    set ${name}::polytype [lindex $args 2]
    incr counter
    return "::mclip::event::$name"
}
