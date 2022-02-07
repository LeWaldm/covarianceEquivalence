-- overview of functions to explore results. 
-- Suited for loading into online m2 editor
-- https://www.unimelb-macaulay2.cloud.edu.au/#editor
load "lib/exploreResults.m2" 

fileNames := {
    "results/final/permu4_{{1, 2, 3, 4}}",
    "results/final/permu4_{{1, 2, 3}, {4}}",
    "results/final/permu4_{{1, 2}, {3, 4}}",
    "results/final/permu4_{{1, 2}, {3}, {4}}",
    "results/final/permu4_{{1}, {2}, {3}, {4}}"
}

fileName := fileNames_3;
(env,ptts,allGroups,dags,allIdeals) = loadResults(fileName);
ptt = ptts_0;
groups = allGroups_0;
printGroupCounts(groups);

-- print groups with only 2 members in multiple commands 
-- (online m2 has output limit per command)
gsel := select(groups,g->#g == 2);
printGroups(dags,for i from 0 to 35 list gsel_i);
printGroups(dags,for i from 36 to #gsel-1 list gsel_i);

-- other functions
printAllGroups(dags,groups);
showNGroupsWithMMembers(dags,groups,n,m);
showAlgEqGroupOf(dags,groups,digraph({{1,2},{2,3},{3,4}}));
