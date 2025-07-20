process Concat_splicetool_vcfs {

    label 'squirl'
    tag "$sample_id"
	publishDir "${params.outputDir}/${splicedir}/$sample_id", mode: params.saveMode

    input:
    tuple val(sample_id), path (vcf_file)
    val (splicetool)
    val (splicedir)

    output:
    tuple val(sample_id) , path("*_concat.vcf.gz") ,path ("*_concat.vcf.gz.tbi")   , emit: concat_vcf_splicetool
  

    

    shell:
    '''
    ls *.vcf > !{sample_id}_file.txt
    echo "Processing VCF file: !{vcf_file} family !{sample_id}"
    sh /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/concat_chr.sh -V !{sample_id}_file.txt -F !{sample_id}  -T !{splicetool}
    
    '''
}
