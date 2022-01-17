-- this file contains code to calculate the 
--   vanishing ideal of a graph with 3 nodes
--   without using the package graphicalModels
-- This follows ALGEBRAIC PROBLEMS IN STRUCTURAL EQUATION MODELING 
--   (Drton 2016) page 29-30
restart

-- gaussian Ring (use eliminate 6 order for elimination later)
R = QQ[l12,l13,l21,l23,l31,l32,s11,s12,s13,s22,s23,s33,MonomialOrder => Eliminate 6]

-- covariance matrix
S = matrix{{s11,s12,s13},{s12,s22,s23},{s13,s23,s33}}

-- directed edges matrix for a graph (l13 is edge 3->1)
L = time matrix{{0,0,l13},{l21,0,0},{0,0,0}}

-- calculate Omega
O = time transpose(inverse(id_(R^3) - L)) * S * inverse(id_(R^3) - L);

-- ideal that vanishes on all non-diagonal entries
I = time ideal({O_(0,1),O_(0,2),O_(1,2)})

-- calculate the vanishing ideal as elimination ideal by eliminating all 
-- occurrences of directed edges matrix
Ivanish = time eliminate({l12,l13,l21,l23,l31,l32},I)


-- *************
-- compare vanisihing ideals of markov equivalent and not markov equivalent graphs
-- *************
-- covariance matrix and gaussian ring same as before
-- set up graphs (L1 markov equivalent to L2 but L3 not equivalent)
L1 = matrix{{0,0,l13},{l21,0,0},{0,0,0}}
L2 = matrix{{0,l12,0},{0,0,0},{l31,0,0}}
L3 = matrix{{0,l12,l13},{0,0,0},{0,0,0}}

-- perform same calculations as above for all graphs
L = L1;
O = transpose(inverse(id_(R^3) - L)) * S * inverse(id_(R^3) - L);
I = ideal({O_(0,1),O_(0,2),O_(1,2)});
Ivanish1 = eliminate({l12,l13,l21,l23,l31,l32},I)
L = L2;
O = transpose(inverse(id_(R^3) - L)) * S * inverse(id_(R^3) - L);
I = ideal({O_(0,1),O_(0,2),O_(1,2)});
Ivanish2 = eliminate({l12,l13,l21,l23,l31,l32},I)
L = L3;
O = transpose(inverse(id_(R^3) - L)) * S * inverse(id_(R^3) - L);
I = ideal({O_(0,1),O_(0,2),O_(1,2)});
Ivanish3 = eliminate({l12,l13,l21,l23,l31,l32},I)

-- compare 
Ivanish1 == Ivanish2  -- expected: true (*)
Ivanish1 == Ivanish3  -- expected: false
-- (*) in general, markoveq does not imply that the vanishing ideals have to be
-- identical, but in this case of 3 nodes we know that Ivanish1 = Ivanish2

-- we can now add equal variance assumptions by adding them to the ideal I
-- e.g. all variances are equal would be
I = ideal({O_(0,1),O_(0,2),O_(1,2), O_(0,0)-O_(1,1), O_(1,1)-O_(2,2)});
Ivanish = eliminate({l12,l13,l21,l23,l31,l32},I)






