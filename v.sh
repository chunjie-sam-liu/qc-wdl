#!/usr/bin/env bash
# @AUTHOR: Chun-Jie Liu
# @CONTACT: chunjie.sam.liu.at.gmail.com
# @DATE: 2022-07-26 19:33:39
# @DESCRIPTION:

# womtool requires 52 = Java 8
# Number of input parameters
module load Java/15.0.1
java -jar /home/liuc9/tools/womtool-78.jar validate /home/liuc9/github/qc-wdl/qc.wdl

