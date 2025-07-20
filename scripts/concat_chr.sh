<<comment
The below script joins all the annotated vcf files split by extract_chr.sh script.
Author: Roshan Shafiha
comment

# Load required modules
source /etc/profile.d/modules.sh
module load htslib/1.9
module load java/1.8.0
module load vt/v0.57
module load bcftools/v1.21
module load SnpEff/4.3T/4.3T

# Initialize variables
all_vcf_file=""
family_id=""
splice_tool=""
# Function to display help message
display_help() {
  echo "Usage: $0 -V <all_vcf_file> -F <family_id> -T <splice_tool>"
  echo
  echo "  -V <all_vcf_file>             all the VCF file to concat"
  echo "  -F <family_id>            Family ID"
  echo "  -T <splice_tool>          splice tool"
  echo "  -h                        Display this help message"
  echo
  echo "Example: $0 -V all_vcf.txt -F MND_1 -T spliceai"
  exit 1
}

# Parse command-line arguments using getopts
while getopts "V:F:T:h" opt; do
  case ${opt} in
    V) all_vcf_file=${OPTARG} ;;
    F) family_id=${OPTARG} ;;
    T) splice_tool=${OPTARG} ;;
    h) display_help ;;
    *) display_help ;;
  esac
done

# Check if required arguments are provided
if [[ -z ${all_vcf_file} || -z ${family_id} || -z ${splice_tool} ]]; then
  echo "Error: Missing required arguments."
  display_help
fi

# Output file prefix
concated_vcf_output="${family_id}_${splice_tool}_concat.vcf.gz"
echo "Output file: ${concated_vcf_output}"

# Run bcftools to join the vcf
bcftools concat -f ${all_vcf_file} |\
bcftools sort -Oz -o ${concated_vcf_output}

# Index the concat VCF
echo "Indexing the concat VCF..."
tabix -p vcf ${concated_vcf_output}



# Check if the output file was created
if [[ ! -f ${concated_vcf_output} ]]; then
  echo "Error: VCF output (${concated_vcf_output}) for Family ${family_id} was not created."
  exit 1
fi

echo "Family ${family_id} concat completed successfully."
echo "All steps completed successfully."
