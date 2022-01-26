
-- saves the results from a calculation into a file. 
-- If file already exists, function tests if the same env and dags in file.
-- If so, adds the variance partition and groups to the file. Else, error.
saveResults = (fileName,env,variancePartition,dags,ideals,groups) -> (
    
    -- add sets with 1 element to variancePartition
    nodes := env_0;
    for i from 1 to nodes do (
        j := 0;
        while j < #variancePartition and not isSubset(set({i}),set(variancePartition_j)) do
            j = j + 1;       
        if j == #variancePartition then 
            variancePartition = append(variancePartition,{i});
    );           
    
    -- main stuff
    if fileExists(fileName) then (
        
        -- load file
        print("File already exists.");
        fileLines = lines(get(fileName));
        print("Loaded file.");
        
        -- check if environments and DAGs are the same   
        envFile := loadPPrintList(fileLines,"env");
        dagsFile := loadPPrintList(fileLines,"dags");
        tmp := temporaryFileName();
        tmp << "";
        pprintEnvToFile(tmp,env,"env");
        pprintListToFile(tmp,dags,"dags");
        tmp << close;     
        tmp2 := temporaryFileName();
        tmp2 << "";
        pprintEnvToFile(tmp2,envFile,"env");
        pprintListToFile(tmp2,dagsFile,"dags");
        tmp2 << close;             
        if not lines(get(tmp)) == lines(get(tmp2)) then
            error("Environment or DAGs different.");
        print("Environment and DAGs identical.");

        -- check if variance partition already in file
        fileAllVariancePartitions = loadPPrintList(fileLines,"allVariancePartitions");
        if isSubset(set({variancePartition}),set(fileAllVariancePartitions)) then 
            error("VariancePartition already saved in the file.");
      
        -- save variancePartitions       
        allVariancePartitions := append(fileAllVariancePartitions,variancePartition);
        groupsFile := loadPPrintList(fileLines,"allIdenticalVanishingIdealGroups");
        allGroups := append(groupsFile,groups);   
        allIdealsFile := loadPPrintList(fileLines,"allVanishingIdeals");
        allIdeals := append(allIdealsFile,ideals);
        
        -- save new file
        removeFile fileName;
        file := fileName << "";
        pprintEnvToFile(file,envFile,"env");
        pprintListToFile(file,allVariancePartitions,"allVariancePartitions");
        pprintListToFile(file,allGroups,"allIdenticalVanishingIdealGroups");
        pprintListToFile(file,allIdeals,"allVanishingIdeals"); 
        pprintListToFile(file,dagsFile,"dags");        
        print("Saved variance partition with its equal vanishing Ideal groups.");
        
    ) else (
    
        -- create file
        file = fileName << "";
        print("Created new file.");
        
        -- save variables
        pprintEnvToFile(file,env,"env");
        pprintListToFile(file,{variancePartition},"allVariancePartitions");
        pprintListToFile(file,{groups},"allIdenticalVanishingIdealGroups");
        pprintListToFile(file,{ideals},"allVanishingIdeals");
        
        -- save all dags
        pprintListToFile(file,dags,"dags");
        
        -- user feedback
        print("Added data to the file.");
    );
   
    -- close file
    file << close;
    print("Closed file.");
)


-- prints list with new line for each element into file
pprintListToFile = (file,l,name) -> (
    file << name << " := {";
    if #l > 0 then (
        file << endl << "    " << toString(l_0);
        for i from 1 to #l-1 do (             
            file << "," << endl << "    " << toString(l_i);          
        );
    );
    file << endl << "};" << endl;
)

-- prints environment in a special such that not R but the actual Ring description printed
pprintEnvToFile = (file,env,name) -> (
    file << name << " := {" << endl << "    " << toString(env_0);
    file << "," << endl << "    " << toString(describe(env_1));
    for i from 2 to #env-1 do (             
        file << "," << endl << "    " << toString(env_i);          
    );
    file << endl << "};" << endl;
)

-- returns list printed with pprintListToFile into file with fileLines
loadPPrintList = (fileLines,listNameFile) -> (
    i := 0;
    while i < #fileLines-1 do (
        if substring(fileLines_i,0,length(listNameFile)) == listNameFile then break;
        i = i + 1;
    );
    if i == #fileLines then 
        error(concatenate("Did not find list ",listNameFile," in file."));   
    j := i + 1;    
    cmmnd := "{";
    while j < #fileLines and fileLines_j != "};" do (
        cmmnd = concatenate(cmmnd,fileLines_j);  
        j = j + 1;
    );
    cmmnd = concatenate(cmmnd,"}");
    value(cmmnd)
)


-- loads results saved by function save results and returns them as tupel
loadResults = (fileName) -> (
    if not fileExists(fileName) then
        error("File does not exist.");
    fileLines = lines(get(fileName));
    env = loadPPrintList(fileLines,"env");
    allVariancePartitions = loadPPrintList(fileLines,"allVariancePartitions");
    allIdenticalVanishingIdealGroups = loadPPrintList(fileLines,"allIdenticalVanishingIdealGroups");
    dags = loadPPrintList(fileLines,"dags");
    ideals = loadPPrintList(fileLines,"allVanishingIdeals");
    (env,allVariancePartitions,allIdenticalVanishingIdealGroups,dags,ideals)
);

