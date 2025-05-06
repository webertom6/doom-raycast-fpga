from PIL import Image
import argparse

# def rgb_to_12bit_bin(r, g, b):
#     """Convert 8-bit RGB to a 12-bit RGB string in binary."""
#     r4 = (r >> 4) & 0xF
#     g4 = (g >> 4) & 0xF
#     b4 = (b >> 4) & 0xF
#     value = (r4 << 8) | (g4 << 4) | b4
#     return f"{value:012b}"

def rgb_to_12bit_bin(r, g, b):
    """Convert 8-bit RGB to a 12-bit RGB string in binary."""
    r4 = (r & 0xF0) >> 4  # Extract the upper 4 bits of red
    g4 = (g & 0xF0) >> 4  # Extract the upper 4 bits of green
    b4 = (b & 0xF0) >> 4  # Extract the upper 4 bits of blue
    
    r4 = int(f"{r4:04b}"[::-1], 2)
    g4 = int(f"{g4:04b}"[::-1], 2)
    b4 = int(f"{b4:04b}"[::-1], 2)
    value = (r4 << 8) | (g4 << 4) | b4  # Combine into 12-bit value
    return f"{value:012b}"

def rgb_to_12bit(r, g, b):
    # Downscale 8-bit to 4-bit
    r4 = (r * 15) // 255
    g4 = (g * 15) // 255
    b4 = (b * 15) // 255

    # Pack into 12-bit value: [RRRR][GGGG][BBBB]
    rgb_12bit = (r4 << 8) | (g4 << 4) | b4
    
    return f"{rgb_12bit:012b}"

def rgb_to_12bit_hex(r, g, b):
    """Convert 8-bit RGB to a 12-bit RGB string in hexadecimal."""
    r4 = (r & 0xF0) >> 4  # Extract the upper 4 bits of red
    g4 = (g & 0xF0) >> 4  # Extract the upper 4 bits of green
    b4 = (b & 0xF0) >> 4  # Extract the upper 4 bits of blue
    value = (r4 << 8) | (g4 << 4) | b4  # Combine into 12-bit value
    return f"{value:03X}"

def convert_image_to_mif(image_path, mif_path, width=16, height=16, address_radix="DEC", data_radix="BIN", grayscale=False):
    img = Image.open(image_path).convert("L" if grayscale else "RGB").resize((width, height))
    pixels = list(img.getdata())

    depth = width * height
    width_bits = 1 if grayscale else 12  # 1 bit for grayscale, 12 bits for RGB
    mif_lines = [
        f"WIDTH={width_bits};",
        f"DEPTH={depth};",
        "",
        f"ADDRESS_RADIX={address_radix};",
        f"DATA_RADIX={data_radix};",
        "",
        "CONTENT BEGIN"
    ]

    for addr in range(depth):
        if addr < len(pixels):
            if grayscale:
                # Convert grayscale pixel to 1-bit (threshold at 128)
                gray_value = 1 if pixels[addr] >= 128 else 0
                data = f"{gray_value:01b}" if data_radix == "BIN" else f"{gray_value:X}"
            else:
                r, g, b = pixels[addr]
                if data_radix == "BIN":
                    data = rgb_to_12bit_bin(r, g, b)
                elif data_radix == "HEX":
                    data = rgb_to_12bit_hex(r, g, b)


        else:
            data = "0" if grayscale else ("000000000000" if data_radix == "BIN" else "000")

        if address_radix == "DEC":
            mif_lines.append(f"    {addr:4d} : {data};")
        elif address_radix == "HEX":
            mif_lines.append(f"    {addr:04X} : {data};")

    mif_lines.append("END;")

    with open(mif_path, "w") as f:
        f.write("\n".join(mif_lines))

    print(f"[✓] MIF file saved to: {mif_path}")

# example usage:
# python png_to_mif.py input.png output.mif --width 16 --height 16 --address_radix DEC --data_radix BIN --grayscale
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert image to .mif file with 12-bit RGB or 1-bit grayscale values.")
    parser.add_argument("image", help="Input image file (.png or .jpg)")
    parser.add_argument("output", help="Output .mif file")
    parser.add_argument("--width", type=int, default=16, help="Target image width")
    parser.add_argument("--height", type=int, default=16, help="Target image height")
    parser.add_argument("--address_radix", choices=["DEC", "HEX"], default="DEC", help="Address radix (DEC or HEX)")
    parser.add_argument("--data_radix", choices=["BIN", "HEX"], default="BIN", help="Data radix (BIN or HEX)")
    parser.add_argument("--grayscale", action="store_true", help="Convert image to 1-bit grayscale")

    args = parser.parse_args()
    convert_image_to_mif(args.image, args.output, args.width, args.height, args.address_radix, args.data_radix, args.grayscale)

