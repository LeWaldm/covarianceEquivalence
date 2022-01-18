
-- check if any edge sets identical
dagsDupl = append(allEdges,{{1,2}});
counter = 0;
allGraphs = dagsDupl;
for i from 0 to #allGraphs -2 do(
    for j from i+1 to #allGraphs-1 do(
        if isEqualSets(set((allGraphs_i)), set((allGraphs_j))) then (
            print("-------------------------");
            print(allGraphs_i);
            print(i);
            print(j);
        );
        counter = counter+1;
    );
);
