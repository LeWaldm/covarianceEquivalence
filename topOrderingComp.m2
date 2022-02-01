-- idea: use macauly2 built-in database to save the vanishing ideal I of 
--   a graph G with variance partition v, computation time ct  as key value pair: 
--       key: {G,varPart} -> value: {I,ct}
--   this is basically a database in long format. Might be improved later.
--
-- This script takes a database and some dags to compute the vanishing
-- ideals of. The script only performs calculations for the dags
-- that have no vanishingIdeals (or ideal of null) in the database.
-- A time Limit for each calculation needs to be given.
load "lib/utils.m2";
load "lib/largeScaleComp.m2";

dbFile = "results/vanIdealsMplNodes4.dbm";
allFiles = {"topSortedDags/ts_dags4"};
allNodes = {4};
timeLimits = {200};
elimMethod = "maple";

db = openDatabaseOut dbFile;
try (
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
        print(#allEqVarPart);

        for p from 0 to #allEqVarPart-1 do (

            -- user feedback
            ptt = allEqVarPart_p;
            print("----------------------------------------------------");
            print(concatenate("Equal Variance Partition: ",toString(ptt)));

            -- open database
            --db = openDatabaseOut concatenate(dbFile,"_",toString(ptt),".dbm");

            -- see which graphs need to be computed
            graphsToComp := sequence();
            for j from 0 to #topOrdDags-1 do (
                key = toString({topOrdDags_j,ptt});
                if db#?key and (db#key)_(-3) != "," then
                    continue;
                graphsToComp = append(graphsToComp,topOrdDags_j);
            );
            needToComp = needToComp + #graphsToComp;
            totalGraphs = totalGraphs + #topOrdDags;

            -- compute the ideals
            for j from 0 to #graphsToComp do (

                I = vanishingIdeal(env,graphsToComp_j,ptt,"maple");
                db#(toString({graphsToComp_j,ptt})) = toString({compTime_j,ideals_j,elimMethod});

            )


            if #graphsToComp>0 then (
                -- calculate ideals
                (ideals,compTime) = compAllVanIdTimeLim(env,graphsToComp,ptt,timeLimits_i,elimMethod);
            

                -- save ideals
                for j from 0 to #graphsToComp-1 do (
                    if not(instance(ideals_j,Nothing)) then
                        actuallyComp = actuallyComp + 1;
                    db#(toString({graphsToComp_j,ptt})) = toString({compTime_j,ideals_j,elimMethod});
                );
            );
        );
    );
    close db;
    print(concatenate(toString(actuallyComp),"/",
        toString(needToComp),"/",toString(totalGraphs), 
        " (actually calculated / requested computation / total graph entries in database"));
) else close db;