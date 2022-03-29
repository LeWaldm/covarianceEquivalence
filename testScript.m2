-- all combinations to test, for this to work comment the parameters in 
-- lib/baseVersion.m2 and lib/improvedVersion.m2
programms = {"lib/baseVersion.m2","lib/improvedVersion.m2"};
allnodes = {3,4};
allProps = {"dags","simpleDigraphs","digraphs"};
allEngines = {"maple"};

for p in programms do (
    for nloop in allnodes do {
        for propLoop in allProps do {
            for engineLoop in allEngines do {
                n = nloop;
                graphProps = propLoop;
                engine = engineLoop;
                saveFileBase = concatenate("test/",toString(n),toString(engine));
                print(n);
                print(graphProps);
                print(engine);
                elapsedTime load p;
            }
        }
    }

)