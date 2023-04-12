# GPU-BLAST-plus
A class project for CS508 from UIUC to implement the classic BLAST algorithm using different GPU computing techniques. 


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
