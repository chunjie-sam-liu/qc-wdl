#!/usr/bin/env bash
# @AUTHOR: Chun-Jie Liu
# @CONTACT: chunjie.sam.liu.at.gmail.com
# @DATE: 2022-07-27 15:17:45
# @DESCRIPTION:

# Number of input parameters
outdir="/scr1/users/liuc9/bam-qc"

targz=$(ls ${outdir}/*.tar.gz)

for tar in ${targz}
do
  bname=$(basename ${tar})
  bname=${bname%.tar.gz}
  # echo ${outdir}/${bname}
  [[ -d ${outdir}/${bname} ]] && echo "${bname} already exists!" && continue
  # echo ${gz}
  cmd="tar -xzvf ${tar} -C ${outdir}"
  echo ${cmd}
  eval ${cmd}
done