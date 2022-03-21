load "lib/utils.m2"

-- parameters
nodes = 4;
ptts = {{{1,2},{3},{4}}};

-- get all cyclic dags
allGraphs = generateDGs(nodes);
cyclic = new MutableHashTable;
pointer = 0;
for g in allGraphs do 
    if checkIsCyclic(g) then (
        cyclic#pointer = g;
        pointer=pointer+1;
    )
cyclicGraphs = for i from 0 to pointer-1 list cyclic#i;


-- compute vanishing ideals of those graphs
env = createEnv(nodes)
for ptt in ptts do(
    print("-----------------------------------------------------------------------------------");
    print(toString(ptt));
    print("-----------------------------------------------------------------------------------");
    for g in cyclicGraphs do (
        print(g);
        I = elapsedTime (vanishingIdeal(env,g,ptt,"maple",-1,true));
    )
)
