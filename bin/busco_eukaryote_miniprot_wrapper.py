#!/usr/bin/env python3

import argparse
import os
import json
import sys
import requests

from busco.analysis.GenomeAnalysis import GenomeAnalysisEukaryotesMiniprot
from busco.BuscoRunner import AnalysisRunner
from busco.BuscoRunner import SingleRunner
from busco.BuscoConfig import BuscoConfigMain
from busco.ConfigManager import BuscoConfigManager

def main(args):
    """
    def run_analysis(self):
        super().run_analysis()
        incomplete_buscos = None
        try:
            self.run_miniprot(incomplete_buscos)
            self.hmmer_runner.miniprot_pipeline = True
            self.gene_details = self.miniprot_align_runner.gene_details
        #     self.run_hmmer(
        #         self.miniprot_align_runner.output_sequences, busco_ids=incomplete_buscos
        #     )
        # except NoRerunFile:
        #     raise NoGenesError("Miniprot")

        # self.hmmer_runner.write_buscos_to_file()
        # self.write_gff_files()
    """
    # Build a config object
    config_manager = config_builder(args)
    print(config_manager.config_main)

    # Pass config to Runner object
    runner = SingleRunner(config_manager)
    runner.run()
    # runner.run_analysis()


def runner():
    pass

def config_builder(args):
    params = {
        "use_miniprot": True,
        "in": args.fasta,
        "cpu": args.cpus,
        "lineage_dataset": args.lineage_db,
        "domain": args.domain,
        "limit": None,
        "offline": True,
        "mode": "genome",
        "out": None,
        "use_augustus": False,
        "augustus_parameters": None,
        "augustus_species": None,
        "auto-lineage": False,
        "auto-lineage-euk": False,
        "auto-lineage-prok": False,
        "config_file": None,
        "contig_break": None,
        "datasets_version": None,
        "download": "==SUPPRESS==",
        "download_base_url": None,
        "download_path": None,
        "evalue": None,
        "force": True,
        "list_datasets": "==SUPPRESS==",
        "long": False,
        "use_metaeuk": False,
        "metaeuk_parameters": None,
        "metaeuk_rerun_parameters": None,
        "skip_bbtools": True,
        "opt-out-run-stats": False,
        "out_path": None,
        "quiet": False,
        "restart": False,
        "scaffold_composition": False,
        "tar": False,
        "version": "==SUPPRESS=="
    }
    manager = BuscoConfigManager(params=params)
    manager.load_busco_config_main()
    return manager


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Description of your program")
    parser.add_argument("-i", "--input", help="Input file")
    parser.add_argument("-o", "--output", help="Output file")
    # Add more arguments as needed

    args = parser.parse_args()

    args.fasta = "test_data/eukaryota/genome.fna"
    args.cpus = 1
    args.lineage_db = "busco_downloads/lineages/eukaryota_odb10"
    args.domain = "eukaryota"

    main(args)
