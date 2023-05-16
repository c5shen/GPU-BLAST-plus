export LD_LIBRARY_PATH=<redacted path>/vmshare/gblastn-1.2/c++/GCC700-ReleaseMT64/lib
/opt/nvidia/nsight-compute/2023.1.1/ncu \
--set full \
--import-source yes \
--source-folders <redacted path>/vmshare/gblastn-1.2/c++/src,<redacted path>/vmshare/gblastn-1.2/c++/src/algo/blast/gpu_blast \
-o <redacted path>/vmshare/gblastn-1.2/results/Debug/profilerinfo \
<redacted path>/vmshare/gblastn-1.2/c++/GCC700-ReleaseMT64/bin/blastn \
-db "aggregated_database.fna" \
-query "queries.fasta" \
-dust no \
-task blastn \
-outfmt "7 delim=, qacc sacc evalue bitscore qcovus pident" \
-max_target_seqs 5 \
-use_gpu true \
-out <redacted path>/vmshare/gblastn-1.2/results/Debug/gpuresults_withgpu.txt
