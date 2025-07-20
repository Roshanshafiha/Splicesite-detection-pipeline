<<comment
The below script is coded for running spliceAi . The database path for squirl is currently hardcoded into the 
script.
Github : https://github.com/monarch-initiative/Squirls
Documentation: https://squirls.readthedocs.io/en/master/running.html

Author : Roshan shafiha 
comment
#load the required modules
source /etc/profile.d/modules.sh
module load htslib/1.9
module load python/2.7
module load java/1.8.0
module load vt/v0.57
module load bcftools/v1.21
module load SnpEff/4.3T/4.3T
module load squirls/2.0.1 

# Input arguments
vcf_file=$1
SQUIRLS_DATA=/gpfs/projects/tmedicine/Shafiha/datahub/squirl/data_hg19_2203/

# Function to display help message
display_help() {
  echo "Usage: $0 -V <vcf_file> "
  echo
  echo "  -V <vcf_file>             Path to the input VCF file"
  echo "  -h                        Display this help message"
  echo
  echo "Example: $0 -V input.vcf.gz "
  exit 1
}

# Parse command-line arguments using getopts
while getopts "V:h" opt; do
  case ${opt} in
    V)
      vcf_file=${OPTARG}
      ;;
    h)
      display_help
      ;;
    *)
      display_help
      ;;
  esac
done

# Check if required arguments are provided
if [[ -z ${vcf_file}  ]]; then
  echo "Error: Missing required arguments."
  display_help
fi


# Output file prefix
#output=$(basename ${vcf_file} .vcf.gz | cut -d'_' -f1)
#squirl_output="${output}_squirl"

# Extract sample_id and chromosome from the filename
sample_id=$(basename ${vcf_file} | cut -d'_' -f1-2)  # Extract "MND-97" as sample_id
chr_pos=$(basename ${vcf_file} | cut -d'_' -f3 | cut -d'.' -f1)  # Extract "1_pos" as chr_pos
#output=$(basename ${vcf_file} .vcf.gz | cut -d'_' -f1)
squirl_output="${sample_id}_${chr_pos}_squirl_initial"

echo "starting to perform squirl ..."
echo "squirl output file name would be ${squirl_output}"

java -jar $JAR/squirls-cli-2.0.1.jar annotate-vcf -d $SQUIRLS_DATA -f vcf,html,tsv -t ENSEMBL ${vcf_file} ${squirl_output} --threads=32


echo "Transfer pathogenic information from tsv to vcf file in squirl..."

awk -F '\t' 'BEGIN {OFS="\t"} NR>1 {print $2, $3, $4, $5, $8}' ${squirl_output}.tsv > pathogen_annotation.tsv
echo '##INFO=<ID=SQUIRL_INTERPRETATION,Number=1,Type=String,Description="Interpretation from SQUIRL">' > info_header.txt
sort -k1,1 -k2,2n pathogen_annotation.tsv > pathogen_annotation.sorted.tsv
bgzip -c pathogen_annotation.sorted.tsv > pathogen_annotation.sorted.tsv.gz
tabix -s 1 -b 2 -e 2 pathogen_annotation.sorted.tsv.gz


squirl_output_pathogen_annotated="${sample_id}_${chr_pos}_squirl.vcf"

bcftools annotate -a pathogen_annotation.sorted.tsv.gz -c CHROM,POS,REF,ALT,INFO/SQUIRL_INTERPRETATION:=interpretation -h info_header.txt -o ${squirl_output_pathogen_annotated}  ${squirl_output}.vcf

# Check if the reference filtered VCF was created
if [[ ! -f ${squirl_output}.vcf ]]; then
    echo "Error: Squirl output (${squirl_output}.vcf) was not created."
    exit 1
fi


echo "All steps compledted succesfully..."

