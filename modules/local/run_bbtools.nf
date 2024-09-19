process BBTOOLS {

    input:
    path input_path 

    output: 
    path "${params.output}/bbtools_output.txt"

    script:
    """
    run_bbtools.py $input_path
    """
}