process BBTOOLS {
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/busco:5.7.1--pyhdfd78af_0':
        'biocontainers/busco:5.7.1--pyhdfd78af_0' }"
    
    input:
    tuple val(_), path(fasta_path) 

    script:
    def output_file = "${fasta_path.toString().split('/')[-1].replaceFirst(/\.fasta$/,'')}_stats_output"
    
    """
    python3 ${PWD}/bin/run_bbtools.py -i ${fasta_path} -o ${output_file}
    """
}