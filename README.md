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

# benchmark datasets
#### Database
We will use the latest version of the Homo Sapien whole genome assembly available on NCBI.
  * The one used in G-BLASTN is an older version (__NCBI36, #accession GCF_000001405.12__).
  * The new one we will use is __GRCh38.p14, #accession GCF_000001405.40__.
  * The new one is available from <https://www.ncbi.nlm.nih.gov/data-hub/genome/GCF_000001405.40/>.
#### Query sequences
We will use the same set of query sequences used in G-BLASTN to search against the target database mentioned above.
  * The queries are the first 500 bacterial sequences of the study SRX338063 from the NCBI server at <http://www.ncbi.nlm.nih.gov/sra/SRX338063>.

# Task division
## 4.13.2023 - 4.20.2023
1. Chengze Shen - improvement of G-BLASTN, mainly on warp-queuing for the seeding step.
2. Kaining Zhou - 
2. Zhuxuan Liu - 
3. Zutai Chen - 
