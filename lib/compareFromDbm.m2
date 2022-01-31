load "lib/utils.m2";
needsPackage "GraphicalModels";

-- parameters
allNodes = {3};
dbFile = "results/vanIdealsTopOrder3and4All.dbm";
allDags = {generateDAGs(3)};
saveFiles = {"results/compare3"};
varPart3 = {
    {},
    {{1,2}},
    {{1,2,3}}
};
varPart4 = {
    {},
    {{1,2}},
    --{{1,2},{3,4}},
    --{{1,2,3}},
    --{{1,2,3,4}}
};
varPart5 = {
     {},
     {{1,2}},
     {{1,2},{3,4}},
     --{{1,2,3},{4,5}},
     --{{1,2,3,4}},
     --{{1,2,3,4,5}}
};
allPartitions = {varPart3};

-- main
try close db;
db = openDatabaseOut dbFile;
for n from 0 to #allNodes-1 do(
    nodes = allNodes_n;
    dags = allDags_n;
    env = createEnv(nodes);
    if nodes > 9 then 
        error("Only works for nodes <10.");
        -- because of the way s_xy is dealt with

    -- create object database with value for correct comparison
    if nodes == 3 then 
        keysSel = select(keys(db),x->substring(x,0,19)=="{digraph ({1, 2, 3}")
    else if nodes == 4 then
        keysSel = select(keys(db),x->substring(x,0,22)=="{digraph ({1, 2, 3, 4}")
    else 
        error("Only 3,4 nodes allowed.");
    data = new MutableHashTable;
    for i from 0 to #keysSel-1 do (
        key = value(keysSel_i);
        data#({key_0,sort(key_1)}) = value(db#(keysSel_i));
    );


    -- loop over all partitions
    for p from 0 to #(allPartitions_n) -1 do (
        ptt := fillPartition(nodes,allPartitions_n_p);
        ideals := sequence();
        H:=null;
        key:=null;
        permIdeal:=null;
        maple=null; -- need this since some db entries have string maple
        str:=null;
        strOut:=null;

        -- generate all ideals
        print("Computing and saving ideals ... ");
        elapsedTime for d from 0 to #dags-1 do (
            print(d);

            -- permute vertices of dag such that they match the keys in db
            -- (1) top sorting
            ord := topologicalSort(dags_d,"min");
            topsorted := new MutableHashTable;
            topsortedInv := new MutableHashTable;
            for i from 0 to nodes-1 do (
                topsorted#(i+1) = ord_i;
                topsortedInv#(ord_i) = i+1;
            );

            -- (2) sort s.t. isolated nodes have highest labels


            -- top sort dag & create permuted dag
            H = topSort(dags_d,"min");

            -- get vanideal of permuted dag from database
            key = {H#newDigraph,ptt};
            print(key);
            permIdeal = (data#key)_1;  
                -- might be more efficient working with string directly

            -- get correct vanIdeal by changing back indices
            inv = new MutableHashTable;
            for i from 1 to nodes do inv#(toString((H#map)#i))=toString(i);
            str = toString(permIdeal);
            strOut = sequence();
            i:=0;
            while i < #str do  (
                if str_i == "s" then (
                    c1 := inv#(str_(i+2));
                    c2 := inv#(str_(i+3));
                    if value(concatenate(c1,">",c2)) then
                        strOut = join(strOut,("s_",c2,c1))
                    else 
                        strOut = join(strOut,("s_",c1,c2));
                    i = i + 3;
                ) else if inv#?(str_i) then 
                    strOut = append(strOut,inv#(str_i))
                else 
                    strOut = append(strOut,str_i);
                i = i+1;
            );
            ideals = append(ideals,value(concatenate(strOut)));
        );

        -- compare all ideals
        print("Comparing ideals ...");
        elapsedTime(
        equivResults := {};
        for i from 0 to #dags-2 do (
            --print(concatenate(toString(i+1),"/",toString(#dags-1)));        
            for j from i+1 to #dags-1 do(
                if toString(ideals_i) == "ideal()" then (
                    if toString(ideals_j) == "ideal()" then
                        equivResults = append(equivResults,{i,j})
                ) else if toString(ideals_j) != "ideal()" and
                    ideals_i == ideals_j then 
                        equivResults = append(equivResults,{i,j}
                );  
            );
        ););

        -- create groups
        print("Computing groups with equal ideals...");
        tmpNodes := for i from 0 to #dags-1 list i;
        groups = time connectedComponents(graph(tmpNodes, equivResults));

        -- save everything ideals
        saveResults(saveFiles_n,env,allPartitions_n_p,dags,ideals,groups);
    ); 
)
close db;