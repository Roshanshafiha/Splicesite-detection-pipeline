process Update_score_pangolin {

    tag "$sample_id"
	publishDir "${params.outputDir}/score_update_pangolin/$sample_id", mode: params.saveMode

    input:
    tuple val(chrom), val(sample_id), path(vcf_file) // `meta` is the folder name, `vcf_file` is the VCF file path
    
    output:
    //tuple val(chrom), val(sample_id), path("${sample_id}_${chrom}_pos_spliceai.vcf")        , emit: spliceai_output
    tuple val(chrom), val(sample_id), path("${sample_id}_${chrom}_score_fix_pangolin.vcf")        , emit: pangolin_output
    

    shell:
    '''
    echo "Processing VCF file: !{sample_id}"
    sh /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/update_score_pangolin.sh !{vcf_file} !{sample_id} !{chrom}
    
    cp !{sample_id}_score_fix_pangolin.vcf ./!{sample_id}_!{chrom}_score_fix_pangolin.vcf

    '''
}
