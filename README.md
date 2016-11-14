# mrfclip
A Tcl implementation of the Martinez et al polygon clipping algorithm:
http://www.cs.ucr.edu/~vbz/cs230papers/martinez_boolean.pdf

## Install
Download and directly load into Tcl

    lappend auto_path /path/to/mrfclip
    package require mrfclip

## Features
- Supports the following boolean operations
  * **AND** - intersection
  * **OR** - union
  * **NOT** - difference
  * **XOR** - (A NOT B) OR (B NOT A)
- Supports all degenerate cases
- Runs in O(n log n+k) time, where n is the number of input points and k is
  the number of intersections
  * \*XOR currently runs in longer time
- Partial support for holes

### Known Issues
- Polygons with self-overlapping edges are not currently supported
- Holes have no formal support. Hole polygons are returned, but just as any
  other polygon.


## Examples
- AND, OR, NOT, and XOR

<img src="/doc/images/t02/r0_2.png" alt="A AND B" width="200" />
<img src="/doc/images/t02/r0_1.png" alt="A OR B" width="200" />
<img src="/doc/images/t02/r0_4.png" alt="A NOT B" width="200" />
<img src="/doc/images/t02/r0_3.png" alt="A XOR B" width="200" />
- Self-intersecting (second image showing holes improperly drawn)

<img src="/doc/images/t01/r0_2.png" alt="A AND B" width="200" />
<img src="/doc/images/t01/r0_1.png" alt="A OR B" width="200" />
<img src="/doc/images/t17/r0_2.png" alt="A AND B" width="200" />
- Degenerate

<img src="/doc/images/t15/r3_2.png" alt="A NOT B AND" width="200" />
<img src="/doc/images/t12/r3_1.png" alt="A NOT B OR C" width="200" />

## Usage
Clipping is done by forming expressions with `mrfclip::clip`.

```tcl
set poly1 {0 0 0 10 10 10 10 0}
set poly2 {5 5 5 15 15 15 15 5}
mrfclip::clip $poly1 AND $poly2
```

Expressions can be strung together
```tcl
mrfclip::clip $poly1 OR $poly2 AND $poly3
```

and embedded
```tcl
mrfclip::clip [mrfclip::clip $poly1 OR $poly2] AND $poly3
```

Multiple polygon (possibly disjoint) input is supported
```tcl
set poly1 {{0 0 0 10 10 10 10 0} {10 10 10 20 20 20 20 10}}
set poly2 {5 5 5 15 15 15 15 5}
mrfclip::clip $poly1 AND $poly2
```

Polygons are clipped strictly left to right. Use command substitution as shown above to achieve the desired clipping.

### Polygon Format
Polygons must be specified as a flat list of coordinates.

    set poly {0 0 10 0 10 10 0 10 0 0}

They can be specified in either form:
- **closed**: The first and last coordinate are the same.
```tcl
set closed   {0 0 10 0 10 10 0 10 0 0}
```
- **unclosed**: The first and last coordinate are automatically connected.
```tcl
set unclosed {0 0 10 0 10 10 0 10}
```

The result will always be in unclosed form.

### Multiple Polygons
Clipping may result in multiple polygons, in which case a list of polygons is
returned. For this reason, the return value of `mrfclip::clip` is always a list of list(s) regardless of the actual result.

## Tests
```sh
    cd tests
    make all
    make png
```

See <a href="/tests/README.md">tests/README.md</a> for more details.
