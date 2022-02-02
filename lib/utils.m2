-- requires package 
needsPackage "GraphicalModels"
needsPackage "DeterminantalRepresentations"

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

-- generates all possible n-tuple of vals (recursion not most clean ever but okay)
generateAllCombinations = (vals,n) -> (
    
    result := ();
    nVals := length(vals);
    nComb := nVals^n;       
    for j from 0 to nComb-1 do (
        l := {};
        for i from 0 to n-1 do  (
            ind := floor(j / nVals^(n-1-i)) % nVals;           
            l = append(l,vals_ind);
        );
        result = append(result,l);
    );
    result
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

-- generate all DAGs with certain number of nodes
generateDAGs = nodes -> (

    -- generate powerset
    nUndirectedEdges := nodes*(nodes-1)//2;
    allCombinations := generateAllCombinations({-1,0,1},nUndirectedEdges);
    allNodes := for i from 1 to nodes list i;

    -- extract dags
    dags := {};
    for comb from 0 to #allCombinations-1 list (
        
        -- generate graph
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
        g := digraph(allNodes,edgesCurr);
        
        -- only add if graph acylic
        if not(checkIsCyclic(g)) then (
            dags = append(dags,g);           
        );
    );
    dags
)


-- function that computes the vanishing ideal of a digraph
-- inputs:
-- - env: environment, output from createEnv() (with env_0 being number of nodes n)
-- - digraph: a Digraph from the graphicalModels package with nodes 0 to n-1
-- - variancePartiton: set of sets of nodes (from 0 to n-1) with equalVariances 
-- ways to call: 
--   vanishingIdeal(env,digraph)
--   vanishingIdeal(env,digraph,variancePartition)
--   vanishingIdeal(env,digraph,variancePartition,methodElim)
vanishingIdeal = method();
vanishingIdeal1 = args -> (

    -- assign local environment
    n := args_0_0;
    R := args_0_1;
    S := args_0_2;
    Lfull := args_0_3;
    toEliminate := args_0_4;
    toKeep := args_0_5;
    g := args_1;
    equalVarGroups := args_2;
    methodElim := args_3;
    L := hadamard(Lfull,adjacencyMatrix(reindexBy(g,"sort")));

    -- calculate Omega
    O := transpose(id_(R^n) - L) * S * (id_(R^n) - L);
    
    -- compute vanishing polynomials from assumption: no bidirected edges
    assNoBidirectedEdges := {};
    for i from 0 to n-2 do (
    	for j from i+1 to n-1 do (
            --print(concatenate("(",toString(i),",",toString(j),")"));
    	    assNoBidirectedEdges = join(assNoBidirectedEdges,{O_(i,j)});
    	)
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
    --eliminateParallel(toEliminate,I)
    --elapsedTime (gb(I));
    --elapsedTime (groebnerBasis(I, Strategy=>"MGB"));
    --elapsedTime eliminateExpGb(toEliminate,I);
    elimIdeal := null;
    if methodElim == "m2" then
        elimIdeal = eliminate(toEliminate,I)
    else if methodElim == "maple" then
        (elimIdeal = eliminateMaple(I,toKeep,5000);
        print("warning: limit set to 5000s, string returned");)
    else 
        error("Illegal value for elimMethod.");
    return elimIdeal;
)
vanishingIdeal (List,Digraph) := (e,d) -> vanishingIdeal1(e,d,{},"m2");
vanishingIdeal (List,Digraph,List) := (e,d,l) -> vanishingIdeal1(e,d,l,"m2");
vanishingIdeal (List,Digraph,List,String) := (e,d,l,m) -> vanishingIdeal1(e,d,l,m);



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
--     POLYNOMIALIDEAL( ideal,variables = {...},...)
-- inputs: R ring of the ideal, str the ideal from maple as described
--         above
-- output: macauly2 ideal
idealMplToM2 = (str) -> (
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
--    output: (elimination Ideal, cpu time in maple used for calculation)
--    call structure: (I,toKeep) or (I,toKeep,timeLimit)
-- eliminateMaple = method()
eliminateMaple = (I,toKeep,timeLimit) -> (

    -- create files
    fileMplCode := temporaryFileName() | ".mpl";
    fileMplOut := temporaryFileName();

    -- fill maple file and execute
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
    calcTime := results_1;
    removeFile(fileMplCode);
    removeFile(fileMplOut);

    -- return
    --return elimIdeal);
    return results_0;
)
-- eliminateMaple(Ideal,List) := (i,v) -> eliminateMaple1(i,v,-1)
-- eliminateMaple(Ideal,List,ZZ) := (i,v,t) -> eliminateMaple1(i,v,t)


-- fills an implicit partition with 1 element sets
fillPartition = (nodes,ptt) -> (

    for i from 1 to nodes do (
        j := 0;
        while j < #ptt and not isSubset(set({i}),set(ptt_j)) do
            j = j + 1;       
        if j == #ptt then 
            ptt = append(ptt,{i});
    );  
    return sort(ptt);
)

lprint = l -> for i from 0 to #l-1 do print(l_i);

-- nice progress bar for computations
-- takes value from 0 to 1 indicating the progress
progressBar = prc -> (
    run(concatenate("printf '",toString(numeric(prc)*100)," percent \r'"));
)