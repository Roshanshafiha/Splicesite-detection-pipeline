process Spliceai_splice_tool {

    label 'spliceai'  // Assign label for targeted config     // Each job gets 32 CPUs
    tag "$sample_id"  // Tag each process by sample_id for easy tracking
    publishDir "${params.outputDir}/spliceai/$sample_id", mode: params.saveMode

    
    
    input:
    tuple val(chrom), 
          val(sample_id),
          path(vcf_file), 
          path(tabix), 
          path (reference_genome), // Reference genome path
          path (database)   // SpliceAI database path


    output:
    tuple val(chrom), val(sample_id), path("*_spliceai.vcf"), emit: spliceai_output  // Output VCF file with annotation


    shell:
    """
    export OMP_NUM_THREADS=!{task.cpus}
    export MKL_NUM_THREADS=!{task.cpus}
    export NUM_THREADS=!{task.cpus}

    echo "Processing VCF file for sample: !{sample_id}, VCF file: !{vcf_file}"
    sh /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/spliceai.sh -V !{vcf_file} -R !{reference_genome} -A !{database}
    """
}
