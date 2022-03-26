This code was developed as part of the Bachelor thesis 'Computational Study of Equivalence of Graphical Models with Groupwise Equal Error variances' at the Technical University of Munich (TUM).

This code was tested in Macaulay2 1.19.1 and Maple 2022 under Ubuntu 20.04LTS.

### Overview

- best check startHere.m2 and follow the instructions to just explore the results
- lib/ contains the main computational functions where lib/improvedVersion is the main computational script
- results/ contains the results, the file names should give enough information about the file contents
- multiple scripts are found in the root folder; they are also useful, but not core functionality as the scripts in lib/

### Connecting Macaulay2 to Maple

In order to utilize Maple to perform heavy computations, you need an active Maple license. Moreover, you need to be able to start maple in terminal by writing 'maple'. Even if this is possible, it might not work in Macaulay2. In every terminal you start, you might need to execute ```export PATH=$PATH:/home/username/maple2022/bin/``` (respectively your path to the maple binary) before starting Macaulay2 for the connection to Maple to work.
