-- requires package 
needsPackage "GraphicalModels"
needsPackage "DeterminantalRepresentations"
needsPackage "SchurRings"

-- generate environment with Ring,L,S matrices for arbitrary number of nodes 
createEnv = nodes -> (
    -- generate entries of L matrix
    entriesL := "";
    for i from 0 to nodes-1 do (
        for j from 0 to nodes-1 do (
            if i == j then 
                continue;
            if not (i == 0 and j == 1) then 
                entriesL = concatenate(entriesL,",");
            entriesL = concatenate(entriesL,"l_",toString(i+1),toString(j+1));
        );
    );
    
    -- generate R
    cmmd := concatenate("QQ[",entriesL);
    for i from 0 to nodes-1 do (
        for j from i to nodes-1 do (
            cmmd = concatenate(cmmd,",s_",toString(i+1),toString(j+1));
        );
    ); 
    cmmd = concatenate(cmmd,",MonomialOrder => Eliminate ",toString(nodes*(nodes-1)),"]");
    R := value(cmmd);
    
    -- generate S
    cmmd = "matrix{";
    for i from 0 to nodes-1 do (
        if i != 0 then
            cmmd = concatenate(cmmd,",");
        cmmd = concatenate(cmmd,"{");
        for j from 0 to nodes-1 do (
            if j != 0 then 
                cmmd = concatenate(cmmd,",");
            if i <= j then
                cmmd = concatenate(cmmd,"s_",toString(i+1),toString(j+1))
            else
                cmmd = concatenate(cmmd,"s_",toString(j+1),toString(i+1));
        );
        cmmd = concatenate(cmmd,"}");
    );  
    cmmd = concatenate(cmmd,"}");
    S := value(cmmd);
       
    -- generate Lfull
    cmmd = "matrix{";
    for i from 0 to nodes-1 do (
        if i != 0 then
            cmmd = concatenate(cmmd,",");
        cmmd = concatenate(cmmd,"{");
        for j from 0 to nodes-1 do (
            if j != 0 then 
                cmmd = concatenate(cmmd,",");
            if i == j then
                cmmd = concatenate(cmmd,"0")
            else
                cmmd = concatenate(cmmd,"l_",toString(i+1),toString(j+1));
        );
        cmmd = concatenate(cmmd,"}");
    );  
    cmmd = concatenate(cmmd,"}");
    Lfull := value(cmmd);
    
    -- generate toKeep
    cmmd = sequence("{");
    for i from 1 to nodes do (
        for j from i to nodes do(
            if not (i == 1 and j==1) then
                cmmd = append(cmmd,",");
            cmmd = append(cmmd,concatenate("s_",toString(i),toString(j)));
        );
    );
    cmmd = append(cmmd,"}");
    toKeep = value(concatenate(cmmd));

    -- toEliminate
    cmmd = concatenate("{",entriesL,"}");
    toEliminate = value(cmmd);
    
    -- generate output
    {nodes,R,S,Lfull,toEliminate,toKeep}
)

-- generates all possible n-tuple of vals
generateAllCombinations = (vals,n) -> (
    
    result := new MutableHashTable;
    resultCounter = 0;
    nVals := length(vals);
    nComb := nVals^n;       
    for j from 0 to nComb-1 do (
        l := new MutableHashTable;
        lCounter = 0;
        for i from 0 to n-1 do  (
            ind := floor(j / nVals^(n-1-i)) % nVals;           
            l#lCounter = vals_ind;
            lCounter = lCounter + 1;
        );
        result#resultCounter = for i from 0 to lCounter-1 list l#i;
        resultCounter = resultCounter + 1;
    );
    return for i from 0 to resultCounter-1 list result#i;
)

-- naive method to check if digraph is cyclic
checkIsCyclic = G -> (    
    gLocal := G;
    sinkVertices := sinks(gLocal);   
    while sinkVertices != {} do (
        gLocal = deleteVertices(gLocal,sinkVertices);
        sinkVertices = sinks(gLocal);
    );
    #vertices(gLocal) != 0 
)

-- generate all directed graphs without self loops
generateDGs = nodes -> (
    -- generate powerset
    nUndirectedEdges := nodes*(nodes-1)//2;
    allCombinations := generateAllCombinations({-1,0,1,2},nUndirectedEdges);
    allNodes := for i from 1 to nodes list i;

    -- generate directed graphs
    graphs := new MutableHashTable;
    for comb from 0 to #allCombinations-1 list (
        edgesCurr := {};
        for i from 1 to nodes-1 do (
            for j from i+1 to nodes do (
                ind = (i-1)*(nodes-1) - (i*(i-1)//2) + j-2; -- double checked  
                if (allCombinations_comb)_ind == 1 then 
                    edgesCurr = append(edgesCurr,{i,j})
                else if (allCombinations_comb)_ind == -1 then 
                    edgesCurr = append(edgesCurr,{j,i})
                else if (allCombinations_comb)_ind == 2 then (
                    edgesCurr = append(edgesCurr,{i,j});
                    edgesCurr = append(edgesCurr,{j,i});
                );      
            );
        );
        graphs#comb = digraph(allNodes,edgesCurr);      
    );
    return (for j from 0 to #keys(graphs)-1 list graphs#j);
)

-- generate all simple directed graphs without self loops
generateSimpleDGs = nodes -> (
    -- generate powerset
    nUndirectedEdges := nodes*(nodes-1)//2;
    allCombinations := generateAllCombinations({-1,0,1},nUndirectedEdges);
    allNodes := for i from 1 to nodes list i;

    -- generate simple directed graphs
    graphs := new MutableHashTable;
    for comb from 0 to #allCombinations-1 list (
        edgesCurr := {};
        for i from 1 to nodes-1 do (
            for j from i+1 to nodes do (
                ind = (i-1)*(nodes-1) - (i*(i-1)//2) + j-2; -- double checked  
                if (allCombinations_comb)_ind == 1 then (
                    edgesCurr = append(edgesCurr,{i,j});
                ) else ( if (allCombinations_comb)_ind == -1 then (
                    edgesCurr = append(edgesCurr,{j,i});                
                ););
            );
        );
        graphs#comb = digraph(allNodes,edgesCurr);      
    );
    return (for j from 0 to #keys(graphs)-1 list graphs#j);
)

-- generate all DAGs with certain number of nodes
generateDAGs = nodes -> (

    graphs := generateSimpleDGs(nodes);
    dags := new MutableHashTable;
    i := 0;
    for g in graphs do (
        if not(checkIsCyclic(g)) then (
            dags#i = g; 
            i = i +1;
        );    
    );
    return (for j from 0 to i-1 list dags#j);
)




-- lists all partitions of set s
allPartitions = s -> (
    p := partitions(length(toList(s)));
    l := {};
    for i from 0 to length(p)-1 do (
        tmpSet = partitions(s,toList(p_i));
        l = join(l,apply(tmpSet,x->apply(toList(x),toList)));
    );
    return l;
)

-- generates the base partitions B_n as described in the thesis
generateBasePartitions = n -> (
    pttOfInteger = partitions(n);
    basePtts =  for p in pttOfInteger list (
        counter = 1;
        for i in p list 
            for j from counter to counter+i-1 list (
                counter = counter+1;   
                j
            )
    )
)

-- transforms a partition into a unique format, ie.
-- (1) fills an implicit partition with all missing 1 element sets and
-- (2) sorts the partition
-- This could probably als be achieved with sets.
unifyPtt = (nodes,ptt) -> (

    -- fill partition
    for i from 1 to nodes do (
        j := 0;
        while j < #ptt and not isSubset(set({i}),set(ptt_j)) do
            j = j + 1;       
        if j == #ptt then 
            ptt = append(ptt,{i});
    );  

    -- sort partition
    ptt = sort(apply(ptt,sort));

    return ptt;
)


-- function that computes the vanishing ideal of a digraph
-- inputs:
-- - env: environment, output from createEnv() (with env_0 being number of nodes n)
-- - digraph: a Digraph from the graphicalModels package with nodes 0 to n-1
-- - variancePartiton: set of sets of nodes (from 0 to n-1) with equalVariances 
-- - engine: determine whether to use m2 or maple for heavy computations, default "m2" (one of "m2" or "maple")
-- - timeLimit: timeLimit for computation, -1 for no limit. Defaults to -1.
-- - saturateIdeal: boolean wheter to saturate the ideal (if cyclic graphs are allowed). Defaults to True.
-- output: with m2 elimination, returns ideal. With maple elimination returns  
--   ideal as maple string. Use idealMplToM2 to get a m2 ideal. If timeLimit reached
--   before calculation terminates, "null" is returned.
-- ways to call: 
--   vanishingIdeal(env,digraph)
--   vanishingIdeal(env,digraph,variancePartition)
--   vanishingIdeal(env,digraph,variancePartition,methodElim)
--   vanishingIdeal1(env,digraph,variancePartition,engine,timeLimit)
--   vanishingIdeal1(env,digraph,variancePartition,elimengineEngine,timeLimit, saturateIdeal)
vanishingIdeal = args -> (

    -- parse inputs
    n := args_0_0;
    R := args_0_1;
    S := args_0_2;
    Lfull := args_0_3;
    toEliminate := args_0_4;
    toKeep := args_0_5;
    g := args_1;
    equalVarGroups := null;
    methodElim := null;
    timeLimit := null;
    saturateIdeal := null;
    if #args >= 3 then
        equalVarGroups = args_2
    else 
        equalVarGroups = {};
    if #args >= 4 then
        methodElim = args_3
    else
        methodElim = "m2";
    if #args >= 5 then
        timeLimit = args_4
    else
        timeLimit = -1;
    if #args >= 6 then 
        saturateIdeal = args_5
    else 
        saturateIdeal = false;
    if methodElim == "m2" and timeLimit > 0 then 
        print("Warning: time limit only executed for elimination with maple.");

    -- calculate matrices
    L := hadamard(Lfull,adjacencyMatrix(reindexBy(g,"sort")));
    O := transpose(id_(R^n) - L) * S * (id_(R^n) - L);
    
    -- compute vanishing polynomials from assumption: no bidirected edges
    assNoBidirectedEdges := {};
    for i from 0 to n-2 do (
    	for j from i+1 to n-1 do 
    	    assNoBidirectedEdges = join(assNoBidirectedEdges,{O_(i,j)});
    );
    
    -- compute vanishing polynomials from additional assumption about equal variance groups
    assEqualVar := {};
    for i from 0 to #equalVarGroups-1 do (
    	group = equalVarGroups_i;
    	if #group > 1 then (
    	    for j from 0 to #group-2 do (
                --print(concatenate("(",toString(group_j-1),"-",toString(group_(j+1)-1),")"));
    	        polyn = O_(group_j-1,group_j-1) - O_(group_(j+1)-1,group_(j+1)-1);
    	        assEqualVar = join(assEqualVar,{polyn});
    	    )
        )
    );
    
    -- compute ideal
    I := ideal(join(assNoBidirectedEdges,assEqualVar));
    
    -- calculate the vanishing ideal as elimination ideal by eliminating all Lambda entries
    elimIdeal := null;
    print(saturateIdeal);
    if methodElim == "m2" then (
        if saturateIdeal then
            I = saturate(I, det(id_(R^n) - L));
        elimIdeal = eliminate(toEliminate,I);
    ) else if methodElim == "maple" then 
        if saturateIdeal then
            elimIdeal = saturateElimMpl(I,det(id_(R^n) - L),toKeep,timeLimit)
        else 
            elimIdeal = eliminateMaple(I,toKeep,timeLimit)
    else 
        error("Illegal value for engine.");
    return elimIdeal;
)
-- vanishingIdeal (args) := args -> vanishingIdeal(args);
-- vanishingIdeal (List,Digraph) := (e,d) -> vanishingIdeal1(e,d,{},"m2",-1,false);
-- vanishingIdeal (List,Digraph,List) := (e,d,l) -> vanishingIdeal1(e,d,l,"m2",-1,false);
-- vanishingIdeal (List,Digraph,List,String) := (e,d,l,m) -> vanishingIdeal1(e,d,l,m,-1,false);


-- takes string replaces '_' by '__'
addUnderline = str -> (
    l := new MutableHashTable;
    idx := 0;
    for i from 0 to #str-1 do (
        l#idx = str_i;
        idx = idx + 1;
        if str_i == "_" then (
            l#idx = "_";
            idx = idx + 1;
        );  
    );
    return concatenate(for i from 0 to idx-1 list l#i);
);

-- gets ideal and returns a string of maple code that generates this ideal
-- in maple
idealM2ToMpl = (ideal) -> (
    str := substring(toString(ideal),5);
    str = addUnderline(str);
    str = concatenate("PolynomialIdeal",str);
    return str;
)


-- gets string of ideal from maple generated from convert(ideal,string)
-- and returns a macauly2 ideal
-- maples ideals have the following structure:
--     POLYNOMIALIDEAL( ideal,variables = ...,characteristic = ..., known_groebner_bases = ...)
-- inputs: R ring of the ideal, str the ideal from maple as described
--         above
-- output: macauly2 ideal
idealMplToM2 = (str) -> (
    print("warning: inefficient implementation with sequences. Need to change to MutableHashTable.");
    if str == "null" then
        return null;
    l := sequence("ideal");
    i := 15; -- skip "POLYNOMIALIDEAL"
    while i < #str and str_i != "=" do (
        l = append(l,str_i);
        if str_i == "_" then
            i = i + 2
        else
            i = i + 1;
    );
    -- the following might be a bit cumbersome but it works
    out := null;
    if substring(str,i-11,10) == ",variables" then 
        l = take(l,{0,#l-12})
    else if substring(str,i-11,10) == "(variables" then 
        return ideal()
    else if substring(str,i-16,15) == ",characteristic" then 
        l = take(l,{0,#l-17})
    else if substring(str,i-16,15) == "(characteristic" then
        return ideal()
    else if substring(str,i-23,21) == ",known_groebner_bases" then
        l = take(l,{0,#l-23})
    else if substring(str,i-23,21) == "(known_groebner_bases" then
        return ideal()
    else
        error("Can't parse maple output.");         
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
--           (this is different from eliminate in m2). optional: timelimit in s.
--    output: elimination Ideal as maple string
--    call structure: (I,toKeep) or (I,toKeep,timeLimit)
-- eliminateMaple = method()
eliminateMaple = (I,toKeep,timeLimit) -> (

    -- create files
    fileMplCode := temporaryFileName() | ".mpl";
    fileMplOut := temporaryFileName();

    -- fill maple file and execute (TODO: put template as .mpl file into lib/
    --     that is filled as for compareFromDbm function)
    fileMplCode << "with(PolynomialIdeals):";
    filestr := concatenate("\"",toString(fileMplOut),"\"");
    fileMplCode << "fileNameWrite := " << filestr << ":";
    fileMplCode << "J := " << idealM2ToMpl(I) << ":";
    fileMplCode << "vars := " << addUnderline(toString(toKeep)) <<":";
    fileMplCode << "start:=time():";
    if timeLimit > 0 then 
        fileMplCode << "try E:=timelimit("<< toString(timeLimit) << ",EliminationIdeal(J,vars)): catch \"time expired\": E:=\"null\" end try:"
    else 
        fileMplCode << "E:=EliminationIdeal(J,vars):";
    fileMplCode << "t:=time()-start:";
    fileMplCode << "fileOut:=fopen(fileNameWrite,'WRITE','TEXT'):";
    fileMplCode << "writeline(fileOut,convert(E,string)):";
    fileMplCode << "writeline(fileOut,convert(t,string)):"<<endl;
    fileMplCode << close;
    run(concatenate("maple ",toString(fileMplCode)," -q"));
    
    -- retrieve result
    fileMplOut;
    results := lines(get(fileMplOut));
    --elimIdeal := idealMplToM2(results_0);
    -- calcTime := results_1;
    --removeFile(fileMplCode);
    removeFile(fileMplOut);

    -- return
    --return elimIdeal;
    return results_0;
)

-- saturates and the eliminates ideal in maple
saturateElimMpl = (I,polyn,toKeep,timeLimit) -> (
    fileMplCode := temporaryFileName() | ".mpl";
    fileMplOut := temporaryFileName();
    print(fileMplCode);

    -- fill maple file and execute (TODO: put template as .mpl file into lib/
    --     that is filled as for compareFromDbm function)
    fileMplCode << "with(PolynomialIdeals):";
    filestr := concatenate("\"",toString(fileMplOut),"\"");
    fileMplCode << "fileNameWrite := " << filestr << ":";
    fileMplCode << "J := " << idealM2ToMpl(I) << ":";
    fileMplCode << "vars := " << addUnderline(toString(toKeep)) <<":";
    fileMplCode << "J = saturate(J," << addUnderline(toString(polyn)) << "):";
    -- fileMplCode << "print(\"saturated\"):"; 
    fileMplCode << "start:=time():";
    if timeLimit > 0 then 
        fileMplCode << "try E:=timelimit("<< toString(timeLimit) << ",EliminationIdeal(J,vars)): catch \"time expired\": E:=\"null\" end try:"
    else 
        fileMplCode << "E:=EliminationIdeal(J,vars):";
    fileMplCode << "t:=time()-start:";
    -- fileMplCode << "print(\"eliminated\"):";
    fileMplCode << "fileOut:=fopen(fileNameWrite,'WRITE','TEXT'):";
    fileMplCode << "writeline(fileOut,convert(E,string)):";
    fileMplCode << "writeline(fileOut,convert(t,string)):"<<endl;
    fileMplCode << close;
    run(concatenate("maple ",toString(fileMplCode)," -q"));
    
    -- retrieve result
    fileMplOut;
    results := lines(get(fileMplOut));
    --removeFile(fileMplCode);
    removeFile(fileMplOut);
    return results_0;
)


-- nice progress bar for computations
-- takes value from 0 to 1 indicating the progress
progressBar = (curr,goal) -> (
    prc = round(numeric(curr/goal)*100);
    cmmd = concatenate("printf '",toString(curr),"/",toString(goal), " (",toString(prc)," percent)\r'");
    --print(cmmd);
    run(cmmd);
)


-- compares all vanishing ideals and returns groups of equal vanIdeals.
-- If compMethod == "m2" then vanIdeals needs to be list of trings
-- If compMethod == "maple" then vanideals needs to be list of strings.
compareVanIdeals = (vanIdeals,compMethod) -> (

    -- variables
    relPathToMplCompScript := "lib/compareIdeals.mpl";

    -- main
    if compMethod == "m2" then (  
        print("Comparing ideals ...");  
        nIdeals := #vanIdeals;
        equivResults := {};
        elapsedTime for i from 0 to nIdeals-2 do (
            progressBar(i/nIdeals);
            --print(concatenate(toString(i+1),"/",toString(#dags-1)));        
            for j from i+1 to nIdeals-1 do(
                if toString(vanIdeals_i) == "ideal()" then (
                    if toString(vanIdeals_j) == "ideal()" then
                        equivResults = append(equivResults,{i,j})
                ) else if toString(vanIdeals_j) != "ideal()" and
                    vanIdeals_i == vanIdeals_j then 
                        equivResults = append(equivResults,{i,j}
                );  
            );
        );

        print("Computing groups with equal ideals...");
        allNodes := for i from 0 to #vanIdeals-1 list i;
        groups = elapsedTime connectedComponents(graph(allNodes, equivResults));
        return groups;

    ) else if compMethod == "maple" then elapsedTime (

        -- print all ideals to a file with one ideal per line and call 
        --    maple script that compares all the ideals and calculates the
        --    groups and just returns the groups to m2
        print("Comparing and grouping all ideals ...");
        fileNameMplIn := temporaryFileName();
        fileNameMplOut := temporaryFileName();
        out := fileNameMplIn << "";
        out << toString(#vanIdeals)<<endl;
        for i from 0 to #vanIdeals-1 do 
            out << vanIdeals_i << endl;
        out << close;

        fileLines := lines(get(relPathToMplCompScript));
        mplCode := temporaryFileName() | ".mpl";
        mplCode << concatenate("fileNameIn:=\"",fileNameMplIn,"\":")<<endl;
        mplCode << concatenate("fileNameOut:=\"",fileNameMplOut,"\":")<<endl;
        for i from 2 to #fileLines-1 do 
            mplCode << fileLines_i << endl;
        mplCode << close;
        run(concatenate("maple -q ",mplCode));
        removeFile(fileNameMplIn);
        removeFile(mplCode);

        -- load results from maple
        groupsMpl := value(get(fileNameMplOut));
        groups := apply(groupsMpl,group->apply(group,i->i-1));
        removeFile(fileNameMplOut);
        return groups;
    ) else 
        error("Unknown compare method.");
)