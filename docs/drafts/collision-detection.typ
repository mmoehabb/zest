#set document(author: "M. E. Abdelsalam", title: "ZNU - Collision Detection")

#set page(paper: "us-letter", columns: 2 )
#show heading: set block(below: 1em, above: 1.1em)
#set par(justify: true, leading: 0.8em, spacing: 2em)

#set align(center)
= ZNU - Collision Detection

#set heading(numbering: "1.")
#set align(left)

= Theory

*Definition 1:* A pointers matrix $M_(r p)$ is a collection of vectors drawn from point _p_ to each point
in rectangular _r_.

*Definition 2:* A point _p_ collides with rectangular _r_ if it lays within the rectangular or on any
of its sides.

*Theory 1:* Let $M_(r p)$ be a pointers matrix of point _p_ and rectangular _r_, _p_ never collides
_r_ if any of $M_(r p)$ columns is sign-consistent.

*Definition 3:* A possible collision point (PCP) of rectangular _r_, is a point that is about to,
or already did, collide with _r_.

*Corollary:* The pointers matrix of a PCP, of some rectangular, doesn't contain a sign-consistent column.

*Theory 2:* Let _p_ be a PCP of a rectangular _r_, _p_ collides _r_ if and only if the circumference
of the resulting retangular, after substituting _p_ to the closest point to it in _r_, is smaller than
or equal to the original one. 

= Implementation

Let $p_1$, $p_2$, $p_2$, ... $p_n$ be arbitrary points in space _s_. And _r_ is a rectangular, in _s_,
which is drawn from points: $r_1$, $r_2$, $r_3$, and $r_4$. In order to classify, so to speak, each point
whether it's a PCP or not, efficiently. We ought to group all their $M_(r p)$ matrices in one big matrix,
that we may call $M_r$.

#align(center)[
	#block(above: 1.75em)[
	$
		M_r =
		mat(
		M_(p_1 x_1), M_(p_1 y_1);
		M_(p_1 x_2), M_(p_1 y_2);
		M_(p_1 x_3), M_(p_1 y_3);
		M_(p_1 x_4), M_(p_1 y_4);
		M_(p_2 x_1), M_(p_2 y_1);
		.;
		.;
		.;
		M_(p_n x_4), M_(p_n y_4)
		)
	$
	]
]

Whereas $M_(r p_i x_k)$ represents the value placed in the first column of the k'th row in the pointers
matrix of the i'th point. Note that the _r_ has been dropped in the matrix above for simplification.

Next we shall normalize this $M_r$ matrix by dividing it over $|M_r|$, which will leave us with a matrix of
positive and negative 1's. Then our objective is to compact and transform this _4n x 2_ matrix into a single
vector with n elements, each of which carries the value 0 or 1. If the i'th element value equals 0, then the
i'th point may collide _r_ (it's considered a PCP), otherwise it should not.

 $
 (M_r)_norm = M_r / norm(M_r)
 $

$
(M_r)_(a g g r) = mat(
1, 1, 1, 1, 0, 0, 0, 0, ...;
0, 0, 0, 0, 1, 1, 1, 1, ...;	
...;
0, 0, 0, 0, ..., 1, 1, 1, 1
)
.
(M_r)_norm
$

$
V_r = floor((M_r)_(a g g r) / 4) . mat(1; 1) = vec(1, 0, 1, ...)
$

Where $V_r$, with length _n_, classifies points; whether they are PCPs or not.
If the i'th value is 0 then $p_i$ is considered a PCP. And note that the floor operation is
applied on the matrix elementwise.

#line(length: 100%)

Let $c_1$, $c_2$, $c_3$, ... $c_k$ be the extracted PCPs of rectangular _r_ from
the previous step, and $V_x$ and $V_y$ be the first and second columns in $M_(r c_i)$,
where $i in {1, 2, ..., k}$.

#align(center)[
$V_l = (V_x dot.o.big V_x) + (V_y dot.o.big V_y)$ \
$s(V_l)$ = index of the smallest row value
]

Recall that $M_(r c_i)$ is being calculated from subtracting the point $c_i$ from the matrix
representation of _r_:

$
r = mat(
r_(x 1), r_(y 1);
r_(x 2), r_(y 2);
r_(x 3), r_(y 3);
r_(x 4), r_(y 4);
)
$

Where each row in the matrix has the x and y values of one point of the rectangular. And
the points are sorted, in the matrix, in a way that if each point get subtracted from the one
that follows it, and the last point get subtracted from the first one, we shall wind up with
a collection of four vectors that form a valid rectangular together.

Now, if we substitute the point at index $s(V_l)$ by point $c_i$, we should wind up with a different
rectangular that has a larger circumference if and only if $c_i$ does not collide _r_.

$
r_(c_i) = mat(
r_(x 1), r_(y 1);
c_(i_x), c_(i_y);
r_(x 3), r_(y 3);
r_(x 4), r_(y 4);
)
$

If $c i r c(r) - c i r c(r_(c_i)) >= 0$, then the point $c_i$ collides rectangular _r_.

\ \
= Example

Now, let's see it in action. We will draw a simple example here that consists of four rectangulars:
A, B, C, and D. Then we will detect collisions to C using the aforementioned approach.

// --- SCALE CONTROLS ---
#let unit = 0.8cm        // Grid unit scaling factor
#let max-x = 8          // Max units on X axis
#let max-y = 6          // Max units on Y axis

#let chart-width = max-x * unit
#let chart-height = max-y * unit

#align(center)[
  #box(width: chart-width + unit, height: chart-height + unit)[
    
    // Scaled positioning helper function
    #let plot(x, y, body) = place(
      top + left,
      dx: x * unit,
      dy: chart-height - (y * unit), 
      body
    )

    // 1. Draw Scaled Axis Lines
    #place(top + left, dx: 0cm, dy: 0cm, line(start: (0cm, chart-height), end: (0cm, 0cm), stroke: 1pt)) 
    #place(top + left, dx: 0cm, dy: chart-height, line(start: (0cm, 0cm), end: (chart-width, 0cm), stroke: 1pt)) 

    // 2. Axis Labels
    #plot(-0.1, max-y + 0.4, [Y])
    #plot(max-x + 0.4, -0.1, [X])

    // 3. Dynamic X-Axis Metrics
    #for x in range(1, max-x + 1) {
      plot(x, 0, line(start: (0cm, 0cm), end: (0cm, 0.15cm), stroke: 1pt))
      plot(x - 0.1, -0.4, text(size: 9pt)[#x])
    }

    // 4. Dynamic Y-Axis Metrics
    #for y in range(1, max-y + 1) {
      plot(0, y, line(start: (0cm, 0cm), end: (-0.15cm, 0cm), stroke: 1pt))
      plot(-0.4, y - 0.15, text(size: 9pt)[#y])
    }

    // 5. A (Red Rectangle)
    #plot(1, 2.5)[
      #rect(width: 2 * unit, height: 1.5 * unit, stroke: red + 1pt, fill: red.lighten(80%), radius: 2pt)[
        #align(center + horizon)[A]
      ]
    ]

    // 6. Blue (Custom Irregular Shape)
    // Anchored at top-left envelope (4, 4.5) spanning to (6.5, 2.0)
    #plot(4, 4.5)[
      #place(top + left)[
        #polygon(
          stroke: blue + 1pt, 
          fill: blue.lighten(80%),
          (0 * unit, 0 * unit),         // Top-Left (Chart: 4.0, 4.5)
          (2.5 * unit, 0 * unit),       // Top-Right (Chart: 6.5, 4.5)
          (1.5 * unit, 1.5 * unit),     // Bottom-Right TILTED UP & LEFT (Chart: 5.5, 2.7)
          (0 * unit, 2.5 * unit),       // Bottom-Left (Chart: 4.0, 2.0)
        )
      ]
      #place(top + left, dx: 0.6 * unit, dy: 0.8 * unit)[C]
    ]

    // 7. Green (Solid border, Colliding into the Blue Object)
    // Moves from x=2.5 to x=4.5 (overlapping blue by 0.5 units horizontally)
    #plot(2.5, 4.0)[
      #rect(width: 2 * unit, height: 1 * unit, stroke: green + 1pt, fill: green.lighten(85%), radius: 2pt)[
        #align(center + horizon)[B]
      ]
    ]

    // 8. New Orange (Placed near the tilted side of the blue Object)
    #plot(5, 2.5)[
      #rect(width: 2 * unit, height: 1.5 * unit, stroke: orange + 1pt, fill: orange.lighten(80%), radius: 2pt)[
        #align(center + horizon)[D]
      ]
    ]
  ]
]

$
r_a &= mat(
    1, 1;
    1, 2.5;
    3, 2.5;
    3, 1;
)
wide wide &
r_b &= mat(
    2.5, 3;
    2.5, 4;
    4.5, 4;
    4.5, 3;
) \
r_c &= mat(
    4, 2;
    4, 4.5;
    6.5, 4.5;
    5.5, 3;
)
wide wide &
r_d &= mat(
    5, 1;
    5, 2.5;
    7, 2.5;
    7, 1;
)
$

Let P (Points) be an $n times 2$ matrix that contains all the points in the space, except
the rectangular _c_ ones. And then let $P_d$ (Points Duplicated) be a $4n times 2$ matrix of
all the points duplicated three times as elaborated in the sections above.

$
M_(r_c) =
mat(
    4, 2;
    4, 4.5;
    6.5, 4.5;
    5.5, 3;
    dots.v;
    5.5, 3;
)
-
P_d
=
mat(
    3, 1;
    3, 3.5;
    5.5, 3.5;
    4.5, 2;
    dots.v;
)
$

Note: it's starting from point (1, 1) in $r_a$.

#pagebreak()

#line(length: 100%)

For the sake of readability, in this document, let's examine only the parts of the matrix
appertain to the three, obvious, PCP points on the diagram above. 

$
r_(b 3) &= mat(
   -0.5, -2;
   -0.5, 0.5;
   2, 0.5;
   1, -1;
)

wide wide &

r_(b 4) &= mat(
   -0.5, -1;
   -0.5, 1.5;
   2, 1.5;
   1, 0;
)
$

$
r_(d 2) &= mat(
   -1, -0.5;
   -1, 2;
   1.5, 2;
   0.5, 0.5;
)
$

It's clear that each point of these three is considered PCP according to _theory 1_;
no single column, of the above matrices, is sign-consistent.

#line(length: 100%)

After normalizing, aggregating, dividing by 4, and then apply dot product from the right
by $mat(1, 1)$. We get a single vector concluding that only three points are considered
PCPs: $r_(b 3)$, $r_(b 4)$, and $r_(d 2)$.

Lastly, we shall apply the circumference method to only these three points in order to
determine if eachone does collide or not with $r_c$.

...