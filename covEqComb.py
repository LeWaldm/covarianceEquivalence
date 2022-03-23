from math import floor
from multiprocessing.sharedctypes import Value
import networkx as nx
from itertools import combinations,product
from joblib import Parallel, delayed
import numpy as np
import time


# helping functions
def generateDAGs(nodes,nparalleljobs=1):
    # generates all labeled DAGs with number nodes

    # generate powerset
    nUndirectedEdges = int(nodes*(nodes-1)/2)
    allCombinations = list(product([-1,0,1], repeat=nUndirectedEdges))
    # allCombinations = generateAllCombinations([-1,0,1],nUndirectedEdges)

    # function to generate DAG
    def createDAGs_from_combs(nodes,allCombinations):
        edges = list()
        for comb in allCombinations:
            edgesCurr = list()
            for i in range(1,nodes):
                for j in range(i+1,nodes+1):
                    ind = int( (i-1)*(nodes-1) - (i*(i-1)/2) + j-2 )
                    if comb[ind] == 1:
                        edgesCurr.append((i,j))
                    elif comb[ind] == -1:
                        edgesCurr.append((j,i))
            G = nx.DiGraph(edgesCurr)
            if nx.is_directed_acyclic_graph(G):
                edges.append(nx.edges(G))  
        return edges

    # generate DAGs in parallel
    if nparalleljobs == 1:
        return createDAGs_from_combs(nodes,allCombinations)
    else:
        subsets = np.array_split(allCombinations,njobs)
        results = Parallel(n_jobs=njobs)(delayed(createDAGs_from_combs)(nodes,subsets[i]) for i in range(njobs))
        return [x for subset in results for x in subset]

def equiv_classes(l):
    # calculates equivalence classes of entries in list l with 
    # relation of equality
    # returns: 
    #   - dictionary with keys represenatives and values occurence of that repr.
    #   - dictionary with keys number of members and value number of classes with 
    #       that number of members

    classes = dict()
    for i in range(len(l)):
        classes[l[i]] = classes.get(l[i],[]) + [i]
    counts = dict()
    for k in classes.keys():
        counts[len(classes[k])] = counts.get(len(classes[k]),0) + 1
    return classes, counts

# compute all partitions of the integer
# code taken from https://stackoverflow.com/questions/10035752/elegant-python-code-for-integer-partitioning
def partitions(n, I=1):
    yield (n,)
    for i in range(I, n//2 + 1):
        for p in partitions(n-i, i):
            yield (i,) + p

# compute all interesting partitions in our case
def interesting_ptts(n):
    ptts = list(partitions(n))
    out = list()
    for p in ptts:
        if p.count(1) > 1:
            l = list(p)
            l.sort(reverse=True)
            i = 1
            tmp = list()
            for j in range(len(l)):
                tmp.append(list(range(i,i+l[j])))
                i = i+l[j]
            out.append(tmp)
    return out


# function for computing properties of some set of graphs G
def compute_properties(edges):
    
    properties = list()
    for e in edges:
        # skeleton
        skeleton = frozenset(map(
            lambda x: frozenset([x[0],x[1]]), e))

        # unshielded colliders
        unshielded_colliders = set()
        for i in range(1,n+1):
            cand = filter(lambda x: x[1]==i, e )
            for (a,b) in combinations(cand,2):
                if (not (a[0],b[0]) in e and 
                    not (b[0],a[0]) in e):
                    unshielded_colliders.add((i,frozenset([a[0],b[0]])))
        unshielded_colliders = frozenset(unshielded_colliders)

        # fixed edges
        fixed_nodes = filter(lambda x: len(x)>1,ptt)
        fixed_nodes = [x for sublist in fixed_nodes for x in sublist]
        fixed_edges = frozenset(filter(
            lambda x: x[0] in fixed_nodes or x[1] in fixed_nodes, e))

        # add to properties
        properties.append((skeleton,unshielded_colliders,fixed_edges))
    return properties



# parameters
nodes = [4]
njobs = 1

# main function
tic = time.perf_counter()
for n in nodes:
    print("-----------------------------------------------")
    print("Nodes: " + str(n))

    # environment
    tic1 = time.perf_counter()
    graphs = generateDAGs(n,nparalleljobs=njobs)
    print(f"Generated all DAGs in {(time.perf_counter()-tic1):.2f}s.")
    ptts = interesting_ptts(n)

    # break data into subsets
    subsets = np.array_split(graphs,njobs)

    # main
    for ptt in ptts:
        print("-------------------------------------")
        print("Partition: " + str(ptt))

        # compute list of properties in parallel
        tic1 = time.perf_counter()
        results = Parallel(n_jobs=njobs)(delayed(compute_properties)(subsets[i]) for i in range(njobs))
        properties = [x for subset in results for x in subset]
        print(f"Computed all properties in {(time.perf_counter()-tic1):.2f}s.")

        # compute equivalence classes
        tic1 = time.perf_counter()
        _, counts = equiv_classes(properties)
        print(f"Computed all equivalence classes in {(time.perf_counter()-tic1):.2f}s.")

        # print results
        for k in sorted(counts.keys()):
            print(f'Number groups with {k} member(s): {counts[k]} classes')
toc = time.perf_counter()
print(f'Time elapsed in total: {(toc-tic):.2f}s')