source /etc/profile.d/modules.sh
module load htslib/1.9
module load python/3.9.12
module load java/1.8.0
module load vt/v0.57
module load bcftools/v1.21
module load SnpEff/4.3T/4.3T


# Input arguments
vcf_file=$1
sample_id=$2
chrom=$3


# Output file prefix
output=$(basename ${vcf_file} .vcf.gz | cut -d'_' -f1)
updated_output="${output}_score_fix_pangolin.vcf"

echo "starting to perform squirl compledted succesfully..."

python /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/update_vcf_pangolin.py ${vcf_file} -o ${updated_output}



# Check if the reference filtered VCF was created
if [[ ! -f ${updated_output} ]]; then
    echo "Error: Pangolin score updated output (${updated_output}) was not created."
    exit 1
fi

echo "All steps compledted succesfully..."

