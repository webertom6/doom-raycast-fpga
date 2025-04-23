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
    r4 = (r >> 4) & 0xF
    g4 = (g >> 4) & 0xF
    b4 = (b >> 4) & 0xF
    value = (r4 << 8) | (g4 << 4) | b4
    return f"{value:012b}"

def rgb_to_12bit_hex(r, g, b):
    """Convert 8-bit RGB to a 12-bit RGB string in hexadecimal."""
    r4 = (r >> 4) & 0xF
    g4 = (g >> 4) & 0xF
    b4 = (b >> 4) & 0xF
    value = (r4 << 8) | (g4 << 4) | b4
    return f"{value:03X}"

def convert_image_to_mif(image_path, mif_path, width=16, height=16, address_radix="DEC", data_radix="BIN"):
    img = Image.open(image_path).convert("RGB").resize((width, height))
    pixels = list(img.getdata())

    depth = width * height
    width_bits = 12  # 4 bits per R, G, B
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
            r, g, b = pixels[addr]
            if data_radix == "BIN":
                data = rgb_to_12bit_bin(r, g, b)
            elif data_radix == "HEX":
                data = rgb_to_12bit_hex(r, g, b)
        else:
            data = "000000000000" if data_radix == "BIN" else "000"

        if address_radix == "DEC":
            mif_lines.append(f"    {addr:4d} : {data};")
        elif address_radix == "HEX":
            mif_lines.append(f"    {addr:04X} : {data};")

    mif_lines.append("END;")

    with open(mif_path, "w") as f:
        f.write("\n".join(mif_lines))

    print(f"[✓] MIF file saved to: {mif_path}")

# python png_to_mif.py vga1/png_files/heart.png vga1/mif_files/heart.mif --width 36 --height 36 --address_radix HEX --data_radix BIN
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert image to .mif file with 12-bit RGB values.")
    parser.add_argument("image", help="Input image file (.png or .jpg)")
    parser.add_argument("output", help="Output .mif file")
    parser.add_argument("--width", type=int, default=16, help="Target image width")
    parser.add_argument("--height", type=int, default=16, help="Target image height")
    parser.add_argument("--address_radix", choices=["DEC", "HEX"], default="DEC", help="Address radix (DEC or HEX)")
    parser.add_argument("--data_radix", choices=["BIN", "HEX"], default="BIN", help="Data radix (BIN or HEX)")

    args = parser.parse_args()
    convert_image_to_mif(args.image, args.output, args.width, args.height, args.address_radix, args.data_radix)
