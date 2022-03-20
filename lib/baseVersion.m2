-- compute and compare ALL vanishing Ideals of some given 
-- variance partitions.

load "lib/utils.m2"

-- parameters
n = 3;
engine = "maple"  -- one of "maple" or "m2"
cyclicAllowed = false        -- whether to allow cyclic graphs
saveFileBase = "results2/desdddf"

-- generate sets
print("------------------------------------------------------------");
print(concatenate("Nodes: ",toString(n)));
print("Generating sets ...")
elapsedTime (
    if cyclicAllowed then
        graphs = generateDGs(n)
    else
        graphs = generateDAGs(n);
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
    elapsedTime for g in graphs do (
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