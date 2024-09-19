include { BBTOOLS } from './modules/local/run_bbtools.nf'

params.input_file = './results/gunzip/GCA_949628265.1.fasta'
// params.output_folder = './results'

Channel.fromPath(params.input_file).set { input_file_ch }
//Channel.fromPath(params.output_folder).set { output_path_ch }

workflow {

    BBTOOLS(input_file_ch)

}