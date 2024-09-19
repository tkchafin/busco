#!/usr/bin/env python

import argparse
import sys

#############################################################################
### Monkey patch GenomeAnalysisEukaryotesMiniprot to only post-miniprot HMMER
#############################################################################

from busco.analysis.GenomeAnalysis import GenomeAnalysis, GenomeAnalysisEukaryotesMiniprot

class Patch_GenomeAnalysisEukaryotesMiniprot(GenomeAnalysisEukaryotesMiniprot):

    def __init__(self):
        super().__init__()

    def run_analysis(self):
        """This function calls all needed steps for running the analysis."""
        print("super")
        GenomeAnalysis.run_analysis(self)
        print("start")
        incomplete_buscos = None
        try:
            print("run_miniprot")
            self.run_miniprot(incomplete_buscos)
            self.hmmer_runner.miniprot_pipeline = True
            print("get_gene_details")
            self.gene_details = self.miniprot_align_runner.gene_details
            print("run_hmmer")
            self.run_hmmer(
                self.miniprot_align_runner.output_sequences, busco_ids=incomplete_buscos
            )
        except NoRerunFile:
            raise NoGenesError("Miniprot")
        print("write_output")
        self.hmmer_runner.write_buscos_to_file()
        self.write_gff_files()
        print("done")

    def run_miniprot(self, incomplete_buscos):
        self.miniprot_index_runner.configure_runner()
        self.miniprot_align_runner.configure_runner(incomplete_buscos)
        self.miniprot_align_runner.parse_output()
        self.miniprot_align_runner.filter()
        self.miniprot_align_runner.record_gene_details()
        # self.miniprot_align_runner.write_protein_sequences_per_busco()

sys.modules['busco.analysis.GenomeAnalysis'].GenomeAnalysisEukaryotesMiniprot = Patch_GenomeAnalysisEukaryotesMiniprot

# Import other busco classes
from busco.BuscoRunner import AnalysisRunner
from busco.BuscoRunner import SingleRunner
from busco.ConfigManager import BuscoConfigManager
from busco.busco_tools.base import NoRerunFile, NoGenesError

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
    params = {
        "use_miniprot": True,
        "in": args.fasta,
        "cpu": args.cpus,
        "lineage_dataset": args.lineage_db,
        "download_path": "./",
        "domain": args.domain,
        "limit": None,
        "offline": True,
        "mode": "genome",
        "skip_bbtools": True,
        "out": args.outdir,
        "force": False,
        "restart": True,
        "tar": args.tar
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
    parser.add_argument("-s", "--source", help="Subworkflow source used to create HMMER inputs", required=True)
    parser.add_argument("--tar", help="Boolean to tar the output", action="store_true")

    args = parser.parse_args()

    main(args)
