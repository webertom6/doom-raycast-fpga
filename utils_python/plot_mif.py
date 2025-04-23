import matplotlib.pyplot as plt
import numpy as np
import re
import argparse

def bin12_to_rgb888(bin_str):
    """Convert 12-bit RGB444 binary string to 8-bit RGB888 tuple."""
    value = int(bin_str, 2)
    r = ((value >> 8) & 0xF) * 17
    g = ((value >> 4) & 0xF) * 17
    b = (value & 0xF) * 17
    return (r, g, b)

def hex12_to_rgb888(hex_str):
    """Convert 12-bit RGB444 hex string to 8-bit RGB888 tuple."""
    value = int(hex_str, 16)
    r = ((value >> 8) & 0xF) * 17
    g = ((value >> 4) & 0xF) * 17
    b = (value & 0xF) * 17
    return (r, g, b)

def read_mif_and_plot(mif_path, width=16, height=16):
    with open(mif_path, 'r') as f:
        lines = f.readlines()

    address_radix = None
    data_radix = None
    data = []

    # Parse header and content
    for line in lines:
        line = line.strip()
        if line.startswith("ADDRESS_RADIX"):
            address_radix = re.search(r'ADDRESS_RADIX=(\w+);', line).group(1)
        elif line.startswith("DATA_RADIX"):
            data_radix = re.search(r'DATA_RADIX=(\w+);', line).group(1)
        elif re.match(r'^\w+\s*:\s*\w+\s*;', line):  # Match content lines
            match = re.match(r'(\w+)\s*:\s*(\w+)\s*;', line)
            if match:
                address, value = match.groups()
                data.append(value)

    if address_radix not in {"HEX", "DEC"} or data_radix not in {"BIN", "HEX"}:
        raise ValueError("Unsupported ADDRESS_RADIX or DATA_RADIX in .mif file")

    if len(data) != width * height:
        raise ValueError(f"Expected {width*height} pixels, but got {len(data)} from the .mif")

    # Convert and reshape to image
    if data_radix == "BIN":
        rgb_pixels = [bin12_to_rgb888(b) for b in data]
    elif data_radix == "HEX":
        rgb_pixels = [hex12_to_rgb888(b) for b in data]

    img = np.array(rgb_pixels, dtype=np.uint8).reshape((height, width, 3))

    # Plot
    plt.imshow(img)
    plt.title("Image Reconstructed from .mif")
    plt.axis("off")
    plt.show()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Read .mif and plot reconstructed image.")
    parser.add_argument("mif_file", help="Path to the .mif file")
    parser.add_argument("--width", type=int, default=16, help="Image width")
    parser.add_argument("--height", type=int, default=16, help="Image height")
    args = parser.parse_args()

    read_mif_and_plot(args.mif_file, args.width, args.height)
