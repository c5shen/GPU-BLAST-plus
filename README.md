# GPU-BLAST-plus
A class project for CS508 from UIUC to implement the classic BLAST algorithm using different GPU computing techniques. 

_**Members**: Chengze Shen, Kaining Zhou, Zhuxuan Liu, Zutai Chen_


# Original BLASTN algorithm for mapping sequences to a database (of sequences)
* The download link to the most recent BLAST (v2.13.0) packages: <https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/>

1. For each input unmapped sequence, represent it with consecutive words of length `W`.
2. The matched positions are referred to as _hits_.
3. _Hits_ are extended to ungapped alignments, allowing for mismatches. 
4. Ungapped extensions that pass a certain threshold score are passed to gapped alignments.
5. Gapped alignments that pass a certain threshold score are saved as "preliminary results".
6. Preliminary matches are considered for ambiguities (e.g., ambiguous nucleotides) and indel locations.
7. Results are then reported back to users.

# Current reference for how to do the project
* G-BLASTN by Kaiyong Zhao and Xiaowen Chu. [link to software](http://www.comp.hkbu.edu.hk/~chxw/software/G-BLASTN.html).
  * at the time of publication, G-BLASTN compared to BLAST v2.2.28. In our analysis we will run the G-BLASTN and our implementation and compare to the latest BLAST version (v2.13.0).


# Main idea for speedup
* Scanning stage of G-BLASTN --> broken into two sub-steps, (1) "scan" and (2) "lookup" .
  * "scan" goes over each database sequence in parallel and records offsets in the sequence that have >= 1 matches to a query.
  * "lookup" is another kernel that re-checks all matched offsets and obtain the corresponding matched offset pairs (of database and query sequences).
  * **MERITS**: 
    1. Having 2 sub-steps (kernels) greatly reduces control divergence.
    2. Using shared memory to record offsets in the "scan" sub-step. This is similar to what we did in the BFS lab (block-queuing kernel).
  * **FURTHER POSSIBLE IMPROVEMENTS**:
    1. TBD

# Benchmarks
#### Database
We will use the latest version of the Homo Sapien whole genome assembly available on NCBI.
  * The one used in G-BLASTN is an older version (__NCBI36, #accession GCF_000001405.12__).
  * The new one we will use is an aggregated database including five genomes (human, mouse, cat, dog, and gorilla):
      - Human: __#accession GCF_000001405.40__.
      - Mouse: __#accession GCF_000001635.27__.
      - Cat: __#accession GCF_018350175.1__.
      - Dog: __#accession GCF_000002285.5__.
      - Gorilla: __#accession GCF_029281585.1__.
  * The combined database can be found at [here](https://drive.google.com/file/d/1as5-0ARcdEcUWDxSnolhyWm6a4CoMlTZ/view?usp=sharing).
  * To create the database (blast database version 4) locally using `makeblastdb`, run the following command:
```
makeblastdb -in [path/to/fasta] -parse_seqids -blastdb_version 4 -title "homo_sapien_grch38" -dbtype nucl
```
  * To use the created database when running `blastn` or `gblastn`, input the db as follows (assuming the database has been created under the same directory as the fasta file):
```
blastn -db <path/to/fasta> ... [other parameters]
OR
gblastn -db <path/to/fasta> ... [other parameters]
```

#### Query sequences
We will use the same set of query sequences used in G-BLASTN to search against the target database mentioned above.
  * The queries are the first 500 bacterial sequences of the study SRX338063 from the NCBI server at <http://www.ncbi.nlm.nih.gov/sra/SRX338063>.
  * The queries are made available in `data/queries.fasta`.

#### Running BLASTN
##### (<span style="color:red">*IMPORTANT*</span>) Compiling BLAST-2.2.28+ (for G-BLASTN to work):
NCBI BLAST+ is a mess for newer compiler and linux system to compile. Although its binaries generally work, it is quite hard to compile the codes locally.
To compile `ncbi-blast-2.2.28+-src` successfully, some files need to change (see files in **to_change.tar.gz**).

After decompressing files from **to_change.tar.gz**, there will be two folders:
*. `to_change/include/`
*. `to_change/your-configured-folder/`

Assume you already downloaded and decompressed the source codes of BLAST+ and you are in the directory `ncbi-blast-2.2.28+-src/c++`, and you have run `./configure` already, do the following steps:
1. Copy and overwrite files (remember to make backups) in `to_change/include` to the corresponding directories in `ncbi-lbast-2.2.28+-src/c++/include`.
2. Change line 4749 of "c++/src/build-system/configure" script, add "7" or "7.*" to support GC 7.0.0 or 7+.
2. After running `./configure`, you should have generated a folder under `ncbi-blast-2.2.28+-src/c++`, for example, `ncbi-blast-2.2.28+-src/c++/GCC750-Debug64` depending on your system and compiler version.
   * Copy `to_change/your-configured-folder/build/Makefile.lib` and overwite (make a backup) the corresponding `ncbi-blast-2.2.28+-src/c++/your-configured-folder/build/Makefile.lib`.
3. Now, try running `make` or `make -j` (using all available cores for compiling) and hope everything works.
4. If step 3 works without errors, you should have successfully compiled binaries in directory `ncbi-blast-2.2.28+-src/c++/your-configured-folder/bin`. Then, you can install g-blastn by using this path.

##### (<span style="color:red">*IMPORTANT*</span>) (Cont.) Compiling G-BLASTN:
1. To simplify the process, all files used to compile G-BLASTN on Chengze's environment is uploaded to <https://drive.google.com/file/d/1ecGFSnw80KM6_ofPhCZx-XhdFCR00oMu/view?usp=share_link>. The compiled file has BLASTN compiled already, so a new user should probably remove the entire `ncbi-blast-2.2.28+-src/` folder and follow the steps above to rebuild BLASTN.
2. After getting the correctly compiled BLASTN, the user can try to compile G-BLASTN using either `./install` or `./install.noask`, for which the user needs to change the `LINE 50: installed_dir=` to the BLASTN `bin/` folder.
2.2 Additionally, the user needs to change one additional file at `c++/src/algo/blast/gpu_blast/makefile`. G-BLASTN requires the header files from `~/NVIDIA_CUDA-{version}_Samples/common/inc` to work, so please change `LINE 18: COMMON_DIR :=` to the correct path.
3. If everything is done correctly, you should be able to compile G-BLASTN, but might face issues running it on test dataset (I am struggling too).

**CURRENT ISSUES**
Although BLAST+ can compile now (with the instructions above), compilation for GPU codes still have issues that have not been resolved, which Chengze Shen is currently working on.

##### Run BLASTN
To run `blastn` with a given database and a given set of query sequences (without WindowMasker and DUST):
```
blastn -db <database> -query <query> -task blastn -outfmt 7 -out <file> \
        -num_threads <1|4|8>
```
To run `gblastn` similarly:
```
gblastn -db <database> -query <query> -task blastn -outfmt 7 -out <file> \
        -use_gpu true -mode <1|2> -num_threads <1|4|8>
```

# Task division
## 4.13.2023 - 4.20.2023
1. Chengze Shen - improvement of G-BLASTN, mainly on warp-queuing for the seeding step.
2. Kaining Zhou - 
2. Zhuxuan Liu - 
3. Zutai Chen - 
