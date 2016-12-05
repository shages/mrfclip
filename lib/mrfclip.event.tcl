
package provide mrfclip::event 1.1

namespace eval mrfclip {
    namespace eval event {
        namespace export init
        namespace export is_vertical
        namespace ensemble create
        variable counter 0
    }
}

proc mrfclip::event::is_vertical {event} {
    upvar ::mrfclip::epsilon epsilon
    set p1 [set [set ${event}::point]::coord]
    set p2 [set [set [set ${event}::other]::point]::coord]
    return [expr {abs([lindex $p1 0] - [lindex $p2 0]) < $epsilon ? 1 : 0}]
}

proc mrfclip::event::init {args} {
    # Create a sweep event object (an edge endpoint)
    #
    # A sweep event object tracks the associated edge and various attributes
    #
    # Arguments:
    # point     Pointer to the associated point object
    variable counter

    set name "E${counter}"
    namespace eval $name {
        variable point      ; # mrfclip::point : point associated with this event
        variable other      NULL ; # mrfclip::event : other sweep event on this edge
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
    return "::mrfclip::event::$name"
}
