
#!/bin/bash

#
#
# Convert the results from freesurfer into the same space as the cropped npy images to get valueable region ids for the heatmaps with
#

FS_SUBJECTS_DIR="${HOME}/freesurfer/subjects"
OUTPUT_DIR="/mnt/bulk-mars/paulkuntke/RadBrainDL_msp/fs_results/"

mkdir -p $OUTPUT_DIR

subjects_file="../top20_worst_progressor_2ycutoff_pst_2z_flair.csv"




while IFS= read -r subject_id; do
  echo "Processing subject: $subject_id"

  # Create subjects outputdir
  mkdir -p "${OUTPUT_DIR}/sub-${subject_id}"

  for labelfile in "aparc.a2009s+aseg" "aseg.auto" "aseg.presurf" "brainmask.auto" "T1" "T2" "wm.asegedit" "wm" "wmparc"
  do
      ./mri_convert "${FS_SUBJECTS_DIR}/${subject_id}/mri/${labelfile}.mgz"  "${OUTPUT_DIR}/sub-${subject_id}/sub-${subject_id}_${labelfile}.nii.gz"
      fslreorient2std  "${OUTPUT_DIR}/sub-${subject_id}/sub-${subject_id}_${labelfile}.nii.gz"  "${OUTPUT_DIR}/sub-${subject_id}/sub-${subject_id}_${labelfile}.nii.gz"
      python label2npyspace.py "${OUTPUT_DIR}/sub-${subject_id}/sub-${subject_id}_${labelfile}.nii.gz" "${OUTPUT_DIR}/sub-${subject_id}/sub-${subject_id}_space-numpy_${labelfile}.nii.gz"


  done

done < "$subjects_file"


# ./mri_convert
