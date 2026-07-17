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
    transformed_image.save(output_file)
    if affine is None:
        affine = np.eye(4)

    # nib_img = nib.Nifti1Image(data, affine=affine)
    # nib.save(nib_img, output_file)


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
