load "lib/utils.m2"
load "lib/loadAndSaveResults.m2"

-- Main computational script. Computes and saves the covariance equivalence
-- classes of all graphs with n nodes. The engine that does the 
-- heavy computations can be set as well as the specific graphs to compute.
-- This is a more efficient version of lib/baseVersion.
-- parameters:
--  - n: number of nodes
--  - engine: determines the engine that is used for performing heavy
--      computations (i.e. elimination ideal, saturation, comparing ideals).
--      Has to be "maple" or "m2". 
--  - graphProps: set of graphs to compute the covariance equivalence
--      classes of. Set to "dags" for directec acyclic graphs, "digraphs" for
--      all digraphs without loops, and "simpleDigraphs" for digraphs without
--      loops and not both edges v->w, v<-w for any nodes v,w
--  - saveFileBase: path to create the result file. The graphProps are added
--      with underline. A new file for each partition is created. The partition
--      is also added with underline.

n = 3;
engine = "maple"
graphProps = "dags"
saveFileBase = "results/3nodes"

-- generate sets
print("------------------------------------------------------------");
print(concatenate("Nodes: ",toString(n)));
print("Generating graphs ...");
elapsedTime (
    cyclicAllowed := false;
    graphs := null;
    if graphProps == "dags" then
        graphs = generateDAGs(n)
    else if graphProps == "simpleDigraphs" then (
        graphs = generateSimpleDGs(n);
        cyclicAllowed = true;
    ) else if graphProps == "digraphs" then (
        graphs = generateDGs(n);
        cyclicAllowed = true;
    ) else 
        error("Illegal parameter in 'graphProps'");

    permus = permutations((for i from 1 to n list i));
    allPermusInt := apply(
        permus, p -> hashTable(for i from 0 to n-1 list ((i+1),(p_i))));
    allPermusStr := apply(
        permus, p -> hashTable(for i from 0 to n-1 list (toString(i+1),toString(p_i))));
    basePartitions = generateBasePartitions(n);
    env = createEnv(n);
    saveFileBase = concatenate(saveFileBase, "_", graphProps);
)


-- internal permutation functions
permutePtt := (ptt,permu) -> (
    return unifyPtt(n,apply(ptt,p->(apply(p,val->permu#val))));
);
permuteGraph := (g,permu) -> (
    edgesPermu := apply(edges(g), e-> apply(e,v->permu#v));
    return digraph(vertices(g), edgesPermu);
);
permuteIdeal := (I,permu) -> (
    str := new MutableHashTable;
    i:=0;
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
    return concatenate(for i from 0 to #I-1 list str#i);
);


-- main loop
actuallyComputed = 0
for ptt in basePartitions do (
    print("-------------------------------------------------");
    print(concatenate("Partition: ", toString(ptt)));

    -- compute valid partitions
    validPermusInt := new MutableHashTable;
    validPermusStr := new MutableHashTable;
    c := 0;
    for p from 0 to #allPermusInt-1 do 
        if permutePtt(ptt,allPermusInt_p) == ptt then (
            validPermusInt#c = allPermusInt_p;
            validPermusStr#c = allPermusStr_p;
            c = c+1;
        );
    nValidPermus := c;


    -- calculate all vanishing ideals
    vanIdealDict = new MutableHashTable;
    alreadyComputed = new MutableHashTable;
    print("Computing vanishing ideals ...");
    computedVanishingIdeal = 0;
    elapsedTime for graph in graphs do (
        progressBar(computedVanishingIdeal,#graphs);

        -- compute vanishing ideal
        if alreadyComputed#?graph then
            continue;
        I = toString(vanishingIdeal(env,graph,ptt,engine,-1,cyclicAllowed));
        vanIdealDict#graph = I;
        alreadyComputed#graph = 1;

        -- permute vanishing ideal
        for p from 0 to nValidPermus-1 do (
            permuGraph = permuteGraph(graph,validPermusInt#p);
            if not alreadyComputed#?permuGraph then(
                permuIdeal = permuteIdeal(I,validPermusStr#p);
                vanIdealDict#permuGraph = permuIdeal;
                alreadyComputed#permuGraph = 1;
                computedVanishingIdeal = computedVanishingIdeal+1;
            );
        );
        actuallyComputed = actuallyComputed + 1;
        computedVanishingIdeal = computedVanishingIdeal + 1;
    );

    -- compare all vanishing ideals
    if engine == "m2" then
        vanIdealList = for d in graphs list value(vanIdealDict#d)
    else if engine == "maple" then
        vanIdealList = for d in graphs list vanIdealDict#d;
    covEqClasses = compareVanIdeals(vanIdealList,engine);

    -- save results
    fileName = concatenate(saveFileBase,"_",toString(ptt));
    saveResults(fileName,env,ptt,graphs,null,covEqClasses);
)
print("------------------------------------------------------------");
print(concatenate("Number of vanishing ideals actually computed: ",toString(actuallyComputed)));
print("Finished.")