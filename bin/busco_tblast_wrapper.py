#!/usr/bin/env python

import argparse
import sys

#########################################################################
### Monkey patching GenomeAnalysisEukaryotesMiniprot to only run miniprot
#########################################################################

from busco.analysis.GenomeAnalysis import GenomeAnalysis, GenomeAnalysisEukaryotesAugustus

class Patch_GenomeAnalysisEukaryotesAugustus(GenomeAnalysisEukaryotesAugustus):

    def __init__(self):
        super().__init__()

    def run_analysis(self):
        """This function calls all needed steps for running the analysis."""
        super().run_analysis()
        self._run_mkblast()
        self._run_tblastn()

sys.modules['busco.analysis.GenomeAnalysis'].GenomeAnalysisEukaryotesAugustus = Patch_GenomeAnalysisEukaryotesAugustus

# Import other busco classes
from busco.BuscoRunner import AnalysisRunner
from busco.BuscoRunner import SingleRunner
from busco.ConfigManager import BuscoConfigManager

def main(args):

    # Build a config object
    config_manager = config_builder(args)

    # Pass config to Runner object
    runner = run_builder(config_manager)

    # Run the analysis
    runner.analysis.run_analysis()

def run_builder(config_manager):
    # Set up SingleRunner
    run_wrapper = SingleRunner(config_manager)

    # Complete local config
    run_wrapper.get_lineage()

    # Initialise AnalysisRunner
    run_wrapper.runner = AnalysisRunner(run_wrapper.config)

    return run_wrapper.runner


def config_builder(args):
    # TODO: Need to set this to make BUSCO run the tblastn step above
    params = {
        "use_miniprot": True,
        "in": args.fasta,
        "cpu": args.cpus,
        "lineage_dataset": args.lineage_db,
        "domain": args.domain,
        "limit": None,
        "offline": True,
        "mode": "genome",
        "skip_bbtools": True,
        "out": args.outdir,
        "force": True,
        "restart": False,
    }
    manager = BuscoConfigManager(params=params)
    manager.load_busco_config_main()
    return manager


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Description of your program")
    parser.add_argument("-f", "--fasta", help="FASTA file path", required=True)
    parser.add_argument("-c", "--cpus", type=int, help="Number of CPUs to use", default=1)
    parser.add_argument("-l", "--lineage_db", help="Lineage database path (e.g., busco_downloads/lineages/eukaryota_odb10)", required=True)
    parser.add_argument("-d", "--domain", help="Domain (e.g., eukaryota)", required=False)
    parser.add_argument("-o", "--outdir", help="Output directory", required=False)

    args = parser.parse_args()

    main(args)