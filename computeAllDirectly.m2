-- compute and compare ALL vanishing Ideals of some given 
-- variance partitions.

load "lib/utils.m2"
load "lib/loadAndSaveResults.m2"
varPart3 = {
    {},
    {{1,2}},
    {{1,2,3}}
};
varPart4 = {
    --{},
    --{{1,2}},
    --{{1,2},{3,4}},
    {{1,2,3}},
    {{1,2,3,4}}
};
nodes = 4;
allVarPart = varPart4;
saveFile = "results/oriented/direct4";


env = createEnv(nodes);
dags = generateDAGs(nodes);
for ptt in allVarPart do (
    ptt = unifyPtt(nodes,ptt);
    print(toString(ptt));
    groups = compVanishingIdealAllDirect(env,dags,ptt,"maple");
    f = concatenate(saveFile,"_",toString(ptt));
    saveResults(f,env,ptt,dags,null,groups);
)
