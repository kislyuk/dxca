#!/bin/bash

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

main() {
    # Download all reads
    mkdir ./reads
    n=0
    for i in "${!illumina_unpaired[@]}"; do
	let n=n+1
	mkdir ./reads/$n/
	dx download "${illumina_unpaired[$i]}" -o ./reads/$n/
	gunzip ./reads/$n/*
	fastqToCA -libraryname ILLUMINA-$n -technology illumina -reads ./reads/$n/* > `echo ./reads/$n/*`.frg
    done
    for i in "${!pacbio_ccs[@]}"; do
	let n=n+1
	mkdir ./reads/$n/
	dx download "${pacbio_ccs[$i]}" -o ./reads/$n/
	gunzip ./reads/$n/*
	fastqToCA -libraryname PACBIO-CCS-$n -technology pacbio-ccs -reads ./reads/$n/* > `echo ./reads/$n/*`.frg
    done
    for i in "${!pacbio_corrected[@]}"; do
	let n=n+1
	mkdir ./reads/$n/
	dx download "${pacbio_corrected[$i]}" -o ./reads/$n/
	gunzip ./reads/$n/*
	fastqToCA -libraryname PACBIO-CORRECTED-$n -technology pacbio-corrected -reads ./reads/$n/* > `echo ./reads/$n/*`.frg
    done
    for i in "${!pacbio_raw[@]}"; do
	let n=n+1
	mkdir ./reads/$n/
	dx download "${pacbio_raw[$i]}" -o ./reads/$n/
	gunzip ./reads/$n/*
	fastqToCA -libraryname PACBIO-RAW-$n -technology pacbio-raw -reads ./reads/$n/* > `echo ./reads/$n/*`.frg
    done

    dx upload -r reads
    process_jobs=()

    for i in {1..2}; do
	process_jobs+=($(dx-jobutil-new-job worker -i command_line='runCA $extra_opts -d ./work -p $prefix ./reads/*/*frg' -i prefix="$prefix" -i extra_opts="$extra_opts"))
    done

    postproc_job=$(dx-jobutil-new-job postprocess --depends-on "${process_jobs[@]}")
    dx-jobutil-add-output results $postproc_job:results
}

worker() {
    dx download -r reads
    echo "Will run '$command_line'"
    # dx-jobutil-add-output ...
}

postprocess() {
    echo "Postprocess running"
    mkdir -p out/results
    touch out/results/out{1..4}
    dx-upload-all-outputs
}

#for file in ./work/9-terminator/*fasta; do
#  gzip $file
#  mv $file.gz out/results
#done
