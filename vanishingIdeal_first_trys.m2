restart
loadPackage "GraphicalModels"
--G=digraph{{1,3},{1,5},{2,3},{2,4},{3,4},{4,5}}
--G = digraph{{1,3},{1,2}}
R=gaussianRing G
covarianceMatrix R
B=directedEdgesMatrix R
--general case: independent errors (no assumptions on the variances)
Omega=bidirectedEdgesMatrix R
S = transpose(inverse(id_(R^3)-B))*Omega*inverse(id_(R^3)-B)
--After fixing a graph, we can recover all parameters 
--given a sample covariance matrix

--special case: independent errors with equal variances
OmegaSpecial=p_(1,1)*id_(R^3)
S=transpose(inverse(id_(R^3)-B))*OmegaSpecial*inverse(id_(R^3)-B)

--polynomial relations that define the model:
gaussianVanishingIdeal R
-- Double-check that the covariance matrices in the model satisfy these
-- polynomial relationships:
-- s_(1,2): note that the indices in Macaulay2 always start at zero
-- Does the polynomial vanish?
S_(0,1)*S_(0,2)-S_(0,0)*S_(1,2)



R = QQ[l12,l13,l24,l34, s11,s12,s13,s14, s22,s23,s24, s33,s34, s44,MonomialOrder => Eliminate 4];
Lambda = matrix{{1, -l12, -l13, 0},
    {0, 1, 0, -l24},
    {0, 0, 1, -l34},
    {0, 0, 0, 1}};
S = matrix{{s11, s12, s13, s14},
    {s12, s22, s23, s24},
    {s13, s23, s33, s34},
    {s14, s24, s34, s44}};
W = transpose(Lambda)*S*Lambda;
I = ideal{W_(0,1),W_(0,2),W_(0,3),W_(1,2),W_(1,3),W_(2,3)}
Ielim = eliminate({l12,l13,l24,l34},I)

needsPackage "GraphicalModels";
G = digraph {{1,{2,3}},{2,{4}},{3,{4}}};
R = gaussianRing G;
gaussianVanishingIdeal R

-- instead of eliminate we could also calculate the groebnber basis
-- of I. The intersection of I with the ring consisting only of all 
-- the s indeterminants is Ivanish by the definition of the elimination ideal.
-- (for proof see Sul2010 S.54-55)

-- without packages (equal variance case)

-- set up ring and covariance matrix
R = QQ[l12,l13,l21,l23,l31,l32,s11,s12,s13,s22,s23,s33,MonomialOrder => Eliminate 6]
S = matrix{{s11,s12,s13},{s12,s22,s23},{s13,s23,s33}}

-- set up two different graphs
L1 = matrix{{0,0,l13},{l21,0,0},{0,0,0}};
L2 = matrix{{0,l12,0},{0,0,0},{l31,0,0}};

-- calculate vanishing ideals
O1 = transpose(inverse(id_(R^3) - L1)) * S * inverse(id_(R^3) - L1);
O2 = transpose(inverse(id_(R^3) - L2)) * S * inverse(id_(R^3) - L2);
I1 = ideal(O1_(0,1),O1_(0,2),O1_(1,2), O1_(2,2)-O1_(1,1));
I2 = ideal(O2_(0,1),O2_(0,2),O2_(1,2), O2_(2,2)-O2_(1,1));
-- I1 = ideal(O1_(0,1),O1_(0,2),O1_(1,2))
-- I2 = ideal(O2_(0,1),O2_(0,2),O2_(1,2))
Ivan1 = eliminate({l12,l13,l21,l23,l31,l32},I1);
Ivan2 = eliminate({l12,l13,l21,l23,l31,l32},I2);

-- compare
Ivan1 == Ivan2



-- check bug in packages
restart
loadPackage "GraphicalModels"
G = digraph({{2,1},{3,1}})
R = gaussianRing G
directedEdgesMatrix R
gaussianVanishingIdeal R

restart
loadPackage "GraphicalModels"
G = digraph({{1,2},{2,3}})
R = gaussianRing G
directedEdgesMatrix R
gaussianVanishingIdeal R

G1 = digraph({{3,2},{1,2}})
R1 = gaussianRing G1
directedEdgesMatrix R1

G1 = digraph({{3,1}})
R1 = gaussianRing G1
directedEdgesMatrix R1

Ivanish = gaussianVanishingIdeal R





