#!/usr/bin/env bash
# @AUTHOR: Chun-Jie Liu
# @CONTACT: chunjie.sam.liu.at.gmail.com
# @DATE: 2022-07-27 14:37:49
# @DESCRIPTION:

# Number of input parameters

bucket="fc-secure-f4731dee-c700-4b23-9cd7-119292a806f1"
sbid="3927dd42-bae5-48ec-af21-8f67b7dd1f6c"
outdir="/home/liuc9/github/qc-wdl/data"

gzfiles=$(gsutil ls gs://${bucket}/${sbid}/QC/*/call-gatherbam/*.tar.gz)
for gz in ${gzfiles}
do
  bname=$(basename ${gz})
  [[ -f ${outdir}/${bname} ]] && echo "${bname} already exists!" && continue
  # echo ${gz}
  cmd="gsutil cp ${gz} ${outdir}/${bname}"
  echo ${cmd}
  eval ${cmd}
done

