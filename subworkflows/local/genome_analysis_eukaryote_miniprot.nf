//
// Align short read (HiC and Illumina) data against the genome
//

//include { SAMTOOLS_FASTQ                      } from '../../modules/nf-core/samtools/fastq/main'


workflow GENOME_ANALYSIS_EUKARYOTE_MINIPROT {
    take:
    fasta    // channel: [ val(meta), /path/to/fasta ]


    main:
    ch_versions = Channel.empty()


    emit:
    versions = ch_versions                   // channel: [ versions.yml ]
}
