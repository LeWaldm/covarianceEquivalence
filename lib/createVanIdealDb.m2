load "lib/utils.m2";

-- idea: use macauly2 built-in database to save the vanishing ideal I of 
--   a graph G with variance partition v as key value pair: 
--       key: {G,varPart} -> toString(ideal)
--   this is basically a database in long format. Might be improved later.
--
-- This script computes the vanishing ideals of all topologically 
-- unique dags and saves the result in a database. If the 
-- dag already has an ideal in the database, it is not computed again.--
-- inputs:
--  - dbFile: file to save ALL results. If already existent, need to 
--      have same elimMethod as this script
--  - allFiles: list of files to load the toplogical dags in form of http://users.cecs.anu.edu.au/~bdm/data/digraphs.html 
--  - allNodes: list of number of nodes associated to the files
--  - elimMethod: method for computing elimination ideal, prefer maple
--  - timeLimits: only applicable for elimMethod 'maple'. List of 
--      time limits for calculations. If more time than limit,
--      ideal is saved as "null" in database. Set -1 if no time limit.


-- parameters
dbFile = "results/test/topOrdVanIdeals4.dbm";  
allFiles = {"topSortedDags/ts_dags4"}; -- 
allNodes = {4};     -- list of all nodes to be computed
elimMethod = "maple";
timeLimits = {2000};  -- in seconds, only applicable if elimMethod is maple, -1 for no limit

-- main 
try close db;  -- for easy debugging
db = openDatabaseOut dbFile;
totalGraphs = 0;
needToComp = 0;
actuallyComp = 0;
for i from 0 to #allNodes-1 do (

    -- user feedback
    nodes = allNodes_i;
    print("----------------------------------------------------------------------------------------------");
    print(concatenate("Nodes: ",toString(nodes)));
    print("----------------------------------------------------------------------------------------------");

    -- generate loop variables
    env = createEnv(nodes);
    topOrdDags := generateDagsFromFile(allFiles_i);
    allEqVarPart := allPartitions(set(for j from 1 to nodes list j));
    allEqVarPart = apply(allEqVarPart,ptt->unifyPtt(nodes,ptt));
    timeLimit := timeLimits_i;
    print(concatenate("Computing ",#allEqVarPart," variance partitions."));

    -- main
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
            if db#?key then 
                if elimMethod == "maple" and db#key != "null" then 
                    continue
                else if (db#key)_(-3) != "," then
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