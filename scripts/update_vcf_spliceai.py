#!/usr/bin/env python3
"""
update_vcf_spliceai.py

This script reads a VCF file, parses the SpliceAI annotation field,
and for each variant computes the maximum delta scores (DS_AG, DS_AL, DS_DG, DS_DL)
across all comma‐separated SpliceAI annotations. It then adds these as new INFO keys:
  BEST_DS_AG, BEST_DS_AL, BEST_DS_DG, and BEST_DS_DL

Usage:
    python update_vcf_spliceai.py input.vcf -o output.vcf

If using STDIN for input, specify '-' as the VCF filename.
"""

import sys
import argparse

def parse_spliceai(spliceai_str):
    """
    Parse a SpliceAI annotation string.
    
    Expected format for each annotation:
        ALLELE|TRANSCRIPT|DS_AG|DS_AL|DS_DG|DS_DL|DP_AG|DP_AL|DP_DG|DP_DL

    Multiple annotations are comma separated.
    
    Returns:
        List of dictionaries (one per annotation) with keys:
          'ALLELE', 'transcript', 'DS_AG', 'DS_AL', 'DS_DG', 'DS_DL',
          'DP_AG', 'DP_AL', 'DP_DG', 'DP_DL'
    """
    spliceai_str = spliceai_str.strip()
    if not spliceai_str:
        return []
    annotations = spliceai_str.split(',')
    parsed = []
    for ann in annotations:
        fields = ann.split('|')
        if len(fields) != 10:
            # Skip annotation if not the expected number of fields.
            continue
        try:
            ds_ag = float(fields[2])
            ds_al = float(fields[3])
            ds_dg = float(fields[4])
            ds_dl = float(fields[5])
            parsed.append({
                'ALLELE': fields[0],
                'transcript': fields[1],
                'DS_AG': ds_ag,
                'DS_AL': ds_al,
                'DS_DG': ds_dg,
                'DS_DL': ds_dl,
                'DP_AG': int(fields[6]),
                'DP_AL': int(fields[7]),
                'DP_DG': int(fields[8]),
                'DP_DL': int(fields[9])
            })
        except Exception:
            continue
    return parsed

def update_info_field(info, best_values):
    """
    Given the original INFO string and a dictionary best_values (with keys
    BEST_DS_AG, BEST_DS_AL, BEST_DS_DG, BEST_DS_DL), return a new INFO string
    that appends these key=value pairs.
    """
    new_fields = []
    for key, val in best_values.items():
        # Format as a float with two decimals.
        new_fields.append(f"{key}={val:.2f}")
    if info == ".":
        return ";".join(new_fields)
    else:
        return info + ";" + ";".join(new_fields)

def process_vcf(infile, outfile):
    """
    Process the input VCF file line by line.

    For header lines:
      - Retain existing header lines.
      - Before the column header (#CHROM ...), add new header lines for the
        BEST_DS_* INFO fields.

    For each variant line:
      - Parse the INFO field.
      - If a SpliceAI annotation is found, compute the maximum values of
        DS_AG, DS_AL, DS_DG, and DS_DL from all annotations.
      - Append these as new INFO keys.
      - Write the modified line to the output.
    """
    header_lines = []
    header_written = False

    # First pass: Collect all header lines before #CHROM
    for line in infile:
        if line.startswith("##"):
            # Collect all meta-information lines
            header_lines.append(line.rstrip("\n"))
        elif line.startswith("#CHROM"):
            # We have reached the column header line, write the stored headers first
            for h in header_lines:
                outfile.write(h + "\n")

            # Write the new INFO headers before #CHROM line
            new_info_headers = [
                '##INFO=<ID=BEST_DS_AG,Number=1,Type=Float,Description="Maximum DS_AG from SpliceAI annotations">',
                '##INFO=<ID=BEST_DS_AL,Number=1,Type=Float,Description="Maximum DS_AL from SpliceAI annotations">',
                '##INFO=<ID=BEST_DS_DG,Number=1,Type=Float,Description="Maximum DS_DG from SpliceAI annotations">',
                '##INFO=<ID=BEST_DS_DL,Number=1,Type=Float,Description="Maximum DS_DL from SpliceAI annotations">'
            ]
            for h in new_info_headers:
                outfile.write(h + "\n")
            
            # Now write the column header (#CHROM ...)
            outfile.write(line)
            
            # Mark that we have written the header section
            header_written = True
            break  # Stop processing header lines after this point

    # Second pass: Process the rest of the data lines
    for line in infile:
        line = line.rstrip("\n")
        if not line:
            continue

        cols = line.split("\t")
        if len(cols) < 8:
            outfile.write(line + "\n")
            continue

        info = cols[7]
        spliceai_value = None

        # Look for a key starting with "SpliceAI=" in the INFO field
        for part in info.split(";"):
            if part.startswith("SpliceAI="):
                spliceai_value = part.split("=", 1)[1]
                break

        if spliceai_value is None:
            # No SpliceAI annotation; write the line unchanged
            outfile.write(line + "\n")
        else:
            annotations = parse_spliceai(spliceai_value)
            if annotations:
                best_ds_ag = max(ann['DS_AG'] for ann in annotations)
                best_ds_al = max(ann['DS_AL'] for ann in annotations)
                best_ds_dg = max(ann['DS_DG'] for ann in annotations)
                best_ds_dl = max(ann['DS_DL'] for ann in annotations)

                best_values = {
                    "BEST_DS_AG": best_ds_ag,
                    "BEST_DS_AL": best_ds_al,
                    "BEST_DS_DG": best_ds_dg,
                    "BEST_DS_DL": best_ds_dl
                }

                new_info = update_info_field(info, best_values)
                cols[7] = new_info
                outfile.write("\t".join(cols) + "\n")
            else:
                outfile.write(line + "\n")



def main():
    parser = argparse.ArgumentParser(
        description="Update a VCF file by adding best (maximum) SpliceAI DS values as new INFO fields."
    )
    parser.add_argument("vcf", help="Input VCF file (use '-' for STDIN)")
    parser.add_argument("-o", "--output", help="Output VCF file", default=None)
    args = parser.parse_args()

    # Open the input file.
    if args.vcf == "-":
        infile = sys.stdin
    else:
        try:
            infile = open(args.vcf, "r")
        except Exception as e:
            sys.exit(f"Error opening input VCF file {args.vcf}: {e}")

    # Open the output file (or use STDOUT).
    if args.output:
        try:
            outfile = open(args.output, "w")
        except Exception as e:
            sys.exit(f"Error opening output file {args.output}: {e}")
    else:
        outfile = sys.stdout

    process_vcf(infile, outfile)

    if infile is not sys.stdin:
        infile.close()
    if outfile is not sys.stdout:
        outfile.close()

if __name__ == "__main__":
    main()

