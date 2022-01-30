
-- computes all vanishingIdeals of list of dags in environemnt env 
-- with the variance partition in eqVarPart with a timeLimit, i.e.
-- if a computations takes longer than timeLimit, it will be skipped.
-- In this case, vanIdeal output will be null and the computation time -1.
-- output: (ideals,computationTimes)
compAllVanIdTimeLim = (env,dags,eqVarPart,timeLimit) -> (

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
    vIdeal := (e,d,v) -> elapsedTiming(vanishingIdeal(e,d,v));

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


-- gets ideal and returns a string of maple code that generates this ideal
-- in maple
idealM2ToMpl = (ideal) -> (
    str := substring(toString(ideal),5);
    str = addUnderline(str);
    str = concatenate("PolynomialIdeal",str);
    return str;
)

-- takes string replaces '_' by '__'
addUnderline = str -> (
    l := sequence();
    for i from 0 to #str-1 do (
        l = append(l,str_i);
        if str_i == "_" then
            l = append(l,"_");
    );
    return concatenate(l);
);

-- gets string of ideal from maple generated from convert(ideal,string)
-- and returns a macauly2 ideal
-- maples ideals have the following structure:
-- POLYNOMIALIDEAL( ideal,variables = {...},...)
idealMplToM2 = (str) -> (
    l := sequence("ideal");
    i := 15; -- skip "POLYNOMIALIDEAL"
    while i < #str and str_i != "=" do (
        l = append(l,str_i);
        if str_i == "_" then
            i = i + 2
        else
            i = i + 1;
    );
    
    l = take(l,{0,#l-12}); -- cutoff ",variables "
    l = append(l,")");
    return value(concatenate(l));
)


-- computes elimination ideal with maple. Needs to have maple
-- installed and accessible by command line with command 'maple'.
-- If maple installed but 'maple' is not knwon in command line,
-- search for the path of the binaries of your maple installation 
-- (e.g. home/yourUserName/maple2021/bin/) and execute in command line 
-- 'export PATH=$PATH:/your/path/to/maple/'
--    input: I is ideal and toKeep list of indeterminants to intersect I with
--           (this is different from eliminate in m2)
--    output: (elimination Ideal, cpu time in maple used for calculation)
eliminateMaple = (I, toKeep) -> (

    -- create files
    fileMplCode := temporaryFileName() | ".mpl";
    fileMplOut := temporaryFileName();

    -- fill maple file and execute
    fileMplCode << "with(PolynomialIdeals):";
    filestr := concatenate("\"",toString(fileMplOut),"\"");
    fileMplCode << "fileNameWrite := " << filestr << ":";
    fileMplCode << "J := " << idealM2ToMpl(I) << ":";
    fileMplCode << "vars := " << addUnderline(toString(toKeep)) <<":";
    fileMplCode << "start:=time(): E:=EliminationIdeal(J,vars): t:=time()-start:";
    fileMplCode << "fileOut:=fopen(fileNameWrite,'WRITE','TEXT'):";
    fileMplCode << "writeline(fileOut,convert(E,string)):";
    fileMplCode << "writeline(fileOut,convert(t,string)):"<<endl;
    fileMplCode << close;
    run(concatenate("maple ",toString(fileMplCode)," -q"));
    
    -- retrieve result
    fileMplOut;
    results := lines(get(fileMplOut));
    elimIdeal := idealMplToM2(results_0);
    calcTime := results_1;
    removeFile(fileMplCode);
    removeFile(fileMplOut);

    -- return
    (elimIdeal,calcTime)
)