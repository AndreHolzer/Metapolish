#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>log.txt 2>&1
Rscript ./scripts/Metaploish_main-anaylsis-script.R 
