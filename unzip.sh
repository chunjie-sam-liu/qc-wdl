#!/usr/bin/env bash
# @AUTHOR: Chun-Jie Liu
# @CONTACT: chunjie.sam.liu.at.gmail.com
# @DATE: 2022-07-27 15:23:14
# @DESCRIPTION:

# Number of input parameters
outdir="/scr1/users/liuc9/bam-qc"

zips=$(find ${outdir} -name "*.md_fastqc.zip")

for zip in ${zips}
do
  bname=$(basename ${zip})
  dname=$(dirname ${zip})
  bname=${bname%.zip}
  [[ -d ${dname}/${bname} ]] && echo "${bname} already exists!" && continue
  cmd="unzip ${zip} -d ${dname}"
  echo ${cmd}
  eval ${cmd}
done
