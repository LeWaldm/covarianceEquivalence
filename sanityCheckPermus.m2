-- checks if equality groups from computing all vanishingIdeals
-- of all nodes directly vs computing them with the permutation technique 
-- are equal.
load "lib/loadAndSaveResults.m2"


filesPermu = {
    "results/final/permu3_{{1}, {2}, {3}}",
    "results/final/permu3_{{1, 2}, {3}}",
    "results/final/permu3_{{1, 2, 3}}",
    "results/final/permu4_{{1}, {2}, {3}, {4}}",
    "results/final/permu4_{{1, 2}, {3}, {4}}",
    "results/final/permu4_{{1, 2}, {3, 4}}",
    "results/final/permu4_{{1, 2, 3}, {4}}",
    "results/final/permu4_{{1, 2, 3, 4}}"
}
filesDirect = {
    "results/direct/direct3_{{1}, {2}, {3}}",
    "results/direct/direct3_{{1, 2}, {3}}",
    "results/direct/direct3_{{1, 2, 3}}",
    "results/direct/direct4_{{1}, {2}, {3}, {4}}",
    "results/direct/direct4_{{1, 2}, {3}, {4}}",
    "results/direct/direct4_{{1, 2}, {3, 4}}",
    "results/direct/direct4_{{1, 2, 3}, {4}}",
    "results/direct/direct4_{{1, 2, 3, 4}}"
}

for i from 0 to #filesPermu-1 do (

    convertToDagSet = fileName -> (
        (env,ptts,allGroups,dags,allIdeals) := loadResults(fileName);
        groups := allGroups_0;
        storage := new MutableHashTable;
        idx := 0;
        for j from 0 to #groups-1 do (
            storage#idx = set(apply(groups_j,m->dags_m));
            idx = idx + 1;
        );
        return set(for j from 0 to idx-1 list storage#j);
    );

    dagSetPermu = convertToDagSet(filesPermu_i);
    dagSetDirect = convertToDagSet(filesDirect_i);
    bool = (isSubset(dagSetPermu,dagSetDirect) and isSubset(dagSetDirect,dagSetPermu));
    print(concatenate(toString(i+1),": ", toString(bool)));
)
