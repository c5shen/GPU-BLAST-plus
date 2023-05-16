CURDIR=$(pwd)
GBLASTBINDIR="$CURDIR/../c++/GCC700-ReleaseMT64/build/algo/blast/gpu_blast"
echo "recompile_gblastn.sh: GBLASTBINDIR: $GBLASTBINDIR"
cd $GBLASTBINDIR
echo "cd to $(pwd)"
touch empty.o #Ensures the make clean will not fail
touch empty.a #Ensures the make clean will not fail
make clean
BLASTBIN="$CURDIR/../c++/GCC700-ReleaseMT64/build/app/blast/blastn"
echo "Removing blast binary file at $BLASTBIN to ensure a new one is made"
rm $BLASTBIN
MAKEDIR="$CURDIR/../c++"
echo "recompile_gblastn.sh: MAKEDIR: $MAKEDIR"
cd $MAKEDIR
echo "cd to $(pwd)"
make
