-- requires package 
needsPackage "GraphicalModels"
needsPackage "DeterminantalRepresentations"

-- setup (automize later)
createEnv = nodes -> (   
    if nodes == 3 then (
        R = QQ[l_12,l_13,l_21,l_23,l_31,l_32,s_11,s_12,s_13,s_22,s_23,s_33,MonomialOrder => Eliminate 6];
        S = matrix{{s_11,s_12,s_13},{s_12,s_22,s_23},{s_13,s_23,s_33}};
        Lfull = matrix({{0,l_12,l_13},{l_21,0,l_23},{l_31,l_32,0}});
        toEliminate = {l_12,l_13,l_21,l_23,l_31,l_32};
    );
    if nodes == 4 then (
        R = QQ[
            l_12,l_13,l_14,l_21,l_23,l_24,l_31,l_32,l_34,l_41,l_42,l_43,
            s_11,s_12,s_13,s_14,s_22,s_23,s_24,s_33,s_34,s_44,
            MonomialOrder => Eliminate 12];
        S = matrix{{s_11,s_12,s_13,s_14},{s_12,s_22,s_23,s_24},{s_13,s_23,s_33,s_34},{s_14,s_24,s_34,s_44}};
        Lfull = matrix{{0,l_12,l_13,l_14},{l_21,0,l_23,l_24},{l_31,l_32,0,l_34},{l_41,l_42,l_43,0}};
        toEliminate = {l_12,l_13,l_14,l_21,l_23,l_24,l_31,l_32,l_34,l_41,l_42,l_43};
    );
    if (nodes != 3) and (nodes != 4) then error("Currently only nodes 3,4 supported!");
    env = {nodes,R,S,Lfull,toEliminate}
)

-- generates all possible n-tuple of vals (recursion not most clean ever but okay)
generateAllCombinations = (vals,n) -> (
    lAll := {};
    recLoc := (stem,pos) -> (
        if pos==0 then (
            lAll = append(lAll,stem);
        ) else (
            for v from 0 to #vals-1 do (
                recLoc(append(stem,vals_v),pos-1);
            )
        );
   );
   recLoc({},n);
   lAll
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
    allNodes = for i from 0 to nodes-1 list i;

    -- extract dags
    dags := {};
    for comb from 0 to #allCombinations-1 list (
        
        -- generate graph
        edgesCurr := {};
        for i from 0 to nodes-2 do (
            for j from i+1 to nodes-1 do (
                ind = i*(nodes-1) - (i*(i+1)//2) + j-1; -- double checked  
                --print("-----");
                --print(i);
                --print(j);
                --print(ind);
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

    -- we expect list assumptions 
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

    -- calculate vanishing ideal   
    -- calculate Omega
    O := transpose(id_(R^n) - L) * S * (id_(R^n) - L);
    
    -- compute polynomials from assumption: no bidirected edges
    assNoBidirectedEdges := {};
    for i from 0 to n-2 do (
    	for j from i+1 to n-1 do (
    	    assNoBidirectedEdges = join(assNoBidirectedEdges,{O_(i,j)});
    	)
    );
    
    -- compute polynomials from additional assumption about equal variance groups
    assEqualVar := {};
    for i from 0 to #equalVarGroups-1 do (
    	group = equalVarGroups_i;
    	if #group > 1 then (
    	    for j from 0 to #group-2 do (
    	        polyn = O_(group_j,group_j) - O_(group_(j+1),group_(j+1));
    	        assEqualVar = join(assEqualVar,{polyn});
    	    )
        )
    );
    
    -- compute ideal
    I := ideal(join(assNoBidirectedEdges,assEqualVar));
    
    -- calculate the vanishing ideal as elimination ideal by eliminating all Lambda entries
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
    time (for i from 0 to #dags-1 do (
        vanishingIdeals = append(vanishingIdeals,vanishingIdeal(env,dags_i,eqVarPart));    
    ));
    print("Done.");

    -- compute groups with identical vanishingIdeal
    print("Comparing ideals ...");
    time(
    equivResults := {};
    for i from 0 to #dags-2 do (
        print(concatenate(toString(i+1),"/",toString(#dags-1)));        
        for j from i+1 to #dags-1 do(
            if (vanishingIdeals_i == vanishingIdeals_j) then (
                equivResults = append(equivResults,{i,j});
            );  
        );
    ););
    print("Done.");

    print("Computing groups with equal ideals...");
    allNodes := for i from 0 to #dags-1 list i;
    groups = time connectedComponents(graph(allNodes, equivResults));
    print("Done.");
    groups
)


-- prints the digraphs in each group
-- input: graphs and groups 
-- output: plot of groups in command line
printGroups = (graphs,groups) -> (
    groupCounter = 0;
    noGroupCounter = 0;
    for i from 0 to #groups-1 do (
        group = groups_i;
        if (#group > 1) then (
            groupCounter = groupCounter + 1;
            print("-------------------------------------------------------------------");
            print(concatenate("Group ",toString(groupCounter)," (",toString(#group)," members)"));
            for j from 0 to #group-1 do (
                print(graphs_(group_j));   
            );
        ) else (
            noGroupCounter = noGroupCounter + 1;
        );
    );
    print(concatenate("Graphs without group: ",toString(noGroupCounter),"/",toString(#graphs)));
)



