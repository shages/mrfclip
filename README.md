# mrfclip
[![Build Status](https://api.travis-ci.org/shages/mrfclip.svg?branch=develop)](https://travis-ci.org/shages/mrfclip)

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
- Supports degenerate cases
- Supports holes[*](#known-issues)
- Runs in O((_n_ + _k_) log _n_) time[*](#known-issues), where n is the
number of input vertices and k is the number of intersections

## Examples

<img src="/doc/images/t19/r1_0.png" alt="A AND B" width="860" />

- AND, OR, NOT, and XOR

<img src="/doc/images/t02/r0_2.png" alt="A AND B" width="200" />
<img src="/doc/images/t02/r0_1.png" alt="A OR B" width="200" />
<img src="/doc/images/t02/r0_4.png" alt="A NOT B" width="200" />
<img src="/doc/images/t02/r0_3.png" alt="A XOR B" width="200" />

- Self-intersecting (second image showing holes, though improperly drawn)

<img src="/doc/images/t01/r0_2.png" alt="A AND B" width="200" />
<img src="/doc/images/t01/r0_1.png" alt="A OR B" width="200" />
<img src="/doc/images/t17/r0_2.png" alt="A AND B" width="200" />

- Degenerate

<img src="/doc/images/t15/r3_0.png" alt="A NOT B AND" width="200" />
<img src="/doc/images/t15/r3_2.png" alt="A NOT B AND" width="200" />
<img src="/doc/images/t12/r3_0.png" alt="A NOT B OR C" width="200" />
<img src="/doc/images/t12/r3_1.png" alt="A NOT B OR C" width="200" />

See [Tests](#tests) for more example cases.

## Usage
Clipping is done by forming expressions with `mrfclip::clip`.

```tcl
set poly1 {0 0 0 10 10 10 10 0}
set poly2 {5 5 5 15 15 15 15 5}
set result [mrfclip::clip $poly1 AND $poly2]
# {10.0 10.0 10.0 5.0 5.0 5.0 5.0 10.0}
```

Expressions can be strung together
```tcl
set poly3 {0 2.5 20 2.5 20 7.5 0 7.5}
mrfclip::clip $poly1 AND $poly2 OR $poly3
# {20.0 7.5 20.0 2.5 0.0 2.5 0.0 7.5 5.0 7.5 5.0 10.0 10.0 10.0 10.0 7.5}
```

and embedded
```tcl
mrfclip::clip $poly1 AND [mrfclip::clip $poly2 OR $poly3]
# {10.0 10.0 10.0 2.5 0.0 2.5 0.0 7.5 5.0 7.5 5.0 10.0}
```

Multiple polygon (possibly disjoint) input is supported
```tcl
set poly1 {{0 0 0 10 10 10 10 0} {10 10 10 20 20 20 20 10}}
set poly2 {5 5 5 15 15 15 15 5}
mrfclip::clip $poly1 AND $poly2
# {10.0 10.0 10.0 5.0 5.0 5.0 5.0 10.0} {15.0 15.0 15.0 10.0 10.0 10.0 10.0 15.0}

```

Polygons are clipped strictly left to right. Use command substitution as shown
above to achieve the desired clipping.

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
returned (a _multi-polygon_). For this reason, the return value of
`mrfclip::clip` is always a list of list(s) regardless of the actual result,
and multi-polygons can also be used directly as input to `mrfclip::clip`

## Known Issues
- Polygons with self-overlapping edges are not supported
- While holes are supported as input and output, there is no special
handling when returning holes. Holes and their enclosing polygons are not
associated, and may be returned in any order.
- The last part of the algorithm is currently implemented in
O(n<sup>2</sup>) time in the worst case. The worst case occurs when the
result is a single or few long chain(s). I plan to change the algorithm to
work in O(_n_ log _n_) time or better in the near future.

## Tests
```sh
    cd tests
    make all
    make png
```

See <a href="/tests/README.md">tests/README.md</a> for more details.
