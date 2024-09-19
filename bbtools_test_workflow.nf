include { BBTOOLS } from './modules/local/run_bbtools.nf'

params.input_file = './results/gunzip/GCA_949628265.1.fasta'
params.output_path = './results/bbtools/GCA_949628265.1'

Channel.fromPath(params.input_file).set { input_file_ch }
Channel.fromPath(params.output_path).set { output_path_ch }

workflow {

    out_path = BBTOOLS(input_file_ch, output_path_ch)
    out_path.view{}

}