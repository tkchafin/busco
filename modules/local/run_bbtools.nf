process BBTOOLS {
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/busco:5.7.1--pyhdfd78af_0':
        'biocontainers/busco:5.7.1--pyhdfd78af_0' }"
    
    input:
    path input_file 
    path output_file

    output: 
    path "${output_file}.tsv"

    script:
    """
    python3 ${PWD}/bin/run_bbtools.py -i $input_file -o $output_file
    """
}