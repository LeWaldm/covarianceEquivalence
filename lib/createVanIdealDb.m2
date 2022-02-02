-- idea: use macauly2 built-in database to save the vanishing ideal I of 
--   a graph G with variance partition v as key value pair: 
--       key: {G,varPart} -> toString(ideal)
--   this is basically a database in long format. Might be improved later.
--
-- This script computes the vanishing
-- ideals of some dags and saves the result in a database. If the 
-- dag already has an ideal in the database, it is not computed again.
-- 
-- that have no vanishingIdeals (or ideal of null) in the database.
-- A time Limit for each calculation needs to be given.
load "lib/utils.m2";
load "lib/largeScaleComp.m2";

-- parameters
dbFile = "results/test/topOrdVanIdeals3.dbm";
allFiles = {"topSortedDags/ts_dags3"};
allNodes = {3};
elimMethod = "maple";
timeLimits = {1000};  -- in seconds, only applicable if elimMethod is maple, -1 for no limit

-- main 
try close db;
db = openDatabaseOut dbFile;
totalGraphs = 0;
needToComp = 0;
actuallyComp = 0;
for i from 0 to #allNodes-1 do (
    nodes = allNodes_i;
    print("----------------------------------------------------------------------------------------------");
    print(concatenate("Nodes: ",toString(nodes)));
    print("----------------------------------------------------------------------------------------------");

    env = createEnv(nodes);
    topOrdDags = generateDagsFromFile(allFiles_i);
    allEqVarPart = allPartitions(set(for j from 1 to nodes list j));
    timeLimit := timeLimits_i;
    print(#allEqVarPart);

    for p from 0 to #allEqVarPart-1 do (

        -- possibility to select only some variance partitions
        ptt = allEqVarPart_p;
        -- if sort({2,1,1,1}) != sort(apply(ptt,g->#g)) then (
        --     print(concatenate("skipped: ",toString(ptt)));
        --     continue;
        -- );

        -- user feedback
        print("----------------------------------------------------");
        print(concatenate("Equal Variance Partition: ",toString(ptt)));

        -- see which graphs need to be computed
        graphsToComp := sequence();
        for j from 0 to #topOrdDags-1 do (
            key = toString({topOrdDags_j,ptt});
            if db#?key and (db#key)_(-3) != "null" then
                continue;
            graphsToComp = append(graphsToComp,topOrdDags_j);
        );
        needToComp = needToComp + #graphsToComp;
        totalGraphs = totalGraphs + #topOrdDags;

        for j from 0 to #graphsToComp-1 do (
            print(concatenate(toString(j+1),"/",toString(#graphsToComp)));
            I := vanishingIdeal1(env,graphsToComp_j,ptt,elimMethod,timeLimit);
            if elimMethod == "maple" then (
                if not(I == "null") then
                    actuallyComp = actuallyComp + 1
                else print("NULLNULLNULLNULLULLNULLNULLNULLNULLNULLNULLNULL");
                db#(toString({graphsToComp_j,ptt})) = I;
            ) else if elimMethod == "m2" then (
                if not instance(I,Nothing) then
                    actuallyComp = actuallyComp + 1
                else print("NULLNULLNULLNULLULLNULLNULLNULLNULLNULLNULLNULL");
                db#(toString({graphsToComp_j,ptt})) = toString(I);
            );
        );
    );
);
close db;
print(concatenate(toString(actuallyComp),"/",
    toString(needToComp),"/",toString(totalGraphs), 
    " (actually calculated / requested computation / total graph entries in database)"));