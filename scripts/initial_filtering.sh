source /etc/profile.d/modules.sh
module load htslib/1.9
module load python/2.7
module load java/1.8.0
module load vt/v0.57
module load bcftools/v1.21
module load SnpEff/4.3T/4.3T
module load bedtools/2.30

# Input arguments
vcf_file=$1
bed_file=$2


# Output file prefix
output=$(basename ${vcf_file} .vcf.gz)
index_Sample=$(bcftools query -l ${vcf_file} | grep  "\-01\_")
parent02_Sample=$(bcftools query -l ${vcf_file} | grep  "\-02\_")
parent03_Sample=$(bcftools query -l ${vcf_file} | grep  "\-03\_")

#get mom and dad index and save it into a txt file 

echo -e "${index_Sample}" > "${index_Sample}_id.txt"
echo -e "${parent02_Sample}" > "${parent02_Sample}_id.txt"
echo -e "${parent03_Sample}" > "${parent03_Sample}_id.txt"
echo "Processing VCF: ${vcf_file}"
echo "Output prefix: ${output}"

# Step 1: Filter vcf file with protein coding region and other filter based on the variant 
echo "Step 1: Filtering variants..."
filtered_vcf="${output}_filtered.vcf.gz"

#extract the sample id and filter genotype thats not ref 
file_1='GT[@'${index_Sample}_id.txt']="ref"'
file_2='GT[@'${index_Sample}_id.txt']="./."'

#parent filteration
parent02='GT[@'${parent02_Sample}_id.txt']="1/1"'
parent03='GT[@'${parent03_Sample}_id.txt']="1/1"'


bedtools intersect -a "${vcf_file}" -b "${bed_file}" -header | \
bcftools view -i '(AC>0 & ALT != "*")' | \
bcftools view -i 'INFO/OLD_MULTIALLELIC=="."' | \
bcftools view -e "${file_1}" | \
bcftools view -e "${parent02} && ${parent03}"|\
bcftools view -e "${file_2}" | \
bcftools view -i 'INFO/gnomadWGS_AF=="." || INFO/gnomadWGS_AF<=0.01' | \
bgzip -c -@ 32 > ${filtered_vcf} 


# Check if the filtered VCF was created
if [[ ! -f ${filtered_vcf} ]]; then
    echo "Error: Filtered VCF (${filtered_vcf}) was not created."
    exit 1
fi

# Index the filtered VCF
echo "Indexing the filtered VCF..."
tabix -p vcf ${filtered_vcf}

#remove the info column and GT column for splice tools :

input_vcf_splicetool="${output}_input_splicetool.vcf.gz"
bcftools annotate -x INFO ${filtered_vcf} |\
bcftools view -G |\
bcftools norm -D |\
bgzip -c -@ 32 > ${input_vcf_splicetool}

# Index the splice tool input VCF
echo "Indexing the filtered VCF..."
tabix -p vcf ${input_vcf_splicetool}

# Check if the reference filtered VCF was created
if [[ ! -f ${input_vcf_splicetool} ]]; then
    echo "Error: Filtered VCF (${input_vcf_splicetool}) was not created."
    exit 1
fi

echo "All filteration compledted succesfully..."

