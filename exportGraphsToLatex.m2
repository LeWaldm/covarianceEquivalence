load "lib/loadAndSaveResults.m2"

-- script to export the graphs from ptt {{1, 2}, {3}, {4}} to
-- a bib text string saved in an output file
--      fileName: name of input file, as programmed only makes sense   
--          with current one
--      fileOut: filename that the string is saved in 
--      scale: float, indicates the scale parameter in tikZ pictures in latex
--      nrows: number of rows to print the graphs in
--      ncols: number of columns to print the graphs in. If nrows and ncols full,
--          a new latex figure will be created.

fileName = "results/4nodes_dags_{{1, 2}, {3}, {4}}";
fileOut = "bibTextStringGraphs";
scale = 0.45;
nrows = 4;
ncols = 5;

-- load data
(env,allVariancePartitions,allIdenticalVanishingIdealGroups,dags,ideals) = loadResults(fileName);
groups = allIdenticalVanishingIdealGroups_0;

-- extract dags with invertible edge 3->4
i := 0;
l := new MutableHashTable;
for g in groups do 
    if #g == 2 then (
        G := dags_(g_0);
        if member({3,4},edges(G)) then
            l#i = G
        else 
            l#i = dags_(g_1);
        i = i + 1;
    )

-- print them to latex notation
i = 0;
nGraphs = #keys(l)
strAll = new MutableHashTable;
strCount = 0;
addStr = str -> (
    strAll#strCount = str;
    strCount = strCount + 1;
)
while i < nGraphs do (

    -- start new figure
    addStr("% new figure --------------------------------------------------------------------\n");
    addStr("\\begin{figure}[h]
                \\centering\n");

    -- iterate over rows
    row = 0;
    while (row < nrows) and (i < nGraphs) do (

        -- iterater over columns 
        col = 0;
        while (col < ncols) and (i < nGraphs) do (
            
            -- get string
            str = showTikZ(l#i);
            str = substring(str,2,#str);
            str = concatenate("\\",str);
            str = substring(str,0,#str - 2);
            i = i+1;

            -- add scale
            strA = substring(str,0,44);
            strB = substring(str,44,#str);
            str = concatenate(strA,"scale=",toString(scale), strB);

            -- add to string 
            if col > 0 then
                addStr("\\hfill");
            addStr(str);
            
            -- change vars
            col = col+1;
        );

        -- introduce line break to next line
        addStr("\n\n");
        addStr("\\vspace*{4pt}\n");
        addStr("% new row ------------------------------------------------------\n");
        row = row+1;
    );

    -- end figure
    addStr("\\caption{Caption}");
    addStr("\n\\end{figure}\n\n");
)

-- write final string to file
str = concatenate(for i from 0 to #keys(strAll)-1 list strAll#i);
fileOut << str << close;
print(nGraphs);