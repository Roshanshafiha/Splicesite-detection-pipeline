<<comment
The below script adds annotation to the vcf files.
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
main_vcf_file=""
pangolin_vcf=""
squirl_vcf=""
spliceai_vcf=""
family_id=""
spliceVARdb=""
genepanel=""
genepanel_header=""
# Function to display help message
display_help() {
  echo "Usage: $0 -M <main_vcf_file> -s <squirl_vcf> -p <pangolin_vcf> -a <spliceai_vcf> -F <family_id> -v <spliceVARdb> -g <genepanel> -H <genepanel_header> "
  echo
  echo "  -M <all_vcf_file>             all the VCF file to concat"
  echo "  -s <squirl_vcf>             the id that has to be transfered to main from squirl"
  echo "  -p <pangolin_vcf>             the id that has to be transfered to main from pangolin"
  echo "  -a <spliceai_vcf>             the id that has to be transfered to main from spliceai"
  echo "  -F <family_id>            Family ID"
  echo "  -v <spliceVARdb>            splicevar database annotation file"
  echo "  -g <genepanel>            sorted genepanel bed file"
  echo "  -H <genepanel_header>            genepanel header file for annotating in bcftools"
  echo "  -h                        Display this help message"
  echo
  echo "Example: $0 -M bcftools_filtered.vcf.gz -s squirl_concat.vcf.gz -p pangolin_concact.vcf.gz -a spliceai_vcf -F MND-01 -v splicevardb -g geneomepanel.bed.gz -H genomepanel_header.txt"
  exit 1
}

# Parse command-line arguments using getopts
while getopts "M:s:p:a:F:v:g:H:h" opt; do
  case ${opt} in
    M)main_vcf_file=${OPTARG} ;;
    s)squirl_vcf=${OPTARG} ;;
    p)pangolin_vcf=${OPTARG} ;;
    a)spliceai_vcf=${OPTARG} ;;
    F)family_id=${OPTARG} ;;
    v)spliceVARdb=${OPTARG} ;;
    g)genepanel=${OPTARG} ;;
    H)genepanel_header=${OPTARG} ;;
    h) display_help ;;
    *) display_help ;;
  esac
done

# Check if required arguments are provided
if [[ -z ${main_vcf_file} || -z ${family_id} || -z ${squirl_vcf} || -z ${spliceai_vcf} || -z ${spliceVARdb} || -z ${genepanel} || -z ${genepanel_header} ]]; then
  echo "Error: Missing required arguments."
  exit 1
fi

# Output file prefix
annotated_vcf_output="${family_id}_splicetools_annotated.vcf.gz"
echo "Output file: ${annotated_vcf_output}"

# Run bcftools to join the vcf



bcftools annotate ${main_vcf_file}  --threads 8 -a ${squirl_vcf}  -c SQUIRLS_SCORE,SQUIRL_INTERPRETATION -Oz -o temp.vcf.gz
tabix -p vcf temp.vcf.gz
bcftools annotate temp.vcf.gz  --threads 8 -a ${spliceai_vcf}  -c INFO/SpliceAI,INFO/BEST_DS_AG,INFO/BEST_DS_AL,INFO/BEST_DS_DG,INFO/BEST_DS_DL -Oz -o temp_spliceai.vcf.gz
tabix -p vcf temp_spliceai.vcf.gz
bcftools annotate temp_spliceai.vcf.gz --threads 8 -a ${pangolin_vcf} -c Pangolin,Pangolin_best_increase,Pangolin_best_decrease -Oz -o  temp_pangolin.vcf.gz
tabix -p vcf temp_pangolin.vcf.gz
bcftools annotate temp_pangolin.vcf.gz --threads 8 -a ${spliceVARdb}  -c HGVS_splicevardb,CLASSIFICATION_splicevardb -Oz -o temp_splicevardb.vcf.gz
tabix -p vcf temp_splicevardb.vcf.gz
bcftools annotate temp_splicevardb.vcf.gz --threads 8 -a ${genepanel}  -c CHROM,FROM,TO,Entity.Name_GEpanel,Evidence_GEpanel,Panel.Name_GEpanel,Phenotypes_GEpanel -h ${genepanel_header} -Oz -o  ${annotated_vcf_output}


# Index the concat VCF
echo "Indexing the concat VCF..."
tabix -p vcf  ${annotated_vcf_output}


# Check if the output file was created
if [[ ! -f ${annotated_vcf_output} ]]; then
  echo "Error: VCF output (${annotated_vcf_output}) for Family ${family_id} was not created."
  exit 1
fi

echo "Family ${family_id} concat completed successfully."
echo "All steps completed successfully."
