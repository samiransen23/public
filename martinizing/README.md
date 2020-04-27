### backward.py
Script for converting CG to AA and vice-versa.  
Tested: POPG and POPC AA .gro constructed using charmm36 (on CHARMM-GUI) was martinized.  
`python backward.py -f md.gro -o test_martinized.gro -from charmm36 -to martini`

### Mapping
Folder containing `.map` files used by `backward.py`.  
Note: `popg.charmm36.map` is the updated mapping that uses 12 beads for each POPG molecule.
