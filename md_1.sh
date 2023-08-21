BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
NC='\033[0m'                      # No Color
pdb_in=$1
echo -e "${BIYellow}Your input pdb: ${pdb_in}.pdb${NC}"
echo -e "${BIYellow}Running step 1, select amber99sb and tip3p water by default:${NC}"
echo -e "$\t{BIRed}gmx pdb2gmx -f ${pdb_in}.pdb -o ${pdb_in}.gro -water tip3p -ff amber99sb${NC}"
sleep 0.3
# run
gmx pdb2gmx -f $pdb_in.pdb -o $pdb_in.gro -water tip3p -ff amber99sb > 1.log
echo -e "${BIYellow}Running step 2, make box and add solvents:${NC}"
echo -e "${BIRed}  gmx editconf -f ${pdb_in}.gro -o ${pdb_in}_box.gro -c -d 1.0 -bt cubic${NC}"
echo -e "${BIRed}  gmx solvate -cp ${pdb_in}_box.gro -cs spc216.gro -o ${pdb_in}_solv.gro -p topol.top${NC}"
gmx editconf -f $pdb_in.gro -o $pdb_in_box.gro -c -d 1.0 -bt cubic > 2.1.log
gmx solvate -cp $pdb_in_box.gro -cs spc216.gro -o $pdb_in_solv.gro -p topol.top > 2.2.log
# spc is three point water model, should work for spc/e tip3p 
echo -e "${BIYellow}Fetching ions.mdp:${NC}"
wget -q http://www.mdtutorials.com/gmx/lysozyme/Files/ions.mdp
echo -e "${BIYellow}Add ions to the system to neutralize the charge:${NC}"
gmx grompp -f ions.mdp -c $pdb_in_solv.gro -p topol.top -o ions.tpr
gmx genion -s ions.tpr -o $pdb_in_solv_ions.gro -p topol.top -pname NA -nname CL -neutral
wget http://www.mdtutorials.com/gmx/lysozyme/Files/minim.mdp
gmx grompp -f minim.mdp -c $pdb_in_solv_ions.gro -p topol.top -o em.tpr -maxwarn 3
sleep 1
gmx mdrun -v -deffnm em -ntmpi 1  -pin on -nb gpu # run energy minimize
# gmx_mpi energy -f em.edr -o potential.xvg
wget http://www.mdtutorials.com/gmx/lysozyme/Files/nvt.mdp
gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
sleep 1
gmx mdrun -deffnm nvt -ntmpi 1 -pin on -nb gpu
# gmx_mpi energy -f nvt.edr -o temperature.xvg # Equilibration
wget http://www.mdtutorials.com/gmx/lysozyme/Files/npt.mdp
gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
sleep 1
gmx mdrun -deffnm npt -ntmpi 1 -pin on -nb gpu
gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr
# gmx_mpi energy -f npt.edr -o pressure.xvg
# gmx_mpi energy -f npt.edr -o density.xvg
wget http://www.mdtutorials.com/gmx/lysozyme/Files/md.mdp
echo gmx mdrun -deffnm md_0_1 -ntmpi 1 -pin on -nb gpu
