#!/usr/bin/env bash
# @AUTHOR: Chun-Jie Liu
# @CONTACT: chunjie.sam.liu.at.gmail.com
# @DATE: 2022-07-27 14:37:49
# @DESCRIPTION:

# Number of input parameters

# download QC output file
# bucket="fc-secure-f4731dee-c700-4b23-9cd7-119292a806f1"
# sbid="3927dd42-bae5-48ec-af21-8f67b7dd1f6c"
# outdir="/home/liuc9/github/qc-wdl/data"

# gzfiles=$(gsutil ls gs://${bucket}/${sbid}/QC/*/call-gatherbam/*.tar.gz)
# for gz in ${gzfiles}
# do
#   bname=$(basename ${gz})
#   [[ -f ${outdir}/${bname} ]] && echo "${bname} already exists!" && continue
#   # echo ${gz}
#   cmd="gsutil cp ${gz} ${outdir}/${bname}"
#   echo ${cmd}
#   eval ${cmd}
# done


## Download samtools idxstats file.
bucket="fc-secure-d02ae31a-ab6d-4003-9904-3f5a1a03453c"
submissionid="332b5f2a-0acf-425f-86fa-5c1fd56638a8"
outdir="/home/liuc9/scratch/mitochondrial/GTExv8-reads-ratio/GTExv8-idxstats"

gzfiles=$(gsutil ls gs://${bucket}/submissions/${submissionid}/IDXSTATS/*/call-gather_idxstats/*.tar.gz)
for gz in ${gzfiles}
do
    bname=$(basename ${gz})
    [[ -f ${outdir}/${bname} ]] && echo "${bname} already exists!" && continue
    cmd="gsutil cp ${gz} ${outdir}/${bname}"
    echo ${cmd}
    eval ${cmd}
done