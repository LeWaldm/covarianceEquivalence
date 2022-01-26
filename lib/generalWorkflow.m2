load "utils.m2";
load "loadAndSaveResults.m2";
load "exploreResults.m2";

-- setup environment
env = createEnv(4)

-- compute single graph
G = digraph({1,2,3,4},{{1,2},{3,4},{3,2}})
I1 = vanishingIdeal(env,G)
I2 = vanishingIdeal(env,G,{{1,2}})
I1 == I2

-- compute large scale
env = createEnv(3);
dags = generateDAGs(3);
#dags
(groups,ideals) =  compVanishingIdealAll(env,dags,{});

-- save computation
saveResults("test5",env,eqVarPart,dags,ideals,groups);

-- load results
(env,allVarPart,allGroups,dags,ideals) = loadResults("test5");
groups = allGroups_0;

-- look at computations
printGroupCounts(groups);
printGroups(dags,groups);
printAllGroups(dags,groups);
showNGroupsWithMMembers(dags,groups,3,3);
showAlgEqGroupOf(dags,groups,digraph({{1,2},{2,3}}));



