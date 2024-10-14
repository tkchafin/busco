process BUSCO_MINIPROT {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/busco:5.7.1--pyhdfd78af_0':
        'biocontainers/busco:5.7.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)        // tuple: meta, fasta
    path(lineage_db)                    // /path/to/lineage_db

    output:
    path("${meta.id}/run_*/miniprot_output")         , emit: miniprot_output
    path("${meta.id}/run_*")                         , emit: base_output
    path("${meta.id}/logs")                          , emit: logs
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    busco_miniprot_wrapper.py \\
        -f $fasta \\
        -c $task.cpus \\
        -l "./"$lineage_db \\
        -o $prefix \\
        -d ${params.domain} \\
        $args

    # Replace GFF symlink with real file
    gff=\$(realpath ${prefix}/run_${lineage_db}/miniprot_output/*.gff)
    target=\$(find ${prefix}/run_${lineage_db}/miniprot_output -name "*.gff")
    cp --remove-destination \$gff \$target

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        busco: \$( busco --version 2>&1 | sed 's/^BUSCO //' )
        miniprot: \$( miniprot --version 2>&1  )
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${meta.id}/run_stub/miniprot_output
    mkdir -p ${meta.id}/logs

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        busco: \$( busco --version 2>&1 | sed 's/^BUSCO //' )
        miniprot: \$( miniprot --version 2>&1  )
    END_VERSIONS
    """
}
