load "lib/utils.m2"
load "lib/loadAndSaveResults.m2"

-- functions
-- print number of group members per group
printGroupCounts = groups -> (
    oneEltGroups := 0;
    for i from 0 to #groups-1 do (
        if #(groups_i) > 1 then
            print(concatenate(toString(i),": ",toString(#(groups_i))))
        else 
            oneEltGroups = oneEltGroups+1;
    );
    print(concatenate("Number digraphs with no groups members: ",toString(oneEltGroups)));
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
    noGroupCounter := 0;
    for i from 0 to #groups-1 do (
        group := groups_i;
        groupCounter = groupCounter + 1;
        print("-------------------------------------------------------------------");
        print(concatenate("Group ",toString(groupCounter)," (",toString(#group)," members)"));
        for j from 0 to #group-1 do (
            print(graphs_(group_j));   
        );
        if (#group == 1) then (
            noGroupCounter = noGroupCounter + 1;
        );
    );
    print(concatenate("Number unique graphs: ",toString(noGroupCounter),"/",toString(#set(flatten(groups)))));
)

-- out of all groups with m members, print n randomly selected groups
showNGroupsWithMMembers = (dags,groups,n,m) -> (
    groups = random(groups);
    l := {};
    nGroupsFound := 0;
    i :=0;
    while nGroupsFound < n and i < #groups do (
        if #(groups_i) == m then (
            l = append(l,groups_i);
            nGroupsFound = nGroupsFound+1;
        );
        i = i + 1;
    );
    if nGroupsFound == 0 then 
        print(concatenate("No groups with ",toString(m)," members were found."))
    else
        print(printAllGroups(dags,l));
)

-- show the algEqGroup of a particular graph
showAlgEqGroupOf = (dags,groups,dag) -> (
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
    i := 0;
    while indGroup == -1 and i < #groups do (
        if isSubset(set({indGraph}),set(groups_i)) then
            indGroup = i
        else
            i = i + 1;
    );
    if indGroup == -1 then
        error("No Group contains the given DAG.");

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



