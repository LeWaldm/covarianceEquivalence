load "lib/loadAndSaveResults.m2"

-- This script checks if equivalence classes from different files are identical.
-- The parameters are two lists of file paths to compare, i.e. files1_i compared with files2_i
files1 = {}
files2 = {}

for i from 0 to #files1-1 do (

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

    dagSet1 = convertToDagSet(files1_i);
    dagSet2 = convertToDagSet(files2_i);
    bool = (isSubset(dagSet1,dagSet2) and isSubset(dagSet2,dagSet1));
    print(concatenate(toString(i+1),": ", toString(bool)));
)