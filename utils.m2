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
    R := assumptions_0;
    S := assumptions_1;
    Lfull := assumptions_2;
    n := assumptions_3;
    toEliminate := assumptions_4;

    -- handle input
    if #args == 0 then error("Need a Digraph as first argument!");
    if instance(args,Digraph) then (
        g := args;
        equalVarGroups := {};
    ) else (
    if #args == 2 then(
        g := args_0;
        equalVarGroups := args_1;           
    ) else (
    if #args > 2 then error("Too many arguments!");
    ););
    L := hadamard(Lfull,adjacencyMatrix(reindexBy(g,"sort")));

    -- calculate vanishing ideal   
    -- calculate Omega
    O := transpose(id_(R^3) - L) * S * (id_(R^3) - L);
    
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
    	        polyn = O_(group_j-1,group_j-1) - O_(group_(j+1)-1,group_(j+1)-1);
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
compare = args -> ( 
    vanishingIdeal(args_0,args_2) == vanishingIdeal(args_1,args_2)     
)





-- function that computes groups of graphs with identical vanishing Ideal
-- input: set of graphs to compare as list of digraphs and 
--        equal variance groupings as list of lists
-- output: list of lists with groups index of graphs with identical vanishing ideal
-- note: second function does same but optimized by only calculating the ideals once
compVanishingIdealAll = (graphs,varianceGrouping) -> (
    results = {};
    time (for i from 0 to #graphs-2 do (
        print(concatenate(toString(i+1),"/",toString(#graphs-1)));
        for j from i+1 to #graphs-1 do(
            val = compare(graphs_i,graphs_j,varianceGrouping);
            if (val == true) then (
                results = append(results,{i,j});
            );  
        );
    ));
    allNodes = for i from 0 to nodes-1 list i;
    connectedComponents(graph(allNodes, results))
)

compVanishingIdealAllOpt = (graphs,varianceGrouping) -> (
    vanishingIdeals = {};
    time (for i from 0 to #graphs-1 do (
        vanishingIdeals_i = vanishingIdeal(graphs_i,varianceGrouping);    
    ));
    print("Computing and saving ideals done!");

    -- compute groups with identical vanishingIdeal
    results = {};
    for i from 0 to #graphs-2 do (
        print(concatenate(toString(i+1),"/",toString(#graphs-1)));        
        for j from i+1 to #graphs-1 do(
            if (vanishingIdeals_i == vanishingIdeals_j) then (
                results = append(results,{i,j});
            );  
        );
    );
    allNodes = for i from 0 to nodes-1 list i;
    connectedComponents(graph(allNodes, results))
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
            print(concatenate("Group ",toString(groupCounter)," (",toString(#group)," members)"));
            for j from 0 to #group-1 do (
                print(allGraphs_(group_j));   
            );
        ) else (
            noGroupCounter = noGroupCounter + 1;
        );
    );
    print(concatenate("Graphs without group: ",toString(noGroupCounter),"/",toString(#graphs)));
)



