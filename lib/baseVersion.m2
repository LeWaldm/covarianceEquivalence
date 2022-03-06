-- compute and compare ALL vanishing Ideals of some given 
-- variance partitions.

load "lib/utils.m2"

-- parameters
n = 3;
engine = "m2"  -- one of "maple" or "m2"
saveFileBase = "results/base/3base"

-- generate sets
print("------------------------------------------------------------");
print(concatenate("Nodes: ",toString(n)));
print("Generating sets ...")
elapsedTime (
    dags = generateDAGs(n);
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
    elapsedTime for dag in dags do (
        I = toString(vanishingIdeal(env,dag,ptt,engine));
        vanIdealDict#dag = I;
        actuallyComputed = actuallyComputed + 1;
    );

    -- compare all vanishing ideals
    if engine == "m2" then
        vanIdealList = for d in dags list value(vanIdealDict#d)
    else if engine == "maple" then
        vanIdealList = for d in dags list vanIdealDict#d;
    covEqClasses = compareVanIdeals(vanIdealList,engine);

    -- save results
    fileName = concatenate(saveFileBase,"_",toString(ptt));
    saveResults(fileName,env,ptt,dags,null,covEqClasses);
)
print("------------------------------------------------------------");
print(concatenate("Number of vanishing ideals actually computed: ",toString(actuallyComputed)));
print("Finished.")