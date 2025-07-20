<<comment
The below script is coded for running Pangolin . It currently has hardcoded distance and masked region. To understand 
how it was run check the following github page : https://github.com/tkzeng/Pangolin
The database file was created based on the information provided by : https://github.com/tkzeng/Pangolin/blob/main/scripts/create_db.py

Author : Roshan shafiha 
comment
source /etc/profile.d/modules.sh
module load htslib/1.9
module load java/1.8.0
module load vt/v0.57
module load bcftools/v1.21
module load SnpEff/4.3T/4.3T
module load pangolin/1.0.2

# Initialize variables
vcf_file=""
assembly_genome=""
database=""
chromosome=""

# Function to display help message
display_help() {
  echo "Usage: $0 -V <vcf_file> -A <assembly_genome> -D <database> -C <chromosome>"
  echo
  echo "  -V <vcf_file>             Path to the input VCF file"
  echo "  -A <assembly_genome>      primary assembly genome from Gencode"
  echo "  -D <database>             Path to the database file"
  echo "  -C <chromosome>          chromosome number"
  echo "  -h                        Display this help message"
  echo
  echo "Example: $0 -V input.vcf -A /path/to/assembly_genome.fa.gz -D /path/to/database.db -C 3"
  exit 1
}

# Parse command-line arguments using getopts
while getopts "V:A:D:C:h" opt; do
  case ${opt} in
    V)
      vcf_file=${OPTARG}
      ;;
    A)
      assembly_genome=${OPTARG}
      ;;
    D)
      database=${OPTARG}
      ;;
    C)
      chromosome=${OPTARG}
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
if [[ -z ${vcf_file} || -z ${assembly_genome} || -z ${database} || -z ${chromosome} ]]; then
  echo "Error: Missing required arguments."
  display_help
fi


# Extract sample_id and chromosome from the filename
sample_id=$(basename ${vcf_file} | cut -d'_' -f1-2)  # Extract "MND-97" as sample_id
chr_pos=$(basename ${vcf_file} | cut -d'_' -f3 | cut -d'.' -f1)     # Extract "1_pos" as chr_pos
#output=$(basename ${vcf_file} .vcf.gz | cut -d'_' -f1)
pangolin_output="${sample_id}_${chr_pos}_pangolin"

echo "starting to perform pangolin..."
echo "Basename extracted from file: ${output}"
echo "running for chromosome: ${chromosome}"

# run pangolin currently not masked and distance 500 to match with spliceAI lookup 
pangolin -m False -d 500 ${vcf_file}  ${assembly_genome}  ${database} ${pangolin_output} 

# Check if the spliceai VCF file was created
if [[ ! -f ${pangolin_output}.vcf ]]; then
    echo "Error: Spliceai output (${pangolin_output}.vcf) was not created."
    exit 1
fi

echo "All steps completed successfully..."
