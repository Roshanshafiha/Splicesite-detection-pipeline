<<comment
The below script splits a VCF file by chromosome position to speed up splice annotation tools.
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
vcf_file=""
chr=""

# Function to display help message
display_help() {
  echo "Usage: $0 -V <vcf_file> -C <chr>"
  echo
  echo "  -V <vcf_file>             Path to the input VCF file"
  echo "  -C <chr>                  Chromosome position"
  echo "  -h                        Display this help message"
  echo
  echo "Example: $0 -V input.vcf.gz -C chr1"
  exit 1
}

# Parse command-line arguments using getopts
while getopts "V:C:h" opt; do
  case ${opt} in
    V) vcf_file=${OPTARG} ;;
    C) chr=${OPTARG} ;;
    h) display_help ;;
    *) display_help ;;
  esac
done

# Check if required arguments are provided
if [[ -z ${vcf_file} || -z ${chr} ]]; then
  echo "Error: Missing required arguments."
  display_help
fi

# Output file prefix
output=$(basename "${vcf_file}" .vcf.gz | cut -d'_' -f1)
chr_vcf_output="${output}_${chr}_pos.vcf"

echo "Starting chromosome position extraction for ${chr}..."
echo "Base filename extracted: ${output}"
echo "Output file: ${chr_vcf_output}"

# Run bcftools to extract the chromosome and compress the output
bcftools view -r ${chr} ${vcf_file} -o ${chr_vcf_output}

# Check if the output file was created
if [[ ! -f ${chr_vcf_output} ]]; then
  echo "Error: VCF output (${chr_vcf_output}) for chromosome ${chr} was not created."
  exit 1
fi

echo "Chromosome ${chr} extraction completed successfully."
echo "All steps completed successfully."
