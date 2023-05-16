import argparse
import os
import subprocess

# Get current time
parser = argparse.ArgumentParser()
parser.add_argument("--basedir")
parser.add_argument("--tstr")
args = parser.parse_args()
basedir = args.basedir
tstr = args.tstr

dbdir = f"{basedir}/blastdb"
outdir = f"{basedir}/results/{tstr}"
soutpath = f"{outdir}/stdout.txt"
serrpath = f"{outdir}/stderr.txt"
libpath = f"{basedir}/c++/GCC700-ReleaseMT64/lib"
# Create output file
os.mkdir(outdir)
# Run code for GPU, with timeout of 5s
os.chdir(dbdir)

try:
    os.environ['LD_LIBRARY_PATH'] = libpath
    with open(serrpath, "+w") as f:
        f.write(f"running from {basedir}/c++/GCC700-ReleaseMT64/bin/blastn\n")
    init = subprocess.run(
        [f"{basedir}/c++/GCC700-ReleaseMT64/bin/blastn",
            "-h"], capture_output=True, timeout=5)
    with open(serrpath, "+a") as f:
        f.write(init.stdout.decode())
        f.write(init.stderr.decode())

    proc = subprocess.run(
        [f"{basedir}/c++/GCC700-ReleaseMT64/bin/blastn", 
         "-db", "aggregated_database.fna", 
         "-query", "queries.fasta", 
         "-dust", "no", 
         "-task", "blastn", 
         "-outfmt", "7 delim=, qacc sacc evalue bitscore qcovus pident", 
         "-max_target_seqs", "5", 
         "-use_gpu", "true",
         "-out", f"{outdir}/gpuresults.txt"], capture_output=True, timeout=5)
    print(f"gblastn generates return code of {proc.returncode}")
    with open(soutpath, "+w") as f:
        f.write(proc.stdout.decode())
    #if proc.returncode != 0:
    with open(serrpath, "+a") as f:
        f.write(proc.stderr.decode())
    # move .log file to output directory
    if os.path.exists(f"{dbdir}/16S_query.fa.log"):
        proc = subprocess.run(["mv", f"{dbdir}/16S_query.fa.log",
                f"{outdir}/"], capture_output=True, timeout=5)
    elif os.path.exists(f"{dbdir}/queries.fasta.log"):
        proc = subprocess.run(["mv", f"{dbdir}/queries.fasta.log",
                f"{outdir}/"], capture_output=True, timeout=5)
    
except subprocess.TimeoutExpired:
    print(f"testscript_gpu.sh timed out after 5s!")
