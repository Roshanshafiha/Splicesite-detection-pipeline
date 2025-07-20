#!/usr/bin/bash
source /etc/profile.d/modules.sh
module load htslib/1.9
module load python/2.7
module load java/1.8.0
module load vt/v0.57
module load vcfanno/0.3.5_py2.7
module load SnpEff/4.3T/4.3T

# Initialize variables
main_vcf_file=""
family_id=""

# Function to display help message
display_help() {
  echo "Usage: $0 -M <main_vcf_file> -F <family_id> "
  echo
  echo "  -M <all_vcf_file>             all the VCF file to concat"
  echo "  -F <family_id>            Family ID"
  echo "  -h                        Display this help message"
  echo
  echo "Example: $0 -M MND-88_splicetools_annotated.vcf.gz -F MND-88"
  exit 1
}

# Parse command-line arguments using getopts
while getopts "M:F:h" opt; do
  case ${opt} in
    M)main_vcf_file=${OPTARG} ;;
    F)family_id=${OPTARG} ;;
    h) display_help ;;
    *) display_help ;;
  esac
done

# Check if required arguments are provided
if [[ -z ${main_vcf_file} || -z ${family_id} ]]; then
  echo "Error: Missing required arguments."
  exit 1
fi

# Output file prefix
annotated_tsv_output="${family_id}_splicetools_annotated.tsv"
echo "Output file: ${annotated_tsv_output}"


## Extraction of splicetool column and converting them to tsv 
echo "Extraction of splicetool column and converting vcf to tsv"
java -XX:+UseParallelGC -XX:ParallelGCThreads=32 -Xmx128g -Djava.io.tmpdir=tmp -jar /gpfs/software/genomics/SnpEff/4.3T/snpEff/SnpSift.jar extractFields -t -s "," -e "." ${main_vcf_file} CHROM POS ID REF ALT FILTER QUAL OLD_MULTIALLELIC DP AC AN AF GEN[*].DP GEN[*].GT ANN[0].EFFECT ANN[1].EFFECT ANN[0].IMPACT ANN[1].IMPACT ANN[0].GENE ANN[1].GENE ANN[0].GENEID ANN[0].FEATURE ANN[0].FEATUREID ANN[0].BIOTYPE ANN[0].RANK ANN[0].HGVS_C ANN[0].HGVS_P LOF[*].GENE LOF[*].NUMTR LOF[*].PERC dbNSFP_Polyphen2_HDIV_score dbNSFP_Polyphen2_HVAR_score dbNSFP_SIFT_score dbNSFP_MutationTaster_score dbNSFP_MutationAssessor_score CADD GERP ccr_pct_v2 ccr_pct_v2_90_percentile lof_z pLI 1kg_AF 1k_MAX ExAC_AF gnomAD_Exome_AF gnomAD_Exome_MAX gnomadWGS_AF gnomadWGS_MAX 1000k_asia_AF 1000k_asia_MAX GHS_AF gnomAD_Exome_nhomalt gnomadWGS_nhomalt gnomadWGS_AF_male gnomadWGS_AF_female gnomAD_Exome_male gnomAD_Exome_female DS_AG DS_AL DS_DG DS_DL mpc_obs_exp mpc_mis_badness mpc_fitted_score MPC QAT_AF PMID GME OMIM_PATTERN CLNSIG CLNDN CLNREVSTAT CLNVI CLINVAR_DISEASES CGD_COND CGC_INHERITANCE INTERVENTION HPO_PHENO geno2mp VKGL_CLASSIFICATION VKGL_SUPPORT PrimateDL gwas_pubmed_trait dgv rmsk cpg_island LCR SQUIRLS_SCORE SQUIRL_INTERPRETATION BEST_DS_AG BEST_DS_AL BEST_DS_DG BEST_DS_DL Pangolin Pangolin_best_increase Pangolin_best_decrease HGVS_splicevardb CLASSIFICATION_splicevardb Entity.Name_GEpanel Evidence_GEpanel Panel.Name_GEpanel Phenotypes_GEpanel > ${family_id}_parsed.tsv || exit 1	

#clean the data 
##Cleaning data and doing filtering. 
python /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/snpEffParseSampleGATKMulti.py ${family_id}_parsed.tsv ${main_vcf_file} > ${annotated_tsv_output}



# Check if the output file was created
if [[ ! -f ${annotated_tsv_output} ]]; then
  echo "Error: VCF output (${family_id}_splicetools_annotated.tsv) for Family ${family_id} was not created."
  exit 1
fi

echo "Family ${family_id} tsv conversion completed successfully."
echo "All steps completed successfully."
