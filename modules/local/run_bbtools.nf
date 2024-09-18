process BBTOOLS {

    input:
    path input_file 
    path output_folder 

    output: 
    path "${output_folder}/bbtools_output"

    script:
    """
    python bin/run_bbtools.py $input_file $output_folder
    """

}