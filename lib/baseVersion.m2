load "lib/utils.m2"

-- compute and compare ALL vanishing Ideals of some given 
-- variance partitions. This is inefficient and just included for
-- completeness purposes. Use lib/improvedVersion.m2 instead.

-- parameters
n = 3;
engine = "maple"                -- one of "maple" or "m2"
graphProps = "digraphs"         -- one of "dags","simpleDigraphs","digraphs"
saveFileBase = "results2/4noddsfses" -- graphProps and variance partition added automatically

-- generate sets
print("------------------------------------------------------------");
print(concatenate("Nodes: ",toString(n)));
print("Generating graphs ...")
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
    saveFileBase = concatenate(saveFileBase, "_", graphProps);
    basePartitions = generateBasePartitions(n);
    env = createEnv(n);
)

-- main loop
actuallyComputed = 0
for ptt in basePartitions do (
    print("-------------------------------------------------");
    print(concatenate("Partition: ", toString(ptt)));

    -- calculate all vanishing ideals
    vanIdealDict = new MutableHashTable;
    print("Computing vanishing ideals ...");
    counter = 0;
    elapsedTime for g in graphs do (
        progressBar(counter,#graphs);
        counter = counter +1;
        I = toString(vanishingIdeal(env,g,ptt,engine,-1,cyclicAllowed));
        vanIdealDict#g = I;
        actuallyComputed = actuallyComputed + 1;
    );

    -- compare all vanishing ideals
    if engine == "m2" then
        vanIdealList = for g in graphs list value(vanIdealDict#g)
    else if engine == "maple" then
        vanIdealList = for g in graphs list vanIdealDict#g;
    covEqClasses = compareVanIdeals(vanIdealList,engine);

    -- save results
    fileName = concatenate(saveFileBase,"_",toString(ptt));
    saveResults(fileName,env,ptt,graphs,null,covEqClasses);
)
print("------------------------------------------------------------");
print(concatenate("Number of vanishing ideals actually computed: ",toString(actuallyComputed)));
print("Finished.")