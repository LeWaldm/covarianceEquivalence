-- requires package 
needsPackage "GraphicalModels"
needsPackage "DeterminantalRepresentations"

-- setup (automize later)
n = 3
R = QQ[l_12,l_13,l_21,l_23,l_31,l_32,s_11,s_12,s_13,s_22,s_23,s_33,MonomialOrder => Eliminate 6]
S = matrix{{s_11,s_12,s_13},{s_12,s_22,s_23},{s_13,s_23,s_33}}
Lfull = matrix({{0,l_12,l_13},{l_21,0,l_23},{l_31,l_32,0}})
toEliminate = {l_12,l_13,l_21,l_23,l_31,l_32}
assumptions = {R,S,Lfull,n,toEliminate}

-- main function
vanishingIdeal = args -> (

    -- we expect list assumptions 
    R = assumptions_0;
    S = assumptions_1;
    Lfull = assumptions_2;
    n = assumptions_3;
    toEliminate = assumptions_4;

    -- handle input
    if #args == 0 then error("Need a Digraph as first argument!");
    if instance(args,Digraph) then (
        g = args;
        equalVarGroups = {};
    ) else (
    if #args == 2 then(
        g = args_0;
        equalVarGroups = args_1;           
    ) else (
    if #args > 2 then error("Too many arguments!");
    ););
    L = hadamard(Lfull,adjacencyMatrix(reindexBy(g,"sort")));

    -- calculate vanishing ideal   
    -- calculate Omega
    O = transpose(id_(R^3) - L) * S * (id_(R^3) - L);
    
    -- compute polynomials from assumption: no bidirected edges
    assNoBidirectedEdges = {};
    for i from 0 to n-2 do (
    	for j from i+1 to n-1 do (
    	    assNoBidirectedEdges = join(assNoBidirectedEdges,{O_(i,j)});
    	)
    );
    
    -- compute polynomials from additional assumption about equal variance groups
    assEqualVar = {};
    for i from 0 to #equalVarGroups-1 do (
    	group = equalVarGroups_i;
    	if #group > 1 then (
    	    for j from 0 to #group-2 do (
    	        polyn = O_(group_j-1,group_j-1) - O_(group_(j+1)-1,group_(j+1)-1);
    	        assEqualVar = join(assEqualVar,{polyn});
    	    )
        )
    );
    
    -- compute ideal
    I = ideal(join(assNoBidirectedEdges,assEqualVar));
    
    -- calculate the vanishing ideal as elimination ideal by eliminating all Lambda entries
    Ivanish = eliminate(toEliminate,I);
    
    -- return vanishing Ideal
    Ivanish
)


-- 
compare = args -> (
    -- takes exactly two digraphs and 3rd arg variance partitionand returns if their vanishing ideals identical   
    vanishingIdeal(args_0,args_2) == vanishingIdeal(args_1,args_2)     
)
