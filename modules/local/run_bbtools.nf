process BBTOOLS {
    container = 'ezlabgva/busco:v5.7.0_cv1'
    
    input:
    path input_path 

    output: 
    path "${params.output}/bbtools_output.txt"

    script:
    """
    python3 ${PWD}/bin/run_bbtools.py -i $input_path
    """
}