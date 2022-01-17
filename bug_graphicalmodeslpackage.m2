restart
loadPackage "GraphicalModels"

-- create two different graphs
G1 = digraph({{1,2},{2,3}})
R1 = gaussianRing G1
L1 = directedEdgesMatrix R1

G2 = digraph({{1,2},{3,2}})
R2 = gaussianRing G2
L2 = directedEdgesMatrix R2

-- however:  
gens R1 == gens R2 -- expected false
L1 == L2  -- expected: false

-- Questions: 
--   - shouldn't L1 and L2 be different? (i.e. L2 different)
--   - gens R1 and gens R2 could be idential if they included all possible 
--     entries (i.e. l12,l13,l21,l23,l31,l32) but they don't

-- Troubleshooting:
--   - it seems like the gaussianRing does not reset after executed once. 
--     When I restart macauly and first execute the second graph, L2 is correct
--     but L1 not.
