process Squirl_splice_tool {


    label 'squirl'
    tag "$sample_id"
	publishDir "${params.outputDir}/squirl/$sample_id", mode: params.saveMode

    input:
    tuple val(chrom), 
          val(sample_id),
          path(vcf_file), 
          path(tabix)  // `meta` is the folder name, `vcf_file` is the VCF file path

    output:
    tuple val(chrom),val(sample_id) , path("*_squirl.vcf")        , emit: squirl_output_vcf
    tuple val(chrom),val(sample_id) , path("*_squirl_initial.vcf")        , emit: squirl_output_vcf_initial
    tuple val(chrom),val(sample_id) , path("*_squirl_initial.tsv")        , emit: squirl_output_tsv
    tuple val(chrom),val(sample_id) , path("*_squirl_initial.html")        , emit: squirl_output_html


    

    shell:
    '''
    echo "Processing VCF file: !{vcf_file} for chromosome !{chrom} family !{sample_id}"
    sh /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/squirl.sh !{vcf_file}
    
    '''
}
