## run_bbtools.py - Python wrapper for BBToolsRunner (see https://gitlab.com/ezlab/busco/-/blob/master/src/busco/busco_tools/bbtools.py?ref_type=heads) 

from busco.busco_tools.bbtools import BBToolsRunner
import argparse

def run_bbtools(input_file:str, output_file:str):

    bbtools_runner = BBToolsRunner()

    bbtools_runner.input_file = input_file
    bbtools_runner.output_file = output_file

    bbtools_runner.configure_runner()

    bbtools_runner.run()

    bbtools_runner.parse_output()

    print(bbtools_runner.metrics, file = bbtools_runner.output_file)

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument('-i', '--input', nargs =1, type=str)
    parser.add_argument('-o', '--output', nargs =1, type=str)

    args = parser.parse_args()

    input_file = args.input[0]
    output_file = args.input[0]

    print(f"Running run_bbtools.py with input {input_file} and output {output_file}")

    #run_bbtools()