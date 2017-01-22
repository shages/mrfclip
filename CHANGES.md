
1.3
===
* Some bug fixes and new tests for self-overlapping edges. Known bugs exist.
* Added ::mrfclip::clip_all proc to apply a single boolean operation to all
  polygons

1.2
===
* Replaced AVL tree with list-based implementation for improved runtime
* Underlying data structures are now cleaned up after clipping
* Various performance enhancements to sweep line loop
* Consecutive duplicate points in input polygons are now gracefully handled
* Exploratory support for self-overlapping edges. There may still be bugs.

1.1
===
* Replaced priority queue with Heap to improve runtime
* Optimized some lookups in S (AVL Tree) to improve runtime
* Fixed XOR runtime to be on-par with other operations

1.0
===
* First release
* Known issues:
  - Polygons with self-overlapping edges are not supported
  - While holes are supported as input and output, there is no special
    handling when returning holes. Holes and their enclosing polygons
    are not associated, and may be returned in any order.
  - The last part of the algorithm is currently implemented in
    O(n<sup>2</sup>) time in the worst case. The worst case occurs when the
    result is a single or few long chain(s). I plan to change the algorithm to
    work in O(_n_ log _n_) time or better in the near future.
  - XOR currently runs in longer time
