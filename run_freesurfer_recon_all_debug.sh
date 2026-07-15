#!/bin/bash

# Debug script to run FreeSurfer recon-all for subjects in CSV file
# This version includes extensive debugging to help locate NIfTI files

# Configuration
CSV_FILE="top20_worst_progressor_2ycutoff_wst_2z_flair.csv"
# IMAGE_BASE_PATH="/mnt/radbrain_dl/explainability/worst_progressor_2ycutoff_pst_2z/mspaths2/t1w/sfcn/saliency/magnitude/worst_progressor_2ycutoff_pst_2z_e1000_b16_im96"
IMAGE_BASE_PATH="/mnt/mspaths_bids/derivatives/reg_to_mni_affine/"
FREESURFER_IMAGE="freesurfer/freesurfer:7.4.1"
SUBJECTS_DIR="${HOME}/freesurfer/subjects"

# Create subjects directory
mkdir -p "$SUBJECTS_DIR"

echo "=== DEBUG FreeSurfer Recon-all Processing ==="
echo "CSV File: $CSV_FILE"
echo "Image Base Path: $IMAGE_BASE_PATH"
echo "Subjects Directory: $SUBJECTS_DIR"
echo ""

# Check if CSV file exists
if [ ! -f "$CSV_FILE" ]; then
    echo "ERROR: CSV file $CSV_FILE not found!"
    echo "Current directory contents:"
    ls -la
    exit 1
fi



echo ""


# Process each subject in the CSV
line_count=0
for subject_id in `cat ${CSV_FILE}`; do

    echo "=== running for id ${subject_id} ===="

    # Trim whitespace

    if [ -n "$subject_id" ]; then
        echo "=== Processing subject: $subject_id ==="
        echo "Line number: $line_count"


        # Try multiple approaches to find the file
        T1_IMAGE_FILE="${IMAGE_BASE_PATH}/sub-${subject_id}/ses-001/anat/sub-${subject_id}_ses-001_space-MNI152_T1w.nii.gz"
        FLAIR_IMAGE_FILE="${IMAGE_BASE_PATH}/sub-${subject_id}/ses-001/anat/sub-${subject_id}_ses-001_space-MNI152_FLAIR.nii.gz"

        # If we found a file, proceed with processing
        if [ -n "$T1_IMAGE_FILE" ] && [ -r "$T1_IMAGE_FILE" ]; then
            echo "Final found image file: $T1_IMAGE_FILE"

            # Create subject-specific directory
            SUBJECT_DIR="${SUBJECTS_DIR}/"
            mkdir -p "$SUBJECT_DIR"

            echo "Subject directory: $SUBJECT_DIR"

            # Run recon-all in Podman container
            echo "Running recon-all for subject $subject_id..."
            echo "Command: podman run --rm -v \"$IMAGE_FILE:/input.nii.gz\" -v \"$SUBJECT_DIR:/subjects\" \"$FREESURFER_IMAGE\" -v \"${HOME}/freesurfer:/fs\" -e $FS_LICENSE=/fs/freesurfer_license.txt recon-all -all -i /input.nii.gz -s \"$subject_id\" -sd /subjects"

            echo "input file: $IMAGE_FILE"

            # Execute the command
            podman run -ti --gpus=all \
                -v "$T1_IMAGE_FILE:/t1w_input.nii.gz" \
                -v "$FLAIR_IMAGE_FILE:/flair_input.nii.gz" \
                -v "${HOME}/freesurfer/subjects:/usr/local/freesurfer/subjects" \
                -v "${HOME}/freesurfer:/fs" -e FS_LICENSE=/fs/freesurfer_license.txt \
                "$FREESURFER_IMAGE" \
                recon-all -all  -subject "$subject_id" -i /t1w_input.nii.gz -T2 /flair_input.nii.gz -openmp 10 -threads 10

            if [ $? -eq 0 ]; then
                echo "✓ Successfully processed subject $subject_id"
            else
                echo "✗ Error processing subject $subject_id"
            fi
        else
            echo "Warning: Skipping subject $subject_id - no suitable image file found"
            echo "Searched in: $IMAGE_BASE_PATH"
            echo "Expected pattern: $SEARCH_PATTERN"
        fi
    fi
done < "$CSV_FILE"

echo ""
echo "=== Processing Completed ==="
echo "Results saved in: $SUBJECTS_DIR"
echo "Check the debug output above to see if files were found properly."
