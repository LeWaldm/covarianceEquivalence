load "lib/utils.m2";
load "lib/largeScaleComp.m2";

dbFile = "results/vanIdealsTopOrderTimeLimit.dbm";
allFiles = {"topSortedDags/ts_dags3","topSortedDags/ts_dags4","topSortedDags/ts_dags5"};
allNodes = {3,4,5};
timeLimits = {10,5*3600,10};
elimMethod = "maple";

db = openDatabaseOut dbFile;
(
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

        for p from 0 to #allEqVarPart-1 do (

            -- user feedback
            ptt = allEqVarPart_p;
            print("----------------------------------------------------");
            print(concatenate("Equal Variance Partition: ",toString(ptt)));

            -- see which graphs need to be computed
            graphsToComp := sequence();
            for j from 0 to #topOrdDags-1 do (
                key = toString({topOrdDags_j,ptt});
                if db#?key and (db#key)_(-3) != "," then 
                    continue;
                graphsToComp = append(graphsToComp,topOrdDags_j);
            );
            print(#graphsToComp);
            needToComp = needToComp + #graphsToComp;
            totalGraphs = totalGraphs + #topOrdDags;

            -- calculate ideals
            --(ideals,compTime) = compAllVanIdTimeLim(env,graphsToComp,ptt,timeLimits_i,elimMethod);

            -- -- save ideals
            -- for j from 0 to #graphsToComp-1 do (
            --     if not(instance(ideals_j,Nothing)) then
            --         actuallyComp = actuallyComp + 1;
            --     db#(toString({graphsToComp_j,ptt})) = toString({compTime_j,ideals_j,elimMethod});
            -- );
        );
    );
    close db;
    print(concatenate(toString(actuallyComp),"/",
        toString(needToComp),"/",toString(totalGraphs), 
        " (actually calculated / requested computation / total graph entries in database)"));
)