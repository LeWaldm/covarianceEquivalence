load "utils.m2";

nodes = 4;
equalVarAss = {{1,2}};

env = createEnv(nodes)
dags = time generateDAGs(nodes);
groups = time compVanishingIdealAllOpt(dags,equalVarAss,envs);
printGroups(dags,groups);

--test git credentials
