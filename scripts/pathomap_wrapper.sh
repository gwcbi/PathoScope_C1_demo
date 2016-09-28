#!/bin/bash

SN="pathomap_wrapper.sh"
echo "[---$SN---] ($(date)) Starting $SN"
t1=$(date +"%s")

umask 0002
#--- Load the pathoscope module
module load pathoscope

##########################################################################################
# Setup variables
##########################################################################################

#--- If array job, a file of file names (fofn) must be provided
if [[ -n "$SLURM_ARRAY_TASK_ID" ]]; then
    [[ -z "$fofn" ]] && echo "No fofn provided" && exit 1
    fastq=$(sed -n "$SLURM_ARRAY_TASK_ID"p $fofn)
fi

#--- If not an array job, the path for the fastq file must have been provided
[[ -z "$fastq" ]] && echo "No fastq provided" && exit 1

#--- Check that fastq file exists
[[ ! -e "$fastq" ]] && echo "[---$SN---] ($(date)) FAILED: file $fastq does not exist" && exit 1

#--- Output directory
outdir=$(basename ${fastq%.*})

#--- Path to bowtie2 databases
indexdir="references"

#--- Create lists for target and filter databases
targetnames=$(tr '\n' ',' < targets.txt | sed 's/,$//')
filternames=$(tr '\n' ',' < filter.txt | sed 's/,$//')


##########################################################################################
# Run pathoscope
##########################################################################################

#--- Print out the parameters
echo "[---$SN---] ($(date)) SETTINGS"
echo "[---$SN---] ($(date)) Fastq:             $fastq"
echo "[---$SN---] ($(date)) Output directory:  $outdir"
echo "[---$SN---] ($(date)) Index directory:   $indexdir"
echo
echo "[---$SN---] ($(date)) Target databases:"
tr ',' '\n' <<< $targetnames | sed 's/^/               /'
echo
echo "[---$SN---] ($(date)) Filter databases:"
tr ',' '\n' <<< $filternames | sed 's/^/               /'

mkdir -p $outdir

pathoscope.py MAP -numThreads $(nproc) \
    -U $fastq \
    -indexDir $indexdir \
    -targetIndexPrefixes "$targetnames" \
    -filterIndexPrefixes "$filternames" \
    -outDir $outdir \
    -numThreads $(nproc) \
    -outAlign outalign.sam

#---Complete job
t2=$(date +"%s")
diff=$(($t2-$t1))
echo "[---$SN---] Total time: ($(date)) $(($diff / 60)) minutes and $(($diff % 60)) seconds."
echo "[---$SN---] ($(date)) $SN COMPLETE."
