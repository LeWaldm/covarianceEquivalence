load "lib/exploreResults.m2"

-- load computed results with dags
fileNames := {
    "results/3nodes_dags_{{1}, {2}, {3}}",
    "results/3nodes_dags_{{1, 2}, {3}}",
    "results/3nodes_dags_{{1, 2, 3}}",
    "results/4nodes_dags_{{1}, {2}, {3}, {4}}",
    "results/4nodes_dags_{{1, 2}, {3}, {4}}",
    "results/4nodes_dags_{{1, 2}, {3, 4}}",
    "results/4nodes_dags_{{1, 2, 3}, {4}}",
    "results/4nodes_dags_{{1, 2, 3, 4}}"
}

-- check the conjectures
for str in fileNames do (
    print(str);
    (env,ptts,allGroups,graphs,allIdeals) = loadResults(str);
    ptt = ptts_0;
    groups = allGroups_0;
    conjectureChecker(graphs,groups,ptt,conjectureThesis);
)