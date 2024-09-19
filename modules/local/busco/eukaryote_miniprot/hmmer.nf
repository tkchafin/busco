process BUSCO_MINIPROT_HMMER {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/busco:5.7.1--pyhdfd78af_0':
        'biocontainers/busco:5.7.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)        // tuple: meta, fasta
    path(lineage_db)                    // /path/to/lineage_db
    path(miniprot_output)               // /path/to/miniprot_output

    output:
    path("${meta.id}/run_*/miniprot_output")         , emit: miniprot_output
    path("${meta.id}/logs")                          , emit: logs
    path("${meta.id}/run_*/full_table.tsv")          , emit: full_table
    path("${meta.id}/run_*/missing_busco_list.tsv")  , emit: missing_busco_list
    path("${meta.id}/run_*/hmmer_output")            , emit: hmmer_output
    path("${meta.id}/run_*/busco_sequences")         , emit: busco_sequences
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # Set up run directory
    mkdir -p ${prefix}/run_${lineage_db}/miniprot_output

    # Get the target of the existing symbolic link
    target=\$(realpath ./${miniprot_output})

    # IMPORTANT: HMMER must be getting the real GFF file, not a link
    # Create a new symbolic link to the same target at the desired location
    cp -r \$target ${prefix}/run_${lineage_db}

    busco_miniprot_hmmer_wrapper.py \\
        -f $fasta \\
        -c $task.cpus \\
        -l "./"$lineage_db \\
        -o $prefix \\
        -d ${params.domain} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        busco: \$( busco --version 2>&1 | sed 's/^BUSCO //' )
        hmmer: \$( hmmsearch -h | grep -m 1 'HMMER' | awk '{print \$3}' )
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${meta.id}/logs
    touch ${meta.id}/run_stub/full_table.tsv
    touch ${meta.id}/run_stub/missing_busco_list.tsv
    mkdir -p ${meta.id}/run_stub/hmmer_output
    mkdir -p ${meta.id}/run_stub/busco_sequences

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        busco: \$( busco --version 2>&1 | sed 's/^BUSCO //' )
        hmmer: \$( hmmsearch -h | grep -m 1 'HMMER' | awk '{print \$3}' )
    END_VERSIONS
    """
}
