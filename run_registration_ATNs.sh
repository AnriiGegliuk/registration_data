#!/bin/bash


stepSizes=("0.1" "0.2") 
gradientSmoothings=("2" "3") 
transformTypes=("Rigid" "Affine" "SyN")
metricTypes=("MI" "CC") 
metricParameters=("1,32,Regular,0.25" "1,4")


baseDir=$(pwd)

# i want to get a log for time each command took
timeLog="${baseDir}/time_log.txt"
echo "Registration Time Log" > "$timeLog"

# Loop through the parameter sets
for stepSize in "${stepSizes[@]}"; do
    for gradientSmoothing in "${gradientSmoothings[@]}"; do
        for transformType in "${transformTypes[@]}"; do
            for metricType in "${metricTypes[@]}"; do
                for metricParameter in "${metricParameters[@]}"; do
                    # creaing a  folder for each combination
                    folderName="Reg_${stepSize}_${gradientSmoothing}_${transformType}_${metricType}_${metricParameter//,/}"
                    mkdir -p "$baseDir/$folderName"
                    cd "$baseDir/$folderName"

                    # just a message to see when it will start
                    echo "Starting registration for $folderName"

                    # running command + added time to track start and end
                    (startTime=$(date +%s)
                    antsRegistration --dimensionality 3 \
                                     --float 0 \
                                     --output "[${folderName}_,${folderName}_Warped.nii,${folderName}_InverseWarped.nii]" \
                                     --interpolation Linear \
                                     --winsorize-image-intensities [0.005,0.995] \
                                     --use-histogram-matching 1 \
                                     --initial-moving-transform "[${baseDir}/rT2_masked_resize.nii,${baseDir}/T2_Template_resize.nii,1]" \
                                     --transform "${transformType}[${stepSize}]" \
                                     --metric "${metricType}[${baseDir}/rT2_masked_resize.nii,${baseDir}/T2_Template_resize.nii,${metricParameter}]" \
                                     --convergence "[1000x500x250x100,1e-6,10]" \
                                     --shrink-factors 8x4x2x1 \
                                     --smoothing-sigmas 3x2x1x0vox \
                                     > "${folderName}_antsH.log" 2>&1
                    endTime=$(date +%s)
                    elapsedTime=$((endTime - startTime))
                    echo "Elapsed time for $folderName: $elapsedTime seconds." | tee -a "$timeLog")

                    # after each itteration code need to go back to basedir
                    cd "$baseDir"
                done
            done
        done
    done
done

# just to see when it stops executing
echo "All registrations completed."

