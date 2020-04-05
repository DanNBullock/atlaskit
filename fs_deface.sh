#!/bin/bash
# Deface all identifiable structural images in a Freesurfer 6 subject directory
#
# AUTHOR : Mike Tyszka, Ph.D.
# PLACE  : Caltech
# DATES  : 2020-04-01 JMT From scratch
#
# Full list of mgz images generated by FS 6 recon-all in <subj_dir>/mri
#
# Identifiable and in the same space
# ----
# T1.mgz
# nu.mgz
# orig.mgz
# orig_nu.mgz
# rawavg.mgz
#
# Identifiable and in separate spaces
# orig/*.mgz
#
# Deidentified
# ----
# aparc+aseg.mgz
# aparc.DKTatlas+aseg.mgz
# aparc.a2009s+aseg.mgz
# aseg.auto.mgz
# aseg.auto_noCCseg.mgz
# aseg.mgz
# aseg.presurf.hypos.mgz
# aseg.presurf.mgz
# brain.finalsurfs.mgz
# brain.mgz
# brainmask.auto.mgz
# brainmask.mgz
# ctrl_pts.mgz
# filled.mgz
# lh.ribbon.mgz
# norm.mgz
# rh.ribbon.mgz
# ribbon.mgz
# wm.asegedit.mgz
# wm.mgz
# wm.seg.mgz
# wmparc.mgz

# Root FS subjects directory to be defaced
root_dir=${HOME}/Data/sandbox
# root_dir=$(SUBJECTS_DIR}

echo ""
echo "----"
echo "Deface Freesurfer recon data in ${root_dir}"
echo "----"

for subj_dir in ${root_dir}/sub-*
do

  subj_id=$(basename ${subj_dir})

  echo ""
  echo "Defacing all images for ${subj_id}"

  # All identifiable images are in <subj_dir>/mri
  mri_dir=${subj_dir}/mri

  # Key filenames
  mgz_fname=${mri_dir}/T1.mgz
  nii_fname=${mgz_fname/.mgz/.nii.gz}
  bak_fname=${mgz_fname/.mgz/.mgz.bak}
  def_fname=${mgz_fname/.mgz/_defaced.nii.gz}
  dmask_fname=${mri_dir}/T1_deface_mask.nii.gz
  dmask_mgz=${dmask_fname/.nii.gz/.mgz}

  # Backup original T1.mgz to T1.mgz.bak
  echo ""
  echo "Backing up $(basename ${mgz_fname}) to $(basename ${bak_fname})"
  cp ${mgz_fname} ${bak_fname}

  # Use T1.mgz to generate the defacing mask
  echo ""
  echo "Defacing $(basename ${mgz_fname})"
  mri_convert ${mgz_fname} ${nii_fname} > /dev/null
  pydeface.py -i ${nii_fname} -om ${dmask_fname} --overwrite
  mri_convert ${def_fname} ${mgz_fname} > /dev/null

  # Save deface mask in mgz format
  echo ""
  echo "Saving $(basename ${dmask_fname}) as $(basename ${dmask_mgz})"
  mri_convert ${dmask_fname} ${dmask_fname/.nii.gz/.mgz} > /dev/null

  # Convert everything that needs defacing to nii.gz
  for stub in nu orig orig_nu
  do

    echo ""

    # Key filenames
    mgz_fname=${mri_dir}/${stub}.mgz
    nii_fname=${mgz_fname/.mgz/.nii.gz}
    bak_fname=${mgz_fname/.mgz/.mgz.bak}
    def_fname=${mgz_fname/.mgz/_defaced.nii.gz}

    # Backup original image
    echo "Backing up $(basename ${mgz_fname}) to $(basename ${bak_fname})"
    cp ${mgz_fname} ${bak_fname}

    # Deface image using T1.mgz deface mask
    if [ -s ${dmask_fname} ]
    then
      echo "Defacing $(basename ${mgz_fname}) using $(basename ${dmask_fname})"
      mri_convert ${mgz_fname} ${nii_fname} > /dev/null
      pydeface.py -i ${nii_fname} -im ${dmask_fname} --overwrite
      mri_convert ${def_fname} ${mgz_fname} > /dev/null
    else
      echo "Could not find ${dmask_fname} - exiting"
    fi

  done

  # Deface rawavg and everything in the mri/orig directory independently
  for mgz_fname in ${mri_dir}/rawavg.mgz ${mri_dir}/orig/*.mgz
  do

    echo ""

    # Key filenames
    nii_fname=${mgz_fname/.mgz/.nii.gz}
    bak_fname=${mgz_fname/.mgz/.mgz.bak}
    def_fname=${mgz_fname/.mgz/_defaced.nii.gz}
  
    # Backup original image
    echo "Backing up $(basename ${mgz_fname}) to $(basename ${bak_fname})"
    cp ${mgz_fname} ${bak_fname}

    # Deface this image
    echo "Defacing $(basename ${mgz_fname}) using $(basename ${dmask_fname})"
    mri_convert ${mgz_fname} ${nii_fname} > /dev/null
    pydeface.py -i ${nii_fname} --overwrite
    mri_convert ${def_fname} ${mgz_fname} > /dev/null
  
  done

  # Clean up .nii.gz files
  echo "Cleaning up"
  rm ${mri_dir}/*.nii.gz ${mri_dir}/orig/*.nii.gz

done
