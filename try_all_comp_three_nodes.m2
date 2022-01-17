restart
load "utils.m2"

-- setup all graphs
allGraphs = {
    digraph({1,2,3},{}),
    digraph({1,2,3},{{1,2}}),
    digraph({1,2,3},{{2,1}}),
    digraph({1,2,3},{{2,3}}),
    digraph({1,2,3},{{3,2}}),
    digraph({1,2,3},{{1,3}}),
    digraph({1,2,3},{{3,1}}),
    digraph({1,2,3},{{1,2},{2,3}}),
    digraph({1,2,3},{{3,1},{2,3}}),
    digraph({1,2,3},{{3,1},{1,2}}),
    digraph({1,2,3},{{3,2},{2,1}}),
    digraph({1,2,3},{{2,1},{1,3}}),
    digraph({1,2,3},{{1,3},{3,2}}),
    digraph({1,2,3},{{2,1},{3,1}}),
    digraph({1,2,3},{{1,2},{3,2}}),
    digraph({1,2,3},{{1,3},{2,3}}),
    digraph({1,2,3},{{1,2},{1,3}}),
    digraph({1,2,3},{{2,1},{2,3}}),
    digraph({1,2,3},{{3,2},{3,1}}),
    digraph({1,2,3},{{2,1},{3,1},{2,3}}),
    digraph({1,2,3},{{2,1},{3,1},{3,2}}),
    digraph({1,2,3},{{1,2},{3,2},{1,3}}),
    digraph({1,2,3},{{1,2},{3,2},{3,1}}),
    digraph({1,2,3},{{1,3},{2,3},{1,2}}),
    digraph({1,2,3},{{1,3},{2,3},{2,1}})
};



-- function that computes groups of graphs with identical vanishing Ideal
-- input: set of graphs to compare as list of digraphs and 
--        equal variance groupings as list of lists
-- output: list of lists with groups index of graphs with identical vanishing ideal
-- note: second function does same but optimized by only calculating the ideals once
compVanishingIdealAll = (graphs,varianceGrouping) -> (
    results = {};
    for i from 0 to #graphs-2 do (
        print(concatenate(toString(i+1),"/",toString(#graphs-1)));
        for j from i+1 to #graphs-1 do(
            val = compare(graphs_i,graphs_j,varianceGrouping);
            if (val == true) then (
                results = append(results,{i,j});
            );  
        );
    );
    allNodes = for i from 0 to nodes-1 list i;
    Gcomponents = graph(allNodes, results);
    connectedComponents(Gcomponents)
)

compVanishingIdealAllOpt = (graphs,varianceGrouping) -> (
    vanishingIdeals = {};
    for i from 0 to #graphs-1 do (
        vanishingIdeals_i = vanishingIdeal(graphs_i,varianceGrouping);    
    );

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
    Gcomponents = graph(allNodes, results);
    connectedComponents(Gcomponents)
)


-- prints the digraphs in each group
-- input: graphs and groups 
-- output: plot of groups in command line
printGroups = (graphs,groups) -> (
    groupCounter = 0;
    for i from 0 to #groups-1 do (
        group = groups_i;
        if (#group > 1) then (
            groupCounter = groupCounter + 1;
            print(concatenate("Group ",toString(groupCounter)));
            for j from 0 to #group-1 do (
                print(allGraphs_(group_j));   
            );
        );
    );
)






restart 
loadPackage "GraphicalModels"
G1 = digraph({{1,2},{2,3},{1,3},{4,1}})
Rtest = gaussianRing G1
Ivanish1 = gaussianVanishingIdeal Rtest1

restart 
loadPackage "GraphicalModels"
G2 = digraph({{1,3},{3,2},{1,2},{4,1}})
Rtest2 = gaussianRing G2
Ivanish2 = gaussianVanishingIdeal Rtest2


