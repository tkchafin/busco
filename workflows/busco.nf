/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                                        } from '../modules/nf-core/fastqc/main'
include { MULTIQC                                       } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap                              } from 'plugin/nf-validation'
include { paramsSummaryMultiqc                          } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML                        } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText                        } from '../subworkflows/local/utils_nfcore_busco_pipeline'
include { EUKARYOTE_MINIPROT                            } from '../subworkflows/local/busco_eukaryote'
include { EUKARYOTE_AUGUSTUS                            } from '../subworkflows/local/busco_eukaryote'
include { EUKARYOTE_METAEUK                             } from '../subworkflows/local/busco_eukaryote'

include { NCBIDATASETS_SUMMARYGENOME as SUMMARYGENOME   } from '../modules/local/ncbidatasets/summarygenome'
include { NCBIDATASETS_SUMMARYGENOME as SUMMARYSEQUENCE } from '../modules/local/ncbidatasets/summarygenome'
include { NCBI_GET_ODB                                  } from '../modules/local/ncbidatasets/get_odb'
include { BUSCO_DOWNLOAD                                } from '../modules/local/busco_download'
include { BUSCO_MINIPROT                                } from '../modules/local/busco/eukaryote_miniprot/miniprot'
include { BUSCO_MINIPROT_HMMER                          } from '../modules/local/busco/eukaryote_miniprot/hmmer'
include { BBTOOLS                                       } from '../modules/local/busco/bbtools'



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow BUSCO {

    take:
    ch_fasta // channel: [meta, path/to/fasta]
    lineage_tax_ids        // channel: /path/to/lineage_tax_ids
    lineage_db             // channel: /path/to/buscoDB

    main:

    if (params.lineage == 'eukaryota') {
        BUSCO_EUKARYOTE ()
    } else if (params.lineage == 'prokaryota')  {
        BUSCO_PROKARYOTE ()
    } else {
        error "Invalid value for analysis_mode: ${params.analysis_mode}"
    }

}

workflow BUSCO_EUKARYOTE {
    error "Not implemented"

    take:
    ch_fasta // channel: [meta, path/to/fasta]
    lineage_tax_ids        // channel: /path/to/lineage_tax_ids
    lineage_db             // channel: /path/to/buscoDB

    main:

    ch_versions = Channel.empty()
    //ch_multiqc_files = Channel.empty()


    // Genome summary statistics
    SUMMARYGENOME ( ch_fasta )
    ch_versions = ch_versions.mix ( SUMMARYGENOME.out.versions.first() )


    // Sequence summary statistics
    SUMMARYSEQUENCE ( ch_fasta )
    ch_versions = ch_versions.mix ( SUMMARYSEQUENCE.out.versions.first() )

    // Get ODB lineage value
    NCBI_GET_ODB ( SUMMARYGENOME.out.summary, lineage_tax_ids )
    ch_versions = ch_versions.mix ( NCBI_GET_ODB.out.versions.first() )

    // Format inputs
    NCBI_GET_ODB.out.csv
    | map { meta, csv -> csv }
    | splitCsv()
    | map { row -> row[1] }
    | set { ch_lineage }

    // Download ODB if not already provided
    ch_odb = BUSCO_DOWNLOAD( ch_lineage ).busco_dir.ifEmpty( lineage_db )


    // TODO: Branch here for the different gene predictor options
    // These will eventually be subworkflows e.g., EUKARYOTE_MINIPROT, EUKARYOTE_AUGUSTUS, etc.

    if (params.gene_predictor == 'miniprot') {
        EUKARYOTE_MINIPROT ()
    } else if (params.gene_predictor == 'augustus')  {
        EUKARYOTE_AUGUSTUS ()
    } else if (params.gene_predictor == 'metaeuk')  {
        EUKARYOTE_METAEUK ()
    } else {
        error "Invalid value for gene predictor: ${params.gene_predictor}"
    } 

    // Run BBTools 
    BBTOOLS ( ch_fasta )

    // Run miniprot
    BUSCO_MINIPROT ( ch_fasta, ch_odb )
    ch_versions = ch_versions.mix ( BUSCO_MINIPROT.out.versions.first() )

    // Run HMMER
    BUSCO_MINIPROT_HMMER ( ch_fasta, ch_odb, BUSCO_MINIPROT.out.miniprot_output )
    ch_versions = ch_versions.mix ( BUSCO_MINIPROT.out.versions.first() )

    // TODO: Not sure if we need MultiQC
    // ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    // //
    // // MODULE: MultiQC
    // //
    // ch_multiqc_config        = Channel.fromPath(
    //     "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    // ch_multiqc_custom_config = params.multiqc_config ?
    //     Channel.fromPath(params.multiqc_config, checkIfExists: true) :
    //     Channel.empty()
    // ch_multiqc_logo          = params.multiqc_logo ?
    //     Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
    //     Channel.empty()

    // summary_params      = paramsSummaryMap(
    //     workflow, parameters_schema: "nextflow_schema.json")
    // ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    // ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
    //     file(params.multiqc_methods_description, checkIfExists: true) :
    //     file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    // ch_methods_description                = Channel.value(
    //     methodsDescriptionText(ch_multiqc_custom_methods_description))

    // ch_multiqc_files = ch_multiqc_files.mix(
    //     ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    // ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    // ch_multiqc_files = ch_multiqc_files.mix(
    //     ch_methods_description.collectFile(
    //         name: 'methods_description_mqc.yaml',
    //         sort: true
    //     )
    // )

    // MULTIQC (
    //     ch_multiqc_files.collect(),
    //     ch_multiqc_config.toList(),
    //     ch_multiqc_custom_config.toList(),
    //     ch_multiqc_logo.toList()
    // )

    emit:
    fasta          = ch_fasta                   // channel: [ path/to/fasta ]
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

workflow BUSCO_PROKARYOTE {
    error "Prokaryote pipeline not implemented yet"

    // take:
    // ch_fasta // channel: [meta, path/to/fasta]
    // lineage_tax_ids        // channel: /path/to/lineage_tax_ids
    // lineage_db             // channel: /path/to/buscoDB

    // main:

    // ch_versions = Channel.empty()
    // //ch_multiqc_files = Channel.empty()


    // // Genome summary statistics
    // SUMMARYGENOME ( ch_fasta )
    // ch_versions = ch_versions.mix ( SUMMARYGENOME.out.versions.first() )


    // // Sequence summary statistics
    // SUMMARYSEQUENCE ( ch_fasta )
    // ch_versions = ch_versions.mix ( SUMMARYSEQUENCE.out.versions.first() )


    // // Get ODB lineage value
    // NCBI_GET_ODB ( SUMMARYGENOME.out.summary, lineage_tax_ids )
    // ch_versions = ch_versions.mix ( NCBI_GET_ODB.out.versions.first() )

    // // Format inputs
    // NCBI_GET_ODB.out.csv
    // | map { meta, csv -> csv }
    // | splitCsv()
    // | map { row -> row[1] }
    // | set { ch_lineage }

    // // Download ODB if not already provided
    // ch_odb = BUSCO_DOWNLOAD( ch_lineage ).busco_dir.ifEmpty( lineage_db )

    // // Run PRODIGAL for Prokaryotic gene prediction
    // PRODIGAL ()

    // // Run BBTools 
    // BBTOOLS ( ch_fasta )

    // // Run miniprot (Necessary in prokaryote mode?)
    // BUSCO_MINIPROT ( ch_fasta, ch_odb )
    // ch_versions = ch_versions.mix ( BUSCO_MINIPROT.out.versions.first() )

    // // Run HMMER
    // BUSCO_MINIPROT_HMMER ( ch_fasta, ch_odb, BUSCO_MINIPROT.out.miniprot_output )
    // ch_versions = ch_versions.mix ( BUSCO_MINIPROT.out.versions.first() )

    // // TODO: Not sure if we need MultiQC
    // // ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    // //
    // // Collate and save software versions
    // //
    // softwareVersionsToYAML(ch_versions)
    //     .collectFile(
    //         storeDir: "${params.outdir}/pipeline_info",
    //         name: 'nf_core_pipeline_software_mqc_versions.yml',
    //         sort: true,
    //         newLine: true
    //     ).set { ch_collated_versions }

    // // //
    // // // MODULE: MultiQC
    // // //
    // // ch_multiqc_config        = Channel.fromPath(
    // //     "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    // // ch_multiqc_custom_config = params.multiqc_config ?
    // //     Channel.fromPath(params.multiqc_config, checkIfExists: true) :
    // //     Channel.empty()
    // // ch_multiqc_logo          = params.multiqc_logo ?
    // //     Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
    // //     Channel.empty()

    // // summary_params      = paramsSummaryMap(
    // //     workflow, parameters_schema: "nextflow_schema.json")
    // // ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    // // ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
    // //     file(params.multiqc_methods_description, checkIfExists: true) :
    // //     file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    // // ch_methods_description                = Channel.value(
    // //     methodsDescriptionText(ch_multiqc_custom_methods_description))

    // // ch_multiqc_files = ch_multiqc_files.mix(
    // //     ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    // // ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    // // ch_multiqc_files = ch_multiqc_files.mix(
    // //     ch_methods_description.collectFile(
    // //         name: 'methods_description_mqc.yaml',
    // //         sort: true
    // //     )
    // // )

    // // MULTIQC (
    // //     ch_multiqc_files.collect(),
    // //     ch_multiqc_config.toList(),
    // //     ch_multiqc_custom_config.toList(),
    // //     ch_multiqc_logo.toList()
    // // )

    // emit:
    // fasta          = ch_fasta                   // channel: [ path/to/fasta ]
    // versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
