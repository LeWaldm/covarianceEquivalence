
-- computes all vanishingIdeals of list of dags in environemnt env 
-- with the variance partition in eqVarPart with a timeLimit, i.e.
-- if a computations takes longer than timeLimit, it will be skipped.
-- This function also uses multi threading to compute ideals in parallel.
-- Precisely, allowableThreads-1 threads will be used.
-- In this case, vanIdeal output will be null and the computation time -1.
-- output: (ideals,computationTimes)
-- ways to call this function:
--     compAllVanIdTimeLim(env,dags,eqVarPart,timeLimit)
--     compAllVanIdTimeLim(env,dags,eqVarPart,timeLimit,elimMethod)
compAllVanIdTimeLim = args -> (

    -- handle input
    if #args!=4 and #args!=5 then
        error("Input arguments have to be 4 or 5.");
    env := args_0;
    dags := args_1;
    eqVarPart := args_2;
    timeLimit := args_3;
    elimMethod := null;
    if #args == 4 then
        elimMethod = "m2"
    else 
        elimMethod = args_4;

    if allowableThreads < 2 then
        error("Need at least 2 allowable Threads.");

    ideals := new MutableHashTable;
    compTime := new MutableHashTable;
    tasks := new MutableHashTable;
    taskIndices := new MutableHashTable;
    nTasks := allowableThreads-1;
    currDag := 0;
    tasksFinished := 0;
    taskMonitored := new MutableHashTable;
    taskStarts := new MutableHashTable;
    --print(instance(vanishingIdeal1,FunctionClosure));
    vIdeal := (e,d,v) -> elapsedTiming(vanishingIdeal(e,d,v,elimMethod));

    -- fill tasks
    for t from 1 to nTasks do (
        tasks#t = schedule(vIdeal,(env,dags#currDag,eqVarPart));
        taskIndices#t = currDag;
        taskStarts#t = currentTime();
        currDag = currDag + 1; 
        taskMonitored#t = true;
    );

    -- main scheduler loop
    result:=0;
    vanIdeal:=0;
    cTime:=0;
    while tasksFinished < #dags do (
        for t from 1 to nTasks do (
            
            --print("loop begin");
            if not taskMonitored#t then (
                continue;
            ) else if isReady tasks#t then (
                -- add results to lists
                --print(concatenate("retrieveResults: ",toString(taskIndices#t)));
                result := taskResult(tasks#t);
                if instance(result,Nothing) then (
                    vanIdeal = null;
                    cTime = -2;
                    print("---------------------------------------------------");
                ) else (
                    result = toList(result);
                    vanIdeal = (result)_1;
                    cTime = (result)_0;
                );

                ideals#(taskIndices#t) = vanIdeal;
                compTime#(taskIndices#t) = cTime;

                -- update current task and give user feedback
                tasksFinished = tasksFinished + 1;
                print(concatenate(toString(tasksFinished),"/",toString(#dags)));

                -- schedule new task if still dags to compute
                if currDag >= #dags then (
                    taskMonitored#t = false;
                ) else (        
                    tasks#t = schedule(vIdeal,(env,dags#currDag,eqVarPart));
                    taskIndices#t = currDag;
                    taskStarts#t = currentTime();
                    currDag = currDag + 1; 
                    --print(concatenate("start: ",toString(taskIndices#t)));
                );
            ) else if currentTime() - taskStarts#t > timeLimit then (
                --print(concatenate("terminate: ",toString(taskIndices#t)));
                cancelTask tasks#t;
                taskStarts#t = currentTime();
                tasks#t = schedule(()->(-1,null,));
            );
        );
        
        nanosleep 10000000;
    );
    print("donecompall");

    -- sort resulting lists such that they ressemble the dag input list
    listIdeals = {};
    listCompTime = {};
    for i from 0 to #dags-1 do (
        listIdeals = append(listIdeals,ideals#i);
        listCompTime = append(listCompTime,compTime#i);
    );

    return (listIdeals,listCompTime);
);


-- lists all partitions of set s
needsPackage "SchurRings"
allPartitions = s -> (
    p := partitions(length(toList(s)));
    l := {};
    for i from 0 to length(p)-1 do (
        tmpSet = partitions(s,toList(p_i));
        l = join(l,apply(tmpSet,x->apply(toList(x),toList)));
    );
    return l;
)

-- function that creates all the unique topologically sorted dags from txt file
-- file has format of http://users.cecs.anu.edu.au/~bdm/data/digraphs.html,
-- ie one dag per line, entries of directed edges matrix in row form
-- with 1 for an edge
needsPackage "GraphicalModels"
generateDagsFromFile = file -> (
    fileLines := lines(get(file));
    l := length(fileLines_0);
    nodes = round((1 + sqrt(1+8*l) )//2);
    dags := {};
    allNodes := for i from 1 to nodes list i;

    for d from 0 to length(fileLines)-1 do (
        edgesList := {};
        for i from 1 to nodes-1 do (
            for j from i+1 to nodes do (
                ind = (i-1)*(nodes-1) - (i*(i-1)//2) + j-2; -- double checked  
                if (fileLines_d)_ind == "1" then 
                    edgesList = append(edgesList,{i,j});
            );
        );
        dags = append(dags,digraph(allNodes,edgesList));
    );
    return dags;
)


-- function that computes groups of graphs with identical vanishing Ideal
-- input: set of graphs to compare as list of digraphs and 
--        equal variance groupings as list of lists
-- output: list of lists with groups index of graphs with identical vanishing ideal
compVanishingIdealAll = method()
compVanishingIdealAll1 := (env,dags,eqVarPart,elimMethod) -> (
    vanishingIdeals := {};
    print("Computing and saving ideals ... ");
    elapsedTime (for i from 0 to #dags-1 do (
        print(concatenate(toString(i+1),"/",toString(#dags)));
        vanishingIdeals = append(vanishingIdeals,vanishingIdeal(env,dags_i,eqVarPart,elimMethod));    
    ));

    -- compute groups with identical vanishingIdeal
    print("Comparing ideals ...");
    elapsedTime(
    equivResults := {};
    for i from 0 to #dags-2 do (
        --print(concatenate(toString(i+1),"/",toString(#dags-1)));        
        for j from i+1 to #dags-1 do(
            if toString(vanishingIdeals_i) == "ideal()" then (
                if toString(vanishingIdeals_j) == "ideal()" then
                    equivResults = append(equivResults,{i,j})
            ) else if toString(vanishingIdeals_j) != "ideal()" and
                vanishingIdeals_i == vanishingIdeals_j then 
                    equivResults = append(equivResults,{i,j}
            );  
        );
    ););

    print("Computing groups with equal ideals...");
    allNodes := for i from 0 to #dags-1 list i;
    groups = time connectedComponents(graph(allNodes, equivResults));
    (groups,vanishingIdeals)
)
compVanishingIdealAll (List,List,List) := 
    (e,d,v) -> compVanishingIdealAll1(e,d,v,"m2");
compVanishingIdealAll (List,List,List,String) := 
    (e,d,v,s) -> compVanishingIdealAll1(e,d,v,s);