#!/bin/bash

stepSizes=("0.1" "0.2")
gradientSmoothings=("2" "3") 
transformTypes=("Rigid" "Affine" "SyN")
metricTypes=("MI" "CC")
metricParameters=("1,32,Regular,0.25" "1,4")

baseDir=$(pwd)


for stepSize in "${stepSizes[@]}"; do
  for gradientSmoothing in "${gradientSmoothings[@]}"; do
    for transformType in "${transformTypes[@]}"; do
      for metricType in "${metricTypes[@]}"; do
        for metricParameter in "${metricParameters[@]}"; do

          # folders for each params compination to apply transform after and check res
          folderName="Reg_${stepSize}_${gradientSmoothing}_${transformType}_${metricType}_${metricParameter//,/}"
          mkdir -p "$baseDir/$folderName"
          cd "$baseDir/$folderName"
          outputPrefix="${folderName}"

          # code for registration with all possible params
          antsRegistration --dimensionality 3 \
                           --float 0 \
                           --output "[${outputPrefix}_,${outputPrefix}_Warped.nii,${outputPrefix}_InverseWarped.nii]" \
                           --interpolation Linear \
                           --winsorize-image-intensities [0.005,0.995] \
                           --use-histogram-matching 1 \
                           --initial-moving-transform "[${baseDir}/rT2_masked_resize.nii,${baseDir}/T2_Template_resize.nii,1]" \
                           --transform "${transformType}[${stepSize}]" \
                           --metric "${metricType}[${baseDir}/rT2_masked_resize.nii,${baseDir}/T2_Template_resize.nii,${metricParameter}]" \
                           --convergence "[1000x500x250x100,1e-6,10]" \
                           --shrink-factors 8x4x2x1 \
                           --smoothing-sigmas 3x2x1x0vox \
                           > "${outputPrefix}_antsH.log" 2>&1
	  # copy of input files to run apply registration after	
          cp "${baseDir}/atlas_resize.nii" .
          cp "${baseDir}/rT2_masked_resize.nii" .

          cd "$baseDir" # base dir needs to be retunred for next itteration for specif params
        done
      done
    done
  done
done
