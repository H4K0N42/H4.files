import os
import shutil
import tempfile
import tomllib
from pathlib import Path
from PIL import Image
import subprocess

# Input and output directories
HYPRCURSOR_DIR = Path("/home/hagen/.icons/theme_mycur/")  # <- replace this
OUTPUT_XCUR_DIR = Path("./theme")  # <- replace this


def find_pngs(base_dir):
    pngs = []
    for root, _, files in os.walk(base_dir):
        for file in files:
            if file.endswith(".png"):
                full_path = os.path.join(root, file)
                pngs.append(full_path)
    return pngs

def convert_png_to_cursor(png_path, output_dir):
    name = os.path.splitext(os.path.basename(png_path))[0]
    cursor_txt = os.path.join(output_dir, f"{name}.txt")
    cursor_file = os.path.join(output_dir, name)

    # Default hotspot in top-left
    with open(cursor_txt, "w") as f:
        f.write(f"{png_path} 0 0\n")

    subprocess.run(["xcursorgen", cursor_txt, cursor_file], check=True)
    os.remove(cursor_txt)

def convert_all():
    cursor_output = os.path.join(OUTPUT_XCUR_DIR, "cursors")
    os.makedirs(cursor_output, exist_ok=True)

    pngs = find_pngs(HYPRCURSOR_DIR)
    for png in pngs:
        convert_png_to_cursor(png, cursor_output)

    # Optional: minimal index.theme
    index_path = os.path.join(OUTPUT_XCUR_DIR, "index.theme")
    with open(index_path, "w") as f:
        f.write("[Icon Theme]\n")
        f.write("Name=ConvertedCursor\n")
        f.write("Comment=Generated from Hyprcursor theme\n")

if __name__ == "__main__":
    convert_all()
