load "lib/utils.m2";
load "lib/loadAndSaveResults.m2";
load "lib/exploreResults.m2";

----------------------------
SMALL SCALE USAGE
---------------------------

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
saveResults("test3",env,eqVarPart,dags,ideals,groups);

-- load results
(env,allVarPart,allGroups,dags,ideals) = loadResults("test3");
groups = allGroups_0;

-- look at computations
printGroupCounts(groups);
printGroups(dags,groups);
printAllGroups(dags,groups);
showNGroupsWithMMembers(dags,groups,3,3);
showAlgEqGroupOf(dags,groups,digraph({{1,2},{2,3}}));


----------------------------
LARGE SCALE USAGE
---------------------------
-- adjust parameters in scripts lib/createVanIdealDb.m2 and 
-- lib/compareFromDbm.m2 and then execute them
load "lib/createVanIdealDb.m2"
load "lib/compareFromDbm.m2"
