load "lib/utils.m2"
load "lib/loadAndSaveResults.m2"
needsPackage "GraphicalModels"

-- functions
-- print number of group members per group
printGroupCounts = groups -> (
    groupCounts := new MutableHashTable;
    for i from 0 to #groups-1 do (
        if not groupCounts#?(#(groups_i)) then
            groupCounts#(#(groups_i)) = 1
        else
            groupCounts#(#(groups_i)) = 1 + groupCounts#(#(groups_i));
    );
    for i from 0 to max(keys(groupCounts)) do
        if groupCounts#?i then 
            print(concatenate("Number groups with ",toString(i), " member(s): ",toString(groupCounts#i)));
)

-- prints the digraphs in all groups with more than one memember
-- input: graphs and groups 
-- output: plot of groups in command line
printGroups = (graphs,groups) -> (
    groupCounter := 0;
    noGroupCounter := 0;
    for i from 0 to #groups-1 do (
        group := groups_i;
        if (#group > 1) then (
            groupCounter = groupCounter + 1;
            print("-------------------------------------------------------------------");
            print(concatenate("Group ",toString(groupCounter)," (",toString(#group)," members)"));
            for j from 0 to #group-1 do (
                print(graphs_(group_j));   
            );
        ) else (
            noGroupCounter = noGroupCounter + 1;
        );
    );
    print(concatenate("Graphs without group: ",toString(noGroupCounter),"/",toString(#graphs)));
)

-- print all groups in groups regardless of number of elements
printAllGroups = (graphs,groups) -> (
    groupCounter := 0;
    for i from 0 to #groups-1 do (
        group := groups_i;
        groupCounter = groupCounter + 1;
        print("-------------------------------------------------------------------");
        print(concatenate("Group ",toString(groupCounter)," (",toString(#group)," members)"));
        for j from 0 to #group-1 do (
            print(graphs_(group_j));   
        );
    );
)

-- out of all groups with m members, print n randomly selected groups
showNGroupsWithMMembers = (dags,groups,n,m) -> (
    groupsRand := random(groups);
    l := {};
    nGroupsFound := 0;
    i :=0;
    while (nGroupsFound < n) and (i < #groupsRand) do (
        if #(groupsRand_i) == m then (
            l = append(l,groupsRand_i);
            nGroupsFound = nGroupsFound+1;
        );
        i = i + 1;
    );
    if nGroupsFound < n then 
        print(concatenate("Only ",toString(nGroupsFound)," groups with ", toString(m), " members were found."))
    else
        printAllGroups(dags,l);
)

-- show the algEqGroup of a particular graph
showCovEqGroupOf = (dags,groups,dag) -> (
    -- find graph index
    indGraph := -1;
    i := 0;
    while indGraph == -1 and i < #dags do (
        if isEqualDags(dags_i,dag) then
            indGraph = i
        else
            i = i + 1;
    );
    if indGraph == -1 then
        error("Given DAG not found in dags.");
    
    -- find group index
    indGroup := -1;
    i = 0;
    while indGroup == -1 and i < #groups do (
        if isSubset(set({indGraph}),set(groups_i)) then
            indGroup = i
        else
            i = i + 1;
    );
    if indGroup == -1 then
        error("No group contains the given DAG.");

    -- display group 
    printAllGroups(dags,{groups_indGroup});
);

-- test for equality
isEqualSets = (s1,s2) -> (
    isSubset(s1,s2) and isSubset(s2,s1)
)
isEqualDags = (d1,d2) -> (
    isEqualSets(set(vertices(d1)),set(vertices(d2))) 
        and isEqualSets(set(edges(d1)), set(edges(d2)))
)


-- takes a variance partition and two DAGs and
-- outputs whether they are covariance equivalent based on the
-- conjecture of the thesis
conjectureThesis = (ptt,G1,G2) -> (

    -- print(G1);
    -- print(G2);

    -- (0) same vertices?
    if not sort(vertices(G1)) == sort(vertices(G2)) then (
        -- print("vertices");
        return false;
    );
        

    -- (i) identical skeleton?
    skel1 := set(apply(edges(G1), e->set(e)));
    skel2 := set(apply(edges(G2), e->set(e)));
    if not (isSubset(skel1,skel2) and isSubset(skel2,skel1)) then (
        -- print("skeleton");
        return false;
    );

    -- (ii) identical unshielded colliders?
    compUnshColl := (g) -> (
        unshieldedColliders := new MutableHashTable;
        c := 0;
        for v in vertices(g) do (
            tmp := new MutableHashTable;
            c1 := 0;
            for e in edges(g) do 
                if e_1 == v then (
                    tmp#c1 = e;
                    c1 = c1+1;
                );
            incoming = for i from 0 to #(keys(tmp))-1 list tmp#i;
            for i from 0 to #incoming-2 do 
                for j from i+1 to #incoming-1 do (
                    v1 := (incoming_i)_0;
                    v2 := (incoming_j)_0;
                    if not (member({v1,v2}, edges(g)) or member({v2,v1}, edges(g))) then (
                        unshieldedColliders#c = {v,set({v1,v2})};
                        c = c + 1;
                    );
                );
        );
        out = set(for i from 0 to #(keys(unshieldedColliders))-1 list unshieldedColliders#i);
        -- print(out);
        return out;
    );
    unshCollG1 := compUnshColl(G1);
    unshCollG2 := compUnshColl(G2);
    if not (isSubset(unshCollG1,unshCollG2) and isSubset(unshCollG2,unshCollG1)) then (
        -- print("colliders");
        return false;
    );

    -- (iii) edges between nodes with e.e.v.a. identical? 
    tmp := new MutableHashTable;
    c := 0;
    for i from 0 to #ptt-1 do 
        if #(ptt_i)>1 then 
            for j from 0 to #(ptt_i)-1 do (
                tmp#c = (ptt_i)_j;
                c = c + 1;
            );
    fixedVertices := for i from 0 to #(keys(tmp))-1 list tmp#i;
    compFixedEdges := (g,fixedVertices) -> (
        fixedEdges := new MutableHashTable;
        c := 0;
        for e in edges(g) do 
            if member(e_0, fixedVertices) or member(e_1, fixedVertices) then (
                fixedEdges#c = e;
                c = c + 1;
            );
        return set(for i from 0 to #(keys(fixedEdges))-1 list fixedEdges#i);
    );
    fixedEdgesG1 := compFixedEdges(G1,fixedVertices);
    fixedEdgesG2 := compFixedEdges(G2,fixedVertices);
    if not (isSubset(fixedEdgesG1,fixedEdgesG2) and isSubset(fixedEdgesG2,fixedEdgesG1)) then (
        -- print("fixed edges");
        return false;
    );
    return true;
)

-- takes a set of graphs, their corresponding computed equivalence
-- classes, the variance partition and a function that takes a partition and two graphs
-- and outputs true or false (e.g. checks some properties).
-- This function checks whether the input function is sufficient
-- and/or necessary to explain the computed results.
conjectureChecker = (graphs,groupsComp,ptt,conjFunc) -> (

    -- check if conjFunc necessary
    necessary := true;
    for group in groupsComp do (
        for i from 0 to #group-2 do (
            for j from i+1 to #group -1 do (
                bool = conjFunc(ptt,graphs_(group_i),graphs_(group_j));
                -- print(bool);
                if not bool then (
                    necessary = false;
                    break;
                );
            );
            if not necessary then
                break;
        );
        if not necessary then 
            break;
    );
    if necessary then
        print("Necessary? ----> YES")
    else 
        print("Necessary? ----> NO");

    --print("---------------------------------------------------------------------");
    -- check if conjFunc sufficient
    -- * calculate equivalence groups according to conjFunc
    equivalences := new MutableHashTable;
    counter := 0;
    for i from 0 to #graphs-2 do 
        for j from i+1 to #graphs-1 do (
            bool = conjFunc(ptt,graphs_i,graphs_j);
            -- print(bool);
            if bool then (
                equivalences#counter = {i,j};
                counter = counter + 1;
            );
        );

    edgesEq := for i from 0 to counter-1 list equivalences#i;
    g := graph((for i from 0 to #graphs-1 list i), edgesEq);
    groupsConj := connectedComponents(g);

    -- * compare the resulting groups
    setGroupsComp := set(apply(groupsComp, g->set(g)));
    setGroupsConj := set(apply(groupsConj, g->set(g)));
    if isSubset(setGroupsComp,setGroupsConj) and isSubset(setGroupsConj,setGroupsComp) then
        print("Sufficient? ---> YES")
    else 
        print("Sufficient? ---> NO");
)