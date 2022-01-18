restart
load "utils.m2";

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
        edges := {};
        for i from 0 to nodes-2 do (
            for j from i+1 to nodes-1 do (
                ind = i*(nodes-1) - (i*(i+1)//2) + j-1;  
                --print("-----");
                --print(i);
                --print(j);
                --print(ind);
                if ((allCombinations_comb)_ind) == 1 then (
                    edges = append(edges,{i,j});
                ) else ( if ((allCombinations_comb)_ind) == -1 then (
                    edges = append(edges,{j,i});                
                ););
            );
        );
        g := digraph(allNodes,edges);
        
        -- only add if graph acylic
        if not(isCyclic(g)) then (
            dags = append(dags,g);           
        );
    );
    dags
)
dags = time generateDAGs(4);
isEqualSets = (s1,s2) -> (
    isSubset(s1,s2) and isSubset(s2,s1)
)



-- check if any acyclic
for i from 0 to #dags-1 do (
    if isCyclic(dags_i) then print(dags_i);
);

-- check if any equal
dagsDupl = append(dags,dags_10);
allGraphs = dags;
for i from 0 to #allGraphs -2 do(
    for j from i+1 to #allGraphs-1 do(
        if not isEqualSets(set(edges(allGraphs_i)), set(edges(allGraphs_j))) then (
            print("-------------------------");
            print(allGraphs_i);
            print(i);
            print(j);
        );
    );
);

-- check if all dags
for i from 0 to #dags-1 do (
    if not(instance(dags_i,Digraph)) then print i;    
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







