load "lib/utils.m2";

nodes = 4;
ptt = {};

env = createEnv(nodes);
dags = generateDAGs(nodes);
groups = compVanishingIdealAllDirect(env,dags,ptt,"maple")
