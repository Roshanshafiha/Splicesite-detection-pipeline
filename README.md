# 🧬 Splice-Site Detection Pipeline for RNA-seq Data

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A522.10.0-brightgreen)](https://www.nextflow.io/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/container-docker-blue)](https://www.docker.com/)
[![RNA-seq Workflow](https://img.shields.io/badge/workflow-RNA--seq-purple)](#)

---

## 📖 Overview

This pipeline performs splice-site variant detection and annotation from **WGS VCF files**, using multiple predictive tools and reference databases. It is built using **Nextflow DSL2** and supports modular, scalable analysis in research or clinical environments.

---

## 🛠️ Tools Integrated

| Tool          | Description |
|---------------|-------------|
| **bcftools**  | Preprocessing, filtering, and chromosome-level splitting of VCFs |
| **SpliceAI**  | Deep learning model for predicting splice-altering variants |
| **Pangolin**  | Probabilistic model of splice junction usage across transcriptomes |
| **SQUIRLS**   | Interpretable machine learning for splice prediction |
| **Custom Scripts** | Used for annotation merging, score updates, VCF-to-TSV conversion |
| **Databases** | Integration with SpliceVarDB and Genomics England gene panels |

---

## 📦 Requirements

- [Nextflow ≥ 22.10.0](https://www.nextflow.io/)
- Java 11+
- Docker or Singularity (optional but recommended)
- Required files:
  - VCF files from RNA-seq variants
  - BED file with coding regions
  - Reference genomes and annotation databases for tools
  - SpliceVarDB and Genomics England panel files

---

---

## 📂 Directory Structure

```text
Splice-site-detection-pipeline/
├── config.cfg                    # Config file
├── main.nf                       # Main Nextflow pipeline
├── process/                      # DSL2 modules for each step
│   ├── bcftools.nf
│   ├── extract_chr.nf
│   ├── spliceai.nf
│   ├── pangolin.nf
│   ├── squirl.nf
│   ├── update_score_spliceai.nf
│   ├── update_score_pangolin.nf
│   ├── concat_vcf.nf
│   ├── annotate_vcf.nf
│   ├── vcf_to_tsv.nf
├── scripts/                      # Bash/Python helper scripts
│   ├── spliceai.sh
│   ├── pangolin.sh
│   ├── squirl.sh
│   ├── update_vcf_spliceai.py
│   ├── update_vcf_pangolin.py
│   ├── snpEffParseSampleGATKMulti.py
│   └── ...
└── input_data/                   # (User-provided) VCF inputs


---

## 🌐 How to Run the Pipeline

```bash
nextflow run main.nf \
  --spliceai_annotation path/to/spliceai/db \
  --spliceai_ref_genome path/to/spliceai/genome.fa \
  --pangolin_assembly_genome path/to/pangolin/genome.fa \
  --pangolin_db path/to/pangolin/db \
  --bedfile path/to/coding_regions.bed \
  --splicevardb path/to/splicevardb.vcf.gz \
  --splicevardb_index path/to/splicevardb.vcf.gz.tbi \
  --genepanel path/to/genepanel.tsv \
  --genepanel_index path/to/genepanel.tsv.idx \
  --genepanel_header path/to/genepanel.header.txt \
  --inputDir ./input_data \
  --outputDir ./pipeline-output \
  --reads "./input_data/MND-*/MND-*.vcf.gz"
##  Parameters

| Parameter                  | Description                          |
| -------------------------- | ------------------------------------ |
| `inputDir`                 | Input directory with gzipped VCFs    |
| `outputDir`                | Output directory for processed files |
| `reads`                    | Glob pattern for input files         |
| `spliceai_annotation`      | SpliceAI annotation VCF              |
| `spliceai_ref_genome`      | SpliceAI-compatible reference genome |
| `pangolin_assembly_genome` | Pangolin genome assembly FASTA       |
| `pangolin_db`              | Pangolin model database              |
| `bedfile`                  | BED file of coding regions           |
| `splicevardb`              | VCF of SpliceVarDB                   |
| `splicevardb_index`        | Tabix index for SpliceVarDB          |
| `genepanel`                | Genomics England gene panel TSV      |
| `genepanel_index`          | Tabix index for the panel            |
| `genepanel_header`         | Header to use with gene panel        |

##  🧪 Example Input Format

input_data/
├── MNZ-001/
│   └── MNZ-001.vcf.gz
├── MNZ-002/
│   └── MNZ-002.vcf.gz


flowchart TD
    A[Input VCFs] --> B[Initial Filtering (bcftools)]
    B --> C[Split by Chromosome]

    C --> D1[SpliceAI Annotation]
    C --> D2[Pangolin Annotation]
    C --> D3[SQUIRLS Annotation]

    D1 --> E1[Update SpliceAI Scores]
    D2 --> E2[Update Pangolin Scores]
    D3 --> E3[SQUIRLS Output]

    E1 --> F[VCF Concatenation]
    E2 --> F
    E3 --> F

    F --> G[Merge with SpliceVarDB & Gene Panel]
    G --> H[VCF to TSV Conversion]
    H --> I[Final Results]




