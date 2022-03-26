-- SCRIPT TO EXPLORE THE RESULTS

-- Best load this script, the 'lib/exploreResults.m2" and
-- the result files from 'results/...' you are interested in into
-- https://www.unimelb-macaulay2.cloud.edu.au/#editor
-- There, printing graphs will display their tikZ picture which is
-- very  nice for exploration. Note that this script does assume
-- that all files in current folder, no results/ or lib/ (thats the case 
-- in the online version)
load "exploreResults.m2" 

-- loading data
fileNames := {
    "3nodes_dags_{{1}, {2}, {3}}",
    "3nodes_digraphs_{{1}, {2}, {3}}",
    "4nodes_dags_{{1, 2}, {3}, {4}}",
    "4nodes_digraphs_{{1}, {2}, {3}, {4}}"
}
fileName := fileNames_0;
(env,ptts,allGroups,graphs,allIdeals) = loadResults(fileName);
ptt = ptts_0;
groups = allGroups_0;


-------------------------
-- exploration functions
-------------------------
-- print the group distribution
printGroupCounts(groups);

-- show 2 randomly selected cov.equivalence groups with 3 members
showNGroupsWithMMembers(graphs,groups,2,3);

-- show the covariance equivalence groups of the specific graph G
G = digraph({{1,2},{2,3}});
showCovEqGroupOf(graphs,groups,G);


-- check whether a specific conjecture holds on the computed graphs and groups.
--   The conjecture is a function that takes a partition and 
--   two graphs and outputs true or false. The conjectureChecker then checks
--   if the inputted conjecture is sufficient and/or necessary for the computed equivalence groups.

-- check whether the classes can be explained by identical edges
conj = (ptt,g1,g2) -> (
    e1 = set(edges(g1));
    e2 = set(edges(g2));
    return isSubset(e1,e2) and isSubset(e2,e1);
)
conjectureChecker(graphs,groups,ptt,conj)

-- check the conjecture from the thesis (implemented in lib/exploreResults.m2)
conjectureChecker(graphs,groups,ptt,conjectureThesis)