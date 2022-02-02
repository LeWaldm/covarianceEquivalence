fileNameIn := error("Needs to be filled before executing."):
fileNameOut := error("Needs to be filled before executing."):

fileIn := fopen(fileNameIn,READ,'TEXT'):
fileOut := fopen(fileNameOut,WRITE,'TEXT'):

# first line of fileIn should be number of ideals in file 
# (is the same as number of remaining lines in the file)
with(PolynomialIdeals):
with(GraphTheory):

# load all ideals 
nIdeals := parse(readline(fileIn)):
ideals := Array(1..nIdeals):
for i from 1 to nIdeals do
    #ideals(i) := convert(readline(fileIn),PolynomialIdeals:-PolynomialIdeal):
    tmp:=parse(readline(fileIn)):
    ideals(i):=parse(convert(tmp,string));
end do:
fclose(fileIn):

# compare all ideals
equivIdeals := Array([]):
k:=0:
for i from 1 to nIdeals-1 do 
    for j from i+1 to nIdeals do
        var1:=ideals(i):  
        var2:=ideals(j):
        if IdealContainment(var1,var2,var1) then
            k := k+1:
            equivIdeals(k) := {i,j}:
        end if:
    end do:
end do: 

# compute groups
groups := ConnectedComponents(Graph([seq(j,j=1..nIdeals)],convert(equivIdeals,set))):

# save output (convert to set of sets and then to string)
writeline(fileOut,convert(convert(map(s->convert(s,set),groups),set),string)):
fclose(fileOut):