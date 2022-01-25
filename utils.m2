-- requires package 
needsPackage "GraphicalModels"
needsPackage "DeterminantalRepresentations"
needsPackage "ThreadedGB"

-- generate environment with Ring,L,S matrices for arbitrary number of nodes 
createEnv = nodes -> (
    -- generate entries of L matrix
    entriesL := "";
    for i from 0 to nodes-1 do (
        for j from 0 to nodes-1 do (
            if i == j then 
                continue;
            if not (i == 0 and j == 1) then 
                entriesL = concatenate(entriesL,",");
            entriesL = concatenate(entriesL,"l_",toString(i+1),toString(j+1));
        );
    );
    
    -- generate R
    cmmd := concatenate("QQ[",entriesL);
    for i from 0 to nodes-1 do (
        for j from i to nodes-1 do (
            cmmd = concatenate(cmmd,",s_",toString(i+1),toString(j+1));
        );
    ); 
    cmmd = concatenate(cmmd,",MonomialOrder => Eliminate ",toString(nodes*(nodes-1)),"]");
    R := value(cmmd);
    
    -- generate S
    cmmd = "matrix{";
    for i from 0 to nodes-1 do (
        if i != 0 then
            cmmd = concatenate(cmmd,",");
        cmmd = concatenate(cmmd,"{");
        for j from 0 to nodes-1 do (
            if j != 0 then 
                cmmd = concatenate(cmmd,",");
            if i <= j then
                cmmd = concatenate(cmmd,"s_",toString(i+1),toString(j+1))
            else
                cmmd = concatenate(cmmd,"s_",toString(j+1),toString(i+1));
        );
        cmmd = concatenate(cmmd,"}");
    );  
    cmmd = concatenate(cmmd,"}");
    S := value(cmmd);
       
    -- generate Lfull
    cmmd = "matrix{";
    for i from 0 to nodes-1 do (
        if i != 0 then
            cmmd = concatenate(cmmd,",");
        cmmd = concatenate(cmmd,"{");
        for j from 0 to nodes-1 do (
            if j != 0 then 
                cmmd = concatenate(cmmd,",");
            if i == j then
                cmmd = concatenate(cmmd,"0")
            else
                cmmd = concatenate(cmmd,"l_",toString(i+1),toString(j+1));
        );
        cmmd = concatenate(cmmd,"}");
    );  
    cmmd = concatenate(cmmd,"}");
    Lfull := value(cmmd);
    
    -- toEliminate
    cmmd = concatenate("{",entriesL,"}");
    toEliminate = value(cmmd);
    
    -- generate output
    {nodes,R,S,Lfull,toEliminate}
)


-- generates all possible n-tuple of vals (recursion not most clean ever but okay)
generateAllCombinations = (vals,n) -> (
    
    result := ();
    nVals := length(vals);
    nComb := nVals^n;       
    for j from 0 to nComb-1 do (
        l := {};
        for i from 0 to n-1 do  (
            ind := floor(j / nVals^(n-1-i)) % nVals;           
            l = append(l,vals_ind);
        );
        result = append(result,l);
    );
    result
)


-- naive method to check if digraph is cyclic
checkIsCyclic = G -> (    
    gLocal := G;
    sinkVertices := sinks(gLocal);   
    while sinkVertices != {} do (
        gLocal = deleteVertices(gLocal,sinkVertices);
        sinkVertices = sinks(gLocal);
    );
    #vertices(gLocal) != 0 
)


-- generate all DAGs with certain number of nodes
generateDAGs = nodes -> (

    -- generate powerset
    nUndirectedEdges := nodes*(nodes-1)//2;
    allCombinations := generateAllCombinations({-1,0,1},nUndirectedEdges);
    allNodes = for i from 1 to nodes list i;

    -- extract dags
    dags := {};
    for comb from 0 to #allCombinations-1 list (
        
        -- generate graph
        edgesCurr := {};
        for i from 1 to nodes-1 do (
            for j from i+1 to nodes do (
                ind = (i-1)*(nodes-1) - (i*(i-1)//2) + j-2; -- double checked  
                if (allCombinations_comb)_ind == 1 then (
                    edgesCurr = append(edgesCurr,{i,j});
                ) else ( if (allCombinations_comb)_ind == -1 then (
                    edgesCurr = append(edgesCurr,{j,i});                
                ););
            );
        );
        g := digraph(allNodes,edgesCurr);
        
        -- only add if graph acylic
        if not(checkIsCyclic(g)) then (
            dags = append(dags,g);           
        );
    );
    dags
)


-- function that computes the vanishing ideal of a digraph
-- inputs:
-- - env: environment, output from createEnv() (with env_0 being number of nodes n)
-- - digraph: a Digraph from the graphicalModels package with nodes 0 to n-1
-- - variancePartiton: set of sets of nodes (from 0 to n-1) with equalVariances 
-- ways to call: 
--   vanishingIdeal(env,digraph)
--   vanishingIdeal(env,digraph,variancePartition)
vanishingIdeal = args -> (

    -- assignt local environment
    n := args_0_0;
    R := args_0_1;
    S := args_0_2;
    Lfull := args_0_3;
    toEliminate := args_0_4;

    -- handle input
    g := null;
    equalVarGroups := null;
    if #args == 0 then error("Need environment as first argument!");
    if #args == 1 then error("Need dags as second argument!");
    if #args == 2 then (
        g = args_1;
        equalVarGroups = {};
    ) else (
    if #args == 3 then (
        g = args_1;
        equalVarGroups = args_2;     
    ) else 
        error("Too many arguments!");
    );
    L := hadamard(Lfull,adjacencyMatrix(reindexBy(g,"sort")));
  
    -- calculate Omega
    O := transpose(id_(R^n) - L) * S * (id_(R^n) - L);
    
    -- compute vanishing polynomials from assumption: no bidirected edges
    assNoBidirectedEdges := {};
    for i from 0 to n-2 do (
    	for j from i+1 to n-1 do (
            --print(concatenate("(",toString(i),",",toString(j),")"));
    	    assNoBidirectedEdges = join(assNoBidirectedEdges,{O_(i,j)});
    	)
    );
    
    -- compute vanishing polynomials from additional assumption about equal variance groups
    assEqualVar := {};
    for i from 0 to #equalVarGroups-1 do (
    	group = equalVarGroups_i;
    	if #group > 1 then (
    	    for j from 0 to #group-2 do (
                --print(concatenate("(",toString(group_j-1),"-",toString(group_(j+1)-1),")"));
    	        polyn = O_(group_j-1,group_j-1) - O_(group_(j+1)-1,group_(j+1)-1);
    	        assEqualVar = join(assEqualVar,{polyn});
    	    )
        )
    );
    
    -- compute ideal
    I := ideal(join(assNoBidirectedEdges,assEqualVar));
    
    -- calculate the vanishing ideal as elimination ideal by eliminating all Lambda entries
    --eliminateParallel(toEliminate,I)
    --elapsedTime (gb(I));
    --elapsedTime (groebnerBasis(I, Strategy=>"MGB"));
    --elapsedTime eliminateExpGb(toEliminate,I);
    eliminate(toEliminate,I)
)


-- takes exactly two digraphs and 3rd arg variance partitionand returns if their vanishing ideals identical
compare = (env,d1,d2,eqVarPart) -> ( 
    vanishingIdeal(env,d1,eqVarPart) == vanishingIdeal(env,d2,eqVarPart)     
)



-- function that computes groups of graphs with identical vanishing Ideal
-- input: set of graphs to compare as list of digraphs and 
--        equal variance groupings as list of lists
-- output: list of lists with groups index of graphs with identical vanishing ideal
compVanishingIdealAll = (env,dags,eqVarPart) -> (
    vanishingIdeals := {};
    print("Computing and saving ideals ... ");
    elapsedTime (for i from 0 to #dags-1 do (
        print(concatenate(toString(i+1),"/",toString(#dags)));
        vanishingIdeals = append(vanishingIdeals,vanishingIdeal(env,dags_i,eqVarPart));    
    ));

    -- compute groups with identical vanishingIdeal
    print("Comparing ideals ...");
    elapsedTime(
    equivResults := {};
    for i from 0 to #dags-2 do (
        --print(concatenate(toString(i+1),"/",toString(#dags-1)));        
        for j from i+1 to #dags-1 do(
            if (vanishingIdeals_i == vanishingIdeals_j) then (
                equivResults = append(equivResults,{i,j});
            );  
        );
    ););

    print("Computing groups with equal ideals...");
    allNodes := for i from 0 to #dags-1 list i;
    groups = time connectedComponents(graph(allNodes, equivResults));
    (groups,vanishingIdeals)
)



