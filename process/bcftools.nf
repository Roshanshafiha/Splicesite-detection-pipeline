process Bcftools_initial_filtering {

    tag "$sample_id"
	publishDir "${params.outputDir}/bcftool_filtering/$sample_id", mode: params.saveMode

    input:
    tuple val(sample_id),path(reads) ,path(bedfile) // `meta` is the folder name, `vcf_file` is the VCF file path


    output:
    tuple val(sample_id),path("*_id.txt")                , emit: sample_id_txt
    tuple val(sample_id),path("*_filtered.vcf.gz")        , emit: initial_filter_file
    tuple val(sample_id),path("*_input_splicetool.vcf.gz"),path("*_input_splicetool.vcf.gz.tbi")   , emit: input_splicetool_file
    //tuple val(sample_id),path("*_input_splicetool.vcf.gz.tbi")    , emit: input_splicetool_tabix_file
    tuple val(sample_id),path("*_filtered.vcf.gz.tbi")    , emit: initial_filter_tabix_file

    shell:
    '''
    echo "Processing VCF file: !{reads}"
    echo "bedfile used : !{bedfile}"
    sh /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/initial_filtering.sh !{reads} !{bedfile}
    
    '''
}
