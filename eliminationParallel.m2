-- DISCLAIMER: This code is the source code of the 
-- elimination package from M2 github. The only change is to use
-- the threaded version of groebner basis.


getIndices = (R,v) -> unique apply(v, index)

eliminateParallel = method()

-- The following was code MES wrote to give to Sottile's group (Spring, 2009).
-- I still want to work this into the eliminateParallel command...
eliminateParallelH = (v,I) -> (
     -- v is a list of variables
     -- I is an ideal
     R := ring I;
     h := local h;
     S := (coefficientRing R)[gens R, h, MonomialSize => 8];
     use R;
     IS := homogenize(sub(trim I,S), h);
     phi := map(R,S,vars R | matrix{{1_R}});
     eS := eliminateParallel(v,IS);
     return trim phi eS;
     )

isFlatPolynomialRing := (R) -> (
     -- R should be a ring
     -- determines if R is a poly ring over ZZ or a field
     kk := coefficientRing R;
     isPolynomialRing R and (kk === ZZ or isField kk)
     )

eliminationRing = (elimvars, R) -> (
     -- input: R: flat polynomial ring
     --        elimvars: list of integer indices of vars to eliminateParallel
     --        homog:Boolean: whether to add another variable for homogenization
     -- output: (F:R-->S, G:S-->R), where S is the new ring
     -- S is the same as R, except that the variables have been permuted, the 
     -- names of the variables are private, and the monomial ordering is an elim order.
     -- If R is a WeylAlgebra, homogenized Weyl algebra, skew commutative ring, or poly
     -- ring, then S will be the same, with the correct multiplication and grading
     keepvars := sort toList(set(0..numgens R-1) - set elimvars);
     perm := join(elimvars,keepvars);
     invperm := inversePermutation perm;
     vars := (options R).Variables;
     degs := (options R).Degrees;
     weyl := (options R).WeylAlgebra;
     skew := (options R).SkewCommutative;
     degs = degs_perm;
     vars = vars_perm;
     M := monoid [vars,MonomialOrder=>Eliminate(#elimvars), Degrees=>degs, 
	  WeylAlgebra => weyl, SkewCommutative => skew, MonomialSize=>16];
     k := coefficientRing R;
     R1 := k M;
     toR1 := map(R1,R,apply(invperm,i->R1_i));
     toR := map(R,R1,apply(perm,i->R_i));
     (toR1,toR)
     )

eliminateParallel1 = (elimindices,I) -> (
     -- at this point, I is an ideal in a flat ring, 
     -- and elimindices represents the variables
     -- to eliminateParallel.
     (toR1,toR) := eliminationRing(elimindices,ring I);
     J := toR1 I;
     if isHomogeneous I then
         (cokernel generators J).cache.poincare = poincare cokernel generators I;
     ideal mingens ideal toR selectInSubring(1,cleanUp(tgb(J,2)))
     )

eliminateParallel (List, Ideal) := (v,I) -> (     
     R := ring I;
     -- if R is a quotient ring, then give error
     if not isFlatPolynomialRing R then
       error "expected a polynomial ring over ZZ or a field";
     if #v === 0 then return I;
     if not all(v, x -> class x === R) then error "expected a list of elements in the ring of the ideal";
     varlist := getIndices(ring I,v);
     eliminateParallel1(varlist, I)
     )

eliminateParallel (Ideal, RingElement) := (I,v) -> eliminateParallel({v},I)
eliminateParallel (Ideal, List) := (I,v) -> eliminateParallel(v,I)
eliminateParallel(RingElement, Ideal) := (v,I) -> eliminateParallel({v},I)