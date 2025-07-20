process Convert_vcf_to_tsv {

    tag "$sample_id"
	publishDir "${params.outputDir}/vcf_to_tsv/$sample_id", mode: params.saveMode

    input:
    tuple val(sample_id), path(reads) , path(tabix)

    output:
    tuple val(sample_id) , path("*_splicetools_annotated.tsv")       , emit: splicetool_output_tsv
    
    

    shell:
    '''
    echo "Processing MND family: !{sample_id}"
    echo "Processing VCF file: !{reads}"

    sh /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/vcf_to_tsv_converter.sh -M !{reads}  -F !{sample_id}
    
    '''
}
