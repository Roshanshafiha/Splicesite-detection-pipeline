<<comment
The below script is coded for running spliceAi . It currenrly has hardcoded distance and masked region. To understand 
how it was run check the following github page : https://github.com/Illumina/SpliceAI.git
The annotation file was created based on the information provided by : https://github.com/broadinstitute/SpliceAI-lookup/tree/master/annotations

Author : Roshan shafiha 
comment
source /etc/profile.d/modules.sh
module load htslib/1.9
module load java/1.8.0
module load vt/v0.57
module load bcftools/v1.21
module load SnpEff/4.3T/4.3T
module load spliceai/v1.3.1

# Initialize variables
vcf_file=""
spliceai_annotation=""
spliceai_reference_genome=""

# Function to display help message
display_help() {
  echo "Usage: $0 -V <vcf_file> -A <annotation_file> -R <reference_genome>"
  echo
  echo "  -V <vcf_file>             Path to the input VCF file"
  echo "  -A <annotation_file>      Path to the SpliceAI annotation file"
  echo "  -R <reference_genome>     Path to the reference genome file"
  echo "  -h                        Display this help message"
  echo
  echo "Example: $0 -V input.vcf.gz -A /path/to/annotation.txt -R /path/to/reference_genome.fa"
  exit 1
}

# Parse command-line arguments using getopts
while getopts "V:A:R:h" opt; do
  case ${opt} in
    V)
      vcf_file=${OPTARG}
      ;;
    A)
      spliceai_annotation=${OPTARG}
      ;;
    R)
      spliceai_reference_genome=${OPTARG}
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
if [[ -z ${vcf_file} || -z ${spliceai_annotation} || -z ${spliceai_reference_genome} ]]; then
  echo "Error: Missing required arguments."
  display_help
fi


# Extract sample_id and chromosome from the filename
sample_id=$(basename ${vcf_file} | cut -d'_' -f1-2)  # Extract "MND-97" as sample_id
chr_pos=$(basename ${vcf_file} | cut -d'_' -f3 | cut -d'.' -f1)  # Extract "1_pos" as chr_pos
#output=$(basename ${vcf_file} .vcf.gz | cut -d'_' -f1)
spliceai_output="${sample_id}_${chr_pos}_spliceai.vcf"

echo "starting to perform spliceai..."
echo "Basename extracted from file: ${output}"

# run splice AI 
spliceai -I ${vcf_file} -O ${spliceai_output} -R ${spliceai_reference_genome} -A ${spliceai_annotation} -D 500

# Check if the spliceai VCF file was created
if [[ ! -f ${spliceai_output} ]]; then
    echo "Error: Spliceai output (${spliceai_output}) was not created."
    exit 1
fi

echo "All steps completed successfully..."
