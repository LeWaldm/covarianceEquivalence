-- idea: use macauly2 built-in database to save the vanishing ideal I of 
--   a graph G with variance partition v, computation time ct  as key value pair: 
--       key: {G,varPart} -> value: {I,ct}
--   this is basically a database in long format. Might be improved later.
load "lib/utils.m2";
load "lib/largeScaleComp.m2";

dbFile = "results/vanIdealsTopOrder.dbm";
allFiles = {"topSortedDags/ts_dags3","topSortedDags/ts_dags4","topSortedDags/ts_dags5"}
allNodes = {3,4,5};
timeLimits = {10,10,10};

db = openDatabaseOut dbFile;
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

        -- calculate ideals
        (ideals,compTime) = compAllVanIdTimeLim(env,topOrdDags,ptt,timeLimits_i);

        -- save ideals
        for j from 0 to #topOrdDags-1 do (
            db#(toString({topOrdDags_j,ptt})) = toString({compTime_j,ideals_j});
        );
    );
)
close db;