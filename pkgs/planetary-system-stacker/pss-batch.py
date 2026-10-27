#!/usr/bin/env python3
"""
pss-batch: stack a selection of ASIAIR planetary captures with PlanetarySystemStacker,
then RGB-align each result (PSS's own automatic RGB alignment, as in the GUI).

Clips are chosen from the ASIAIR sidecar files (<clip>.avi.txt) by exposure and gain.
PSS always writes results next to its input, so each selected clip is symlinked into the
output folder first; results land there and the raw folder is left untouched.

Outputs per clip, in the output folder:
  <clip>_pss.fits       stacked image (16-bit FITS)
  <clip>_pss_rgb.fits   same, with red/blue channels aligned to green

Defaults match the settings worked out for the 2026-10-22 Saturn session:
  Planet stabilisation, Force Bayer RGGB, 30 px alignment boxes, best 15% of frames.

Examples:
  pss-batch --dry-run                       # list what would be processed
  pss-batch                                 # gain >= 300, any exposure, all dates
  pss-batch --exposure 0.015 --min-gain 300 # only 15 ms, gain 300 and up
  pss-batch --date 2026-10-22 --min-gain 252
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path


def read_sidecar(txt: Path) -> dict:
    """Parse an ASIAIR '<clip>.avi.txt' file into a dict of key -> value strings."""
    info = {}
    for line in txt.read_text(errors="replace").splitlines():
        if "=" in line:
            key, _, value = line.partition("=")
            info[key.strip()] = value.strip()
    return info


def parse_exposure(value: str) -> float:
    """'0.015 Sec' -> 0.015"""
    m = re.match(r"\s*([0-9.]+)", value or "")
    return float(m.group(1)) if m else float("nan")


def select_clips(raw_dir: Path, args) -> list:
    clips = []
    for avi in sorted(raw_dir.glob("*.avi")):
        if args.date and not avi.name.startswith(args.date):
            continue
        txt = avi.with_name(avi.name + ".txt")
        if not txt.exists():
            print(f"  skip (no sidecar): {avi.name}")
            continue
        info = read_sidecar(txt)
        exposure = parse_exposure(info.get("Exposure", ""))
        try:
            gain = int(info.get("Gain", "-1"))
        except ValueError:
            gain = -1
        if args.exposure is not None and abs(exposure - args.exposure) > 1e-6:
            continue
        if gain < args.min_gain:
            continue
        clips.append((avi, exposure, gain, info.get("Capture Area Size", "?")))
    return clips


def find_pss() -> str:
    """Locate the PlanetarySystemStacker launcher (sibling of this script when installed)."""
    for base in (Path(__file__), Path(sys.argv[0])):
        sibling = base.resolve().parent / "PlanetarySystemStacker"
        if sibling.exists():
            return str(sibling)
    found = shutil.which("PlanetarySystemStacker")
    if not found:
        sys.exit("PlanetarySystemStacker not found on PATH.")
    return found


def rgb_align(stack: Path, out: Path, resolution: int):
    """Apply PSS's automatic RGB alignment (same function as the GUI's 'Automatic' box)."""
    # PSS's modules import each other by bare name (e.g. "import ser_parser"), so its package
    # folder must be on sys.path, as it is when PSS itself runs.
    import planetary_system_stacker
    pkg_dir = os.path.dirname(planetary_system_stacker.__file__)
    if pkg_dir not in sys.path:
        sys.path.insert(0, pkg_dir)
    from frames import Frames
    from miscellaneous import Miscellaneous

    image = Frames.read_image(str(stack))
    if image.ndim != 3:
        print(f"    {stack.name}: monochrome, no RGB alignment needed")
        return
    # 5 px is PSS's default maximum channel shift (configuration.postproc_max_shift).
    aligned, shift_red, shift_blue = Miscellaneous.auto_rgb_align(
        image, 5, interpolation_factor=resolution)
    Frames.save_image(str(out), aligned, color=True, avoid_overwriting=False)
    print(f"    {out.name}: red shift {tuple(round(s, 2) for s in shift_red)}, "
          f"blue shift {tuple(round(s, 2) for s in shift_blue)} (y, x px)")


def main():
    sys.stdout.reconfigure(line_buffering=True)  # keep our output in order with PSS's
    home = Path.home()
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--raw-dir", type=Path, default=home / "Astro" / "Saturn",
                   help="folder with the .avi clips and .avi.txt sidecars (default: %(default)s)")
    p.add_argument("--out-dir", type=Path, default=None,
                   help="output folder (default: ~/Astro/Saturn-processed/batch-<today>)")
    p.add_argument("--date", default=None,
                   help="only clips whose name starts with this, e.g. 2026-10-22")
    p.add_argument("--exposure", type=float, default=None,
                   help="only this exposure in seconds, e.g. 0.015 (default: any)")
    p.add_argument("--min-gain", type=int, default=300,
                   help="minimum gain (default: %(default)s)")
    p.add_argument("--stack-percent", type=int, default=15,
                   help="percent of best frames to stack (default: %(default)s)")
    p.add_argument("--box", type=int, default=30,
                   help="alignment box width in px (default: %(default)s)")
    p.add_argument("--debayer", default="Force Bayer RGGB",
                   help="PSS debayering choice (default: %(default)s)")
    p.add_argument("--rgb-resolution", type=int, choices=[1, 2, 4], default=2,
                   help="RGB alignment precision: 1 = 1 px, 2 = 0.5 px, 4 = 0.25 px (default: 2)")
    p.add_argument("--no-rgb", action="store_true", help="skip RGB alignment")
    p.add_argument("--keep-links", action="store_true",
                   help="keep the clip symlinks in the output folder afterwards")
    p.add_argument("--dry-run", action="store_true", help="only list the selected clips")
    args = p.parse_args()

    raw_dir = args.raw_dir.expanduser()
    if not raw_dir.is_dir():
        sys.exit(f"Raw folder not found: {raw_dir}")
    out_dir = (args.out_dir or home / "Astro" / "Saturn-processed" /
               f"batch-{date.today().isoformat()}").expanduser()

    clips = select_clips(raw_dir, args)
    exp_txt = f"{args.exposure} s" if args.exposure is not None else "any exposure"
    print(f"Selected {len(clips)} clip(s) from {raw_dir} ({exp_txt}, gain >= {args.min_gain}"
          f"{', date ' + args.date if args.date else ''}):")
    for avi, exposure, gain, area in clips:
        print(f"  {avi.name}   {exposure:g} s  gain {gain}  {area}")
    if not clips:
        return
    print(f"Output folder: {out_dir}")
    if args.dry_run:
        return

    out_dir.mkdir(parents=True, exist_ok=True)
    links = []
    for avi, *_ in clips:
        link = out_dir / avi.name
        if link.is_symlink() or link.exists():
            link.unlink()
        link.symlink_to(avi.resolve())
        links.append(link)

    pss = find_pss()
    cmd = [pss,
           "--out_format", "fits",
           "--debayering", args.debayer,
           "--stab_mode", "Planet",
           "--align_box_width", str(args.box),
           "--stack_percent", str(args.stack_percent),
           *[str(link) for link in links]]
    print("\nRunning PlanetarySystemStacker on", len(links), "clip(s)...\n")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"\nPlanetarySystemStacker exited with code {result.returncode}.")

    if not args.no_rgb:
        print("\nRGB alignment:")
        for link in links:
            stack = out_dir / (link.stem + "_pss.fits")
            if not stack.exists():
                print(f"    {stack.name}: missing (stacking failed?)")
                continue
            try:
                rgb_align(stack, out_dir / (link.stem + "_pss_rgb.fits"), args.rgb_resolution)
            except Exception as e:  # keep going with the other clips
                print(f"    {stack.name}: RGB alignment failed: {e}")

    if not args.keep_links:
        for link in links:
            if link.is_symlink():
                link.unlink()

    print(f"\nDone. Results in {out_dir}")


if __name__ == "__main__":
    main()
