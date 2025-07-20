process Pangolin_splice_tool {

    label 'pangolin'
    tag "$sample_id"  // Tag each process by sample_id for easy tracking
    publishDir "${params.outputDir}/pangolin/$sample_id", mode: params.saveMode

    input:
    tuple val(chrom), 
          val(sample_id),
          path(vcf_file), 
          path(tabix), 
          path (assembly_genome), // Reference genome path
          path (database)   // SpliceAI database path


    output:
    tuple val(chrom), val(sample_id), path("*_pangolin.vcf"), emit: pangolin_output  // Output VCF file with annotation

    shell:
    """
    export OMP_NUM_THREADS=!{task.cpus}
    export MKL_NUM_THREADS=!{task.cpus}
    export NUM_THREADS=!{task.cpus}
    
    echo "Processing VCF file for sample: !{sample_id}, VCF file: !{vcf_file}"
    sh /gpfs/projects/tmedicine/Shafiha/Netxflow_pipeline/RNA_seq_analysis/scripts/pangolin.sh -V !{vcf_file} -A !{assembly_genome} -D !{database} -C !{chrom}
    """
}
