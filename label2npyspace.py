#! /usr/bin/env python

import argparse
import logging
from os.path import basename, exists, join, splitext

import nibabel as nib
import numpy as np
import torch
import torchio as tio
from rich.logging import RichHandler

# from rich.progress import BarColumn, Progness, TextColumn, TimeRemainingColumn, track

FORMAT = "%(message)s"
logging.basicConfig(
    level="NOTSET", format=FORMAT, datefmt="[%X]", handlers=[RichHandler()]
)

log = logging.getLogger("rich")


def resize_image(input_file, output_file, size=96, crop=180, affine=None):
    log.debug(f"resizing {input_file} to size {size} and cropping {crop}")
    # Build a transformation pipeline:
    #   1. Resample to isotropic 1mm voxels
    #   2. Crop or pad to a cubic volume of side `crop`
    #   3. Resize isotropically to the desired `size`
    # The resulting image from TorchIO is a LabelMap with a singleton
    # channel dimension (shape: 1 × D × H × W).  To obtain a true 3‑D volume we
    # manually squeeze that dimension before saving.
    transforms = tio.Compose(
        [
            tio.Resample((1, 1, 1)),
            tio.CropOrPad((crop, crop, crop)),
            tio.Resize(
                (size, size, size),
                label_interpolation="nearest",
                image_interpolation="nearest",
            ),
        ]
    )
    image = tio.LabelMap(input_file)
    transformed_image = transforms(image)
    # Remove the leading singleton channel dimension
    data = transformed_image.data.squeeze()
    if affine is None:
        affine = np.eye(4)
    # Convert the (torch) tensor to a NumPy array and save with nibabel
    np_data = data.numpy() if hasattr(data, "numpy") else np.array(data)
    nii_img = nib.Nifti1Image(np_data, affine)
    nib.save(nii_img, output_file)


def main():

    parser = argparse.ArgumentParser(description="Resize and crop images")
    parser.add_argument("inputfile", type=str, help="input nifti file")
    parser.add_argument("outputfile", type=str, help="output filename")
    parser.add_argument(
        "--size", type=int, default=96, help="size of outputimage (isotropic)"
    )
    parser.add_argument(
        "--crop", type=int, default=180, help="cropping size, applied before resizing"
    )

    args = parser.parse_args()
    resize_image(args.inputfile, args.outputfile, size=args.size, crop=args.crop)


if __name__ == "__main__":
    main()
