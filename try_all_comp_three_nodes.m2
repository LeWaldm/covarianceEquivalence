load "utils.m2"


allGraphs = {
    digraph({1,2,3},{}),
    digraph({1,2,3},{{1,2}}),
    digraph({1,2,3},{{2,1}}),
    digraph({1,2,3},{{2,3}}),
    digraph({1,2,3},{{3,2}}),
    digraph({1,2,3},{{1,3}}),
    digraph({1,2,3},{{3,1}}),
    digraph({1,2,3},{{1,2},{2,3}}),
    digraph({1,2,3},{{3,1},{2,3}}),
    digraph({1,2,3},{{3,1},{1,2}}),
    digraph({1,2,3},{{3,2},{2,1}}),
    digraph({1,2,3},{{2,1},{1,3}}),
    digraph({1,2,3},{{1,3},{3,2}}),
    digraph({1,2,3},{{2,1},{3,1}}),
    digraph({1,2,3},{{1,2},{3,2}}),
    digraph({1,2,3},{{1,3},{2,3}}),
    digraph({1,2,3},{{1,2},{1,3}}),
    digraph({1,2,3},{{2,1},{2,3}}),
    digraph({1,2,3},{{3,2},{3,1}}),
    digraph({1,2,3},{{2,1},{3,1},{2,3}}),
    digraph({1,2,3},{{2,1},{3,1},{3,2}}),
    digraph({1,2,3},{{1,2},{3,2},{1,3}}),
    digraph({1,2,3},{{1,2},{3,2},{3,1}}),
    digraph({1,2,3},{{1,3},{2,3},{1,2}}),
    digraph({1,2,3},{{1,3},{2,3},{2,1}})
}


nodes = 25
for i from 0 to nodes-2 do (
    for j from i+1 to nodes-1 do(
        val = compare(allGraphs_i,allGraphs_j,{});
        if (val == true) then (
            printVal = "true";
        ) else (
            printVal = "f"
        );
        print(concatenate({toString(i),",",toString(j), ": ", printVal}));
        if (val == true) then (
            print(allGraphs_i);
            print(allGraphs_j);
        );
            
    );
)
