process Extract_chr_pos {

    tag "$sample_id:$chrom"
    label 'quick_jobs'
    publishDir "${params.outputDir}/vcf_breakdown/$sample_id", mode: params.saveMode

    input:
    tuple val(chrom), 
    val(sample_id),
    path(vcf_file), 
    path(tabix_file) 

    output:
    tuple val(chrom),val(sample_id), path("${sample_id}_${chrom}_pos.vcf"),path (tabix_file), emit: chr_pos_vcf

    shell:
    '''
    echo "Processing Chromosome !{chrom} for Sample !{sample_id} with VCF: !{vcf_file}"
    sh /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/extract_chr.sh -V !{vcf_file} -C !{chrom} 
    '''
}
