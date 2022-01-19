load "utils.m2";

nodes = 4;
equalVarAss = {{1,2}};

env = setupEnv(nodes)
dags = time generateDAGs(nodes);
groups = time compVanishingIdealAllOpt(dags,equalVarAss,envs);
printGroups(dags,groups);
