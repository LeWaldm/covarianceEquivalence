from math import floor
from multiprocessing.sharedctypes import Value
import networkx as nx
from itertools import combinations

# parameters
nodes = [5]


# helping functions
def generateAllCombinations(vals,n):
    # generates all possible n-tuple of vals

    result = list()
    nVals = len(vals)
    nComb = nVals**n   
    for j in range(nComb): 
        l = list()
        for i in range(n):
            ind = floor(j / nVals**(n-1-i)) % nVals      
            l.append(vals[ind])
        result.append(l)
    return result

def generateDAGs(nodes):
    # generates all labeled DAGs with number nodes

    # generate powerset
    nUndirectedEdges = int(nodes*(nodes-1)/2)
    allCombinations = generateAllCombinations([-1,0,1],nUndirectedEdges)
    allNodes = [x for x in range(nodes)]

    # generate directed graphs
    graphs = list()
    for comb in range(len(allCombinations)):
        edgesCurr = list()
        for i in range(1,nodes):
            for j in range(i+1,nodes+1):
                ind = int( (i-1)*(nodes-1) - (i*(i-1)/2) + j-2 )
                if allCombinations[comb][ind] == 1:
                    edgesCurr.append((i,j))
                elif allCombinations[comb][ind] == -1:
                    edgesCurr.append((j,i))
        G = nx.DiGraph(edgesCurr)
        if nx.is_directed_acyclic_graph(G):
            graphs.append(G)   
    return graphs

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

def generatePtts(n):

    if not (n==3 or n==4 or n==5):
        raise ValueError("Only 3 nodes allowed!")
    out =  [
        [[1],[2],[3]],
        [[1,2],[3]],
        [[1,2,3]]
    ]
    if n == 4:
        out = [
            [[1],[2],[3],[4]],
            [[1,2],[3],[4]],
            [[1,2,3],[4]],
            [[1,2,3,4]]
        ]
    if n==5:
        out = [
            [[1],[2],[3],[4],[5]],
            [[1,2],[3],[4],[5]],
            [[1,2],[3,4],[5]],
            [[1,2,3],[4,5]]
        ]
    return out


# main function
for n in nodes:

    # environment
    graphs = generateDAGs(n)
    ptts = generatePtts(n)

    # main
    for ptt in ptts:

        # compute list of properties
        properties = list()
        for g in graphs:

            # skeleton
            skeleton = frozenset(map(
                lambda x: frozenset([x[0],x[1]]),
                nx.edges(g)
            ))

            # unshielded colliders
            unshielded_colliders = set()
            for i in range(1,n+1):
                edges = nx.edges(g)
                cand = filter(lambda x: x[1]==i, edges )
                for (a,b) in combinations(cand,2):
                    if (not (a[0],b[0]) in edges and 
                        not (b[0],a[0]) in edges):
                        unshielded_colliders.add((i,frozenset([a[0],b[0]])))
            unshielded_colliders = frozenset(unshielded_colliders)

            # fixed edges
            fixed_nodes = filter(lambda x: len(x)>1,ptt)
            fixed_nodes = [x for sublist in fixed_nodes for x in sublist]
            fixed_edges = frozenset(filter(
                lambda x: x[0] in fixed_nodes or x[1] in fixed_nodes,
                nx.edges(g)
            ))

            # add to properties
            properties.append((skeleton,unshielded_colliders,fixed_edges))

        # compute equivalence classes
        _, counts = equiv_classes(properties)

        # save results
        print(str(ptt) + "-----------------------")
        for k in sorted(counts.keys()):
            print(f'with {k} members: {counts[k]} classes')