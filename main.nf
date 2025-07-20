//  RNA seq pipeline 
// 
nextflow.enable.dsl=2
//parameters to change 


// these paramters can be accessed within the command line 
//  example run can include 
params.saveMode = 'copy'
//params.metadata = "$projectDir/"
params.inputDir = "$projectDir/input_data/"
params.outputDir = "$projectDir/pipeline-output/"
params.workDir = "$projectDir/work/"
params.runType = 'execution'
params.reads   = "$projectDir/input_data/MND-*/MND-*.vcf.gz" 

//parameters for splice tool run based on genome assembly used 

params.spliceai_annotation = ""
params.spliceai_ref_genome = ""

params.pangolin_assembly_genome=""
params.pangolin_db=""

params.bedfile=""
params.splicevardb=""
params.splicevardb_index=""

params.genepanel = ""
params.genepanel_index = ""
params.genepanel_header = ""



log.info """\
    RNA sequence pipeline
    =============================
    Inputs: ${params.inputDir}
    Outputs: ${params.outputDir}
    WorkDir: ${params.workDir}
""".stripIndent()


include{ Bcftools_initial_filtering } from './process/bcftools'
include{ Extract_chr_pos } from './process/extract_chr'
include{ Squirl_splice_tool } from './process/squirl'
include{ Spliceai_splice_tool } from './process/spliceai'
include{ Pangolin_splice_tool } from './process/pangolin'
include{ Update_score_spliceai } from './process/update_score_spliceai'
include{ Update_score_pangolin } from './process/update_score_pangolin'
include{ Concat_splicetool_vcfs } from './process/concat_vcf'
include { Concat_splicetool_vcfs as Concat_squirl_vcfs } from './process/concat_vcf'
include { Concat_splicetool_vcfs as Concat_spliceai_vcfs } from './process/concat_vcf'
include { Concat_splicetool_vcfs as Concat_pangolin_vcfs } from './process/concat_vcf'
include { Merge_vcf_annotations } from './process/annotate_vcf'
include { Convert_vcf_to_tsv } from './process/vcf_to_tsv'





workflow {



    //annotations and databases to run splice tools 
    
    spliceai_ref_genome=Channel.fromPath(params.spliceai_ref_genome, checkIfExists: true)
    spliceai_db=Channel.fromPath(params.spliceai_annotation, checkIfExists: true)
    
    //assembly genome and database to run pangolin 
    pangolin_assembly_genome=Channel.fromPath(params.pangolin_assembly_genome, checkIfExists: true)
    pangolin_db=Channel.fromPath(params.pangolin_db, checkIfExists: true)

    //bedfile for filtering 
    coding_region_bedfile=Channel.fromPath(params.bedfile, checkIfExists: true)

    //splicevardb 

    splicevardb_annotation_file=Channel.fromPath(params.splicevardb, checkIfExists: true)
    splicevardb_index_file=Channel.fromPath(params.splicevardb_index, checkIfExists: true)

    //Genomics England gene panel file 
    genepanel=Channel.fromPath(params.genepanel, checkIfExists: true)
    genepanel_index=Channel.fromPath(params.genepanel_index, checkIfExists: true)
    genepanel_header=Channel.fromPath(params.genepanel_header, checkIfExists: true)

    //extract each vcf file 
    Channel.fromPath(params.reads)\
        |map { file -> 
            def sample_id = file.getName().tokenize('.')[0]
            tuple(sample_id, file)
        }\
        |set {vcf_files }
       
    // Combine the bedfile with each VCF file tuple
    vcf_files\
        |combine(coding_region_bedfile)
        |set { vcf_bed_combined }

    vcf_bed_combined.view()

    //bcftool initial filtering step
    Bcftools_initial_filtering(vcf_bed_combined)
    

    //split the vcf file by each chromosome position 
    chromosomes_ch = Channel.of(1..22, "X", "Y")

    chromosomes_ch\
    |combine(Bcftools_initial_filtering.out.input_splicetool_file)\
    |Extract_chr_pos.collect()\
    |set{splice_tool_input}

    //spliceai annotation

    splice_tool_input\
    | combine(spliceai_ref_genome)\
    | combine(spliceai_db)\
    | Spliceai_splice_tool.collect()\
    | set{spliceai_updatescore}


    //update spliceai score
    Update_score_spliceai(spliceai_updatescore)


    //squirl annotation
    splice_tool_input\
    |Squirl_splice_tool

    //pangolin annotation
    splice_tool_input\
    | combine(pangolin_assembly_genome)\
    | combine(pangolin_db)\
    |Pangolin_splice_tool.collect()\
    | set{pangolin_updatescore}

    //update pangolin score
    Update_score_pangolin(pangolin_updatescore)
    
    //prepare file for concatenation step
    //Squirl

    Squirl_splice_tool.out.squirl_output_vcf\
    |map { file -> 
        def sample_id = file[1]  // Extract sample_id from the tuple
        def vcf_file = file[2]   // Extract the VCF file path
        tuple(sample_id, vcf_file)  // Return as tuple with sample_id and VCF file path
    }\
    |groupTuple(by: 0)\
    |set {squirl_concat_vcf_input}

    //Pangolin

    Update_score_pangolin.out.pangolin_output\
    |map { file -> 
        def sample_id = file[1]  // Extract sample_id from the tuple
        def vcf_file = file[2]   // Extract the VCF file path
        tuple(sample_id, vcf_file)  // Return as tuple with sample_id and VCF file path
    }\
    |groupTuple(by: 0)\
    |set {pangolin_concat_vcf_input}


    //Spliceai

    Update_score_spliceai.out.spliceai_output\
    |map { file -> 
        def sample_id = file[1]  // Extract sample_id from the tuple
        def vcf_file = file[2]   // Extract the VCF file path
        tuple(sample_id, vcf_file)  // Return as tuple with sample_id and VCF file path
    }\
    |groupTuple(by: 0)\
    |set {spliceai_concat_vcf_input} 

    
    println 'concatenation of VCF begains for splice tools'

    // Capture emitted channels
    squirl_vcf_channel = Concat_squirl_vcfs(squirl_concat_vcf_input, splicetool =  "squirl", splicetool_dir =  "squirl_concat_vcf")
    pangolin_vcf_channel = Concat_pangolin_vcfs(pangolin_concat_vcf_input, splicetool = "pangolin", splicetool_dir = "pangolin_concat_vcf")
    spliceai_vcf_channel = Concat_spliceai_vcfs(spliceai_concat_vcf_input, splicetool = "spliceai", splicetool_dir = "spliceai_concat_vcf")



    squirl_vcf_channel.concat_vcf_splicetool
    | mix( pangolin_vcf_channel.concat_vcf_splicetool,spliceai_vcf_channel.concat_vcf_splicetool, Bcftools_initial_filtering.out.initial_filter_file ,Bcftools_initial_filtering.out.initial_filter_tabix_file )
    | groupTuple( by: 0 )
    | combine(splicevardb_annotation_file)
    | combine(splicevardb_index_file)
    | combine(genepanel)
    | combine(genepanel_index)
    | combine(genepanel_header)
    | set {all_vcf_combined_channel}


    all_vcf_combined_channel.view()
    Merge_vcf_annotations(all_vcf_combined_channel)
    Convert_vcf_to_tsv(Merge_vcf_annotations.out.splicetool_output_vcf)


}


workflow.onComplete {
    log.info ( workflow.success ? "Completed!" : "Error" )
}