-- this script needs a .dbm database that contains the vanishingIdeals of 
-- all possible variance partitions but only for all topologically unique graphs.
-- This db can be calculated by ;createVanIdealDb.m2'.
-- This script calculates the vanishingIdeals of all the other graphs by
-- permuting the nodes and the indices in the ideals. 
-- Then it compares all vanishing ideals, computes
-- the groups of equal vanishing ideals and saves the results in a file.
-- These computations are only done for the unique partitions of the
-- number of nodes. The groups (and ideals) for other partitions can
-- be deduced by permutation (again).
load "lib/utils.m2";
needsPackage "GraphicalModels";
load "lib/loadAndSaveResults.m2";

-- parameters
allNodes = {3};
dbTopSortVanIdealsMpl = "results/test/topOrdVanIdeals3.dbm";
saveFiles = {"results/test/3"};
varPart3 = {
    {},
    {{1,2}},
    {{1,2,3}}
};
varPart4 = {
    {},
    {{1,2}},
    {{1,2},{3,4}},
    {{1,2,3}},
    {{1,2,3,4}}
};
varPart5 = {
     {},
     {{1,2}},
     {{1,2},{3,4}},
     {{1,2,3},{4,5}},
     {{1,2,3,4}},
     {{1,2,3,4,5}}
};
allPartitions = {varPart3};
relPathToMplCompScript = "lib/compareIdeals.mpl";
compareMethod = "maple";


-- help function: takes string and hashtable and returns
-- string that has all characters that are keys of hastable
-- changed according to the hashtable
permuStr = (str,permu) -> (
    out := new MutableHashTable;
    for i from 0 to #str-1 do (
        if permu#?(str_i) then 
            out#i = permu#(str_i)
        else out#i = str_i;
    );
    return concatenate(for i from 0 to #str-1 list out#i);
)

-- main
try close dbTopSortVanIdealsMpl;
db = openDatabaseOut dbTopSortVanIdealsMpl;
for n from 0 to #allNodes-1 do (

    -- setup loop variables
    nodes = allNodes_n;
    print("--------------------------------------------------------------");
    print(concatenate("Nodes: ", toString(nodes)));
    env = createEnv(nodes);
    desiredPtts := apply(allPartitions_n,p->fillPartition(nodes,p));
    desiredPtts = sort(apply(desiredPtts,sort));
    desiredPttsSet := set(desiredPtts);
    if nodes > 9 then   -- because of the way s_xy is dealt with
        error("Only works for nodes <10.");

    -- create hashmap with m2 objects instead ot str in key for better comparison
    --   and only select the entries with correct number of nodes
    print("Selecting entries with correct number of nodes...");
    if nodes == 3 then 
        keysSel = select(keys(db),x->substring(x,0,19)=="{digraph ({1, 2, 3}")
    else if nodes == 4 then
        keysSel = select(keys(db),x->substring(x,0,22)=="{digraph ({1, 2, 3, 4}")
    else 
        error("Only 3,4 nodes allowed.");
    vanIdeals = new MutableHashTable;
    maple:=null;
    for i from 0 to #keysSel-1 do (
        key = value(keysSel_i);
        --db with time: vanIdeals#({key_0,sort(key_1)}) = toString((value(db#(keysSel_i))));
        vanIdeals#({key_0,sort(key_1)}) = db#(keysSel_i);
    );
    close db;

    -- find all dags deduced from the top orderings by permutations
    print("Permuting topologically sorted dags ...");
    topDags2eqDags = new MutableHashTable; -- values are a list of all the dags
    topDags2eqDagsPermus = new MutableHashTable; -- values are a list of the permutations
    allPermus := apply(
        permutations(for i from 1 to nodes list i),
        p -> hashTable(for i from 0 to nodes-1 list (toString(i+1),toString(p_i)))
    );
    counter := 0;
    allKeys := keys(vanIdeals);
    elapsedTime for i from 0 to #allKeys-1 do (
        progressBar(i/(#allKeys-1));
        k := allKeys_i;
        alreadyCreated := new MutableHashTable;
        listDags := sequence();
        listPermus := sequence();
        for permu in allPermus do (
            edgesPermu := sort(value(permuStr(toString(edges(k_0)),permu)));
            if alreadyCreated#?edgesPermu then 
                continue;
            alreadyCreated#edgesPermu = 1;
            listDags = append(listDags,digraph(vertices(k_0),edgesPermu));
            listPermus = append(listPermus,permu);
        );
        topDags2eqDags#(k_0) = listDags;
        topDags2eqDagsPermus#(k_0) = listPermus;
    );

    -- add all permuted dags with their permuted eqvarptt and permutedvanIdeal
    --   to vanIdeals, but only if they permute to a desired partition    
    vanIdealSaveFile = concatenate(saveFiles_n,"_vanIdeals.dbm");
    if fileExists(vanIdealSaveFile) then (
        print("Database of all vanishingIdeals already exists. Loading this database...");
        error("Loading an already existing database is currently not supported.");
            -- problems: how to check that the database contains all the 
            --   necessary keys? could run createVanIdeals database then.
            --   or just scan the database and determine which are missing.
            --   In both cases I would need to abstract the script more.
            --   maybe in a later stage, not necessary now.
        -- try close vanIdealSaveFile;
        -- allVanIdealsDb = openDatabaseOut vanIdealSaveFile;
    ) else (
        print("Permuting ideals of new dags ...");
        allVanIdealsDb = openDatabaseOut vanIdealSaveFile;
        counter:=0;
        nTotal := #(keys(vanIdeals));
        elapsedTime for k in keys(vanIdeals) do (
            progressBar(counter/nTotal);
            counter = counter + 1;
            dag = k_0;
            ptt = k_1;
            I = vanIdeals#k;
            lDags = topDags2eqDags#dag;
            lPermus = topDags2eqDagsPermus#dag;
            for d from 0 to #lDags-1 do (

                -- assign variables in this loop
                permu = lPermus_d;

                -- calculate key, i.e. permute and sort partition
                pttPermu = value(permuStr(toString(ptt),permu));
                pttPermu = sort(apply(pttPermu,sort));
                key = {lDags_d,pttPermu};

                -- check if permuted ptt desired
                if not member(pttPermu,desiredPttsSet) then
                    continue;

                -- calculate value, i.e. permute ideal by permu 
                --   (works for both m2 and maple ideals)
                str = new MutableHashTable;
                i=0;
                while i < #I do  (
                    if permu#?(I_i) and I_(i-1)=="_" then (
                        c1 = permu#(I_(i));
                        c2 = permu#(I_(i+1));
                        if value(concatenate(c1,">",c2)) then (
                            str#(i) = c2;
                            str#(i+1) = c1;
                        ) else (
                            str#(i) = c1;
                            str#(i+1) = c2;
                        );
                        i = i + 1;
                    ) else 
                        str#i = I_i;
                    i = i + 1;
                );
                IpermuStr = concatenate(for i from 0 to #I-1 list str#i);

                -- add key value pair
                allVanIdealsDb#(toString(key)) = IpermuStr;
            );
        );
    );
    print(#keys(allVanIdealsDb));


    -- iterate over all partitions (later: maybe loop over partitions one level higher)
    for ptt in desiredPtts do (
        print("------------------------------------------------");
        print(concatenate("Partition: ",toString(ptt)));

        -- see if already calculated
        fileName = concatenate(saveFiles_n,"_",toString(ptt));
        if fileExists(fileName) then  (
            print("File with this name already exists. Continue.");
            continue;
        );

        -- get all keys with current variance ptt from the vanIdeals
        selKeys := select(keys(allVanIdealsDb),k->(value(k))_1 == ptt);
        print(concatenate("Found ",toString(#selKeys)," keys."));

        -- get the corresponding graphs with their vanIdeals
        dags := apply(selKeys,k->(value(k))_0);
        ideals := apply(selKeys,k->allVanIdealsDb#k);

        -- print all ideals to a file with one ideal per file and call 
        --    maple script that compares all the ideals and calculates the
        --    groups and just returns the groups to m2
        print("Comparing and grouping all ideals ...");
        fileNameMplIn = temporaryFileName();
        fileNameMplOut = temporaryFileName();
        out = fileNameMplIn << "";
        out << toString(#selKeys)<<endl;
        for i from 0 to #selKeys-1 do 
            out << ideals_i << endl;
        out << close;

        fileLines = lines(get(relPathToMplCompScript));
        mplCode = temporaryFileName() | ".mpl";
        mplCode << concatenate("fileNameIn:=\"",fileNameMplIn,"\":")<<endl;
        mplCode << concatenate("fileNameOut:=\"",fileNameMplOut,"\":")<<endl;
        for i from 2 to #fileLines-1 do 
            mplCode << fileLines_i << endl;
        mplCode << close;
        elapsedTime run(concatenate("maple -q ",mplCode));
        removeFile(fileNameMplIn);
        removeFile(mplCode);

        -- load results from maple
        groups = value(get(fileNameMplOut));
        groups = apply(groups,group->apply(group,i->i-1));
        removeFile(fileNameMplOut);

        -- save results
        saveResults(fileName,env,ptt,dags,null,groups);
    );
    close allVanIdealsDb;
);