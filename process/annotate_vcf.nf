process Merge_vcf_annotations {

    tag "$sample_id"
	publishDir "${params.outputDir}/annotated_vcf_final/$sample_id", mode: params.saveMode

    input:
    tuple val(sample_id), file(reads) , file (tabix), path(splicevardb), path (splicevardb_index) , path (genepanel) , path (genepanel_index) , path (genepanel_header)

    output:
    tuple val(sample_id) , path("*_splicetools_annotated.vcf.gz")  ,path ("*_splicetools_annotated.vcf.gz.tbi")      , emit: splicetool_output_vcf
    
    

    shell:
    '''
    echo "Processing MND family: !{sample_id}"
    echo "Processing VCF file: !{reads}"
    echo "Processing tabix file: !{tabix}"
    echo "splicevardb file: !{splicevardb}"
    sh /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/annotate_vcf.sh -M !{sample_id}_filtered.vcf.gz -s !{sample_id}_squirl_concat.vcf.gz -p !{sample_id}_pangolin_concat.vcf.gz -a !{sample_id}_spliceai_concat.vcf.gz  -F !{sample_id} -v !{splicevardb} -g !{genepanel} -H !{genepanel_header}
    
    '''
}
