#!/usr/bin/env python3
"""
update_vcf_pangolin.py

This script reads a VCF file, parses the Pangolin annotation field,
computes the best increase and decrease scores, and appends these as new INFO fields.

The original Pangolin annotation and other INFO fields are preserved.

Usage:
    python update_vcf_pangolin.py input.vcf -o output.vcf
"""

import sys
import argparse

def parse_pangolin(pangolin_str):
    """
    Parse the Pangolin annotation string.

    Expected format per annotation:
      gene_id|position:largest_increase|position:largest_decrease|Warnings:

    Returns:
        List of parsed annotation dicts.
    """
    pangolin_str = pangolin_str.strip()
    if not pangolin_str:
        return []
    annotations = pangolin_str.split(',')
    parsed = []
    for ann in annotations:
        fields = ann.split('|')
        if len(fields) < 4:
            continue
        try:
            gene_id = fields[0]
            inc_pos_score = fields[1]  # e.g. "2:0.2"
            dec_pos_score = fields[2]  # e.g. "-77:-0.05"

            inc_pos, inc_score = inc_pos_score.split(':')
            dec_pos, dec_score = dec_pos_score.split(':')

            inc_score_float = float(inc_score)
            dec_score_float = float(dec_score)

            parsed.append({
                'gene_id': gene_id,
                'increase_score': inc_score_float,
                'decrease_score': dec_score_float,
                'increase_raw': f"{gene_id}|{inc_pos}:{inc_score}",
                'decrease_raw': f"{gene_id}|{dec_pos}:{dec_score}"
            })
        except Exception:
            continue
    return parsed

def append_to_info_field(original_info, new_fields):
    """
    Append new INFO fields to the existing INFO field.
    """
    if not new_fields:
        return original_info
    if original_info == "." or not original_info:
        return ";".join(new_fields)
    return original_info + ";" + ";".join(new_fields)

def process_vcf(infile, outfile):
    """
    Process VCF, add Pangolin_best_increase and Pangolin_best_decrease INFO fields.
    """
    for line in infile:
        line = line.rstrip("\n")

        if line.startswith("##"):
            outfile.write(line + "\n")
            continue

        if line.startswith("#CHROM"):
            # Write new INFO headers before column header
            outfile.write('##INFO=<ID=Pangolin_best_increase,Number=1,Type=String,Description="Annotation with the highest increase score from Pangolin">\n')
            outfile.write('##INFO=<ID=Pangolin_best_decrease,Number=1,Type=String,Description="Annotation with the lowest decrease score from Pangolin">\n')
            outfile.write(line + "\n")
            continue

        if not line.strip():
            continue

        cols = line.split("\t")
        if len(cols) < 8:
            outfile.write(line + "\n")
            continue

        info_field = cols[7]
        pangolin_value = None

        # Look for Pangolin= entry in INFO field
        for part in info_field.split(";"):
            if part.startswith("Pangolin="):
                pangolin_value = part.split("=", 1)[1]
                break

        # No Pangolin annotation? Write the line as-is.
        if pangolin_value is None:
            outfile.write(line + "\n")
            continue

        # Parse Pangolin annotation
        annotations = parse_pangolin(pangolin_value)
        if not annotations:
            # Pangolin entry exists, but couldn't parse it
            outfile.write(line + "\n")
            continue

        # Find best increase & decrease
        best_increase_ann = max(annotations, key=lambda ann: ann['increase_score'])
        best_decrease_ann = min(annotations, key=lambda ann: ann['decrease_score'])

        # Prepare new INFO fields
        new_info_fields = [
            f"Pangolin_best_increase={best_increase_ann['increase_raw']}",
            f"Pangolin_best_decrease={best_decrease_ann['decrease_raw']}"
        ]

        # Append them to the INFO field
        updated_info = append_to_info_field(info_field, new_info_fields)
        cols[7] = updated_info

        outfile.write("\t".join(cols) + "\n")

def main():
    parser = argparse.ArgumentParser(description="Update VCF with Pangolin best increase/decrease annotations.")
    parser.add_argument("vcf", help="Input VCF file (use '-' for STDIN)")
    parser.add_argument("-o", "--output", help="Output VCF file", default=None)
    args = parser.parse_args()

    if args.vcf == "-":
        infile = sys.stdin
    else:
        try:
            infile = open(args.vcf, "r")
        except Exception as e:
            sys.exit(f"Error opening input VCF file {args.vcf}: {e}")

    if args.output:
        try:
            outfile = open(args.output, "w")
        except Exception as e:
            sys.exit(f"Error opening output VCF file {args.output}: {e}")
    else:
        outfile = sys.stdout

    process_vcf(infile, outfile)

    if infile is not sys.stdin:
        infile.close()
    if outfile is not sys.stdout:
        outfile.close()

if __name__ == "__main__":
    main()
