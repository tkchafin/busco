#!/usr/bin/env python3

## run_bbtools.py - Python wrapper for BBToolsRunner (see https://gitlab.com/ezlab/busco/-/blob/master/src/busco/busco_tools/bbtools.py?ref_type=heads) 

from busco.busco_tools.bbtools import BBToolsRunner
from busco.BuscoRunner import SingleRunner
from busco.BuscoConfig import BaseConfig
from busco.AutoLineage import AutoSelectLineage

from busco.ConfigManager import BuscoConfigManager

import argparse

'''
def run_bbtools(input_file:str, output_path:str):

    #Set configuration
    config = BaseConfig()
    config.set('busco_run','in',input_file)
    config.set('busco_run','main_out', output_path)
    
    #Set lineage
    #lineage = AutoSelectLineage()

    #Create runner object
    BBToolsRunner.config = config
    bbtools_runner = BBToolsRunner()

    bbtools_runner.configure_runner()
    bbtools_runner.run()
    bbtools_runner.parse_output()
'''

def main(args):
    
    config_manager = config_builder(args)

    runner = run_builder(config_manager)

    run(runner)

def run(runner):
    runner.run()
    runner.parse_output()   

def config_builder(args):
    params = {
        "in": args.fasta,
        "lineage_dataset": args.lineage_db,
        "domain": args.domain,
        "limit": None,
        #"offline": True,
        "mode": "genome",
        "out":f"./results/bbtools",
        "out_path":None,
        "force": True,
        "restart": False
    }
    manager = BuscoConfigManager(params=params)
    manager.load_busco_config_main()

    return manager

def run_builder(config_manager):
    single_runner = SingleRunner(config_manager)

    single_runner.get_lineage()

    BBToolsRunner.config = single_runner.config

    single_runner.runner = BBToolsRunner()

    return single_runner.runner


if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument('-i', '--input', nargs =1, type=str, required=True, help = "Path to input file")
    parser.add_argument('-o', '--output', nargs =1, type=str, required=True, help= "Path to output file")

    args = parser.parse_args()
    
    args.fasta = args.input[0]
    args.cpus = 1
    args.lineage_db = "eukaryota_odb10"
    args.domain = "eukaryota"

    #input_file = args.input[0]
    #output_path = args.output[0]

    main(args)