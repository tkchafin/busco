import subprocess
import argparse

def parse_output(stats_output):
        '''Taken from the BUSCO BBTools module (https://gitlab.com/ezlab/busco/-/blob/master/src/busco/busco_tools/bbtools.py?ref_type=heads)'''

        stats_metrics = dict()

        lines = stats_output.splitlines()

        for line in lines:
            if line.startswith("Main genome scaffold total:"):
                stats_metrics["Number of scaffolds"] = line.split(":")[-1].strip()
            elif line.startswith("Main genome contig total:"):
                stats_metrics["Number of contigs"] = line.split(":")[-1].strip()
            elif line.startswith("Main genome scaffold sequence total:"):
                stats_metrics["Total length"] = line.split(":")[-1].strip()
            elif line.startswith("Main genome contig sequence total:"):
                stats_metrics["Percent gaps"] = (
                    line.split("\t")[-1].strip().strip(" gap")
                )
            elif line.startswith("Main genome scaffold N/L50:"):
                nl50 = line.split(":")[-1].strip().split("/")
                if float(nl50[0].replace(' MB','')) < float(nl50[1].replace(' MB','')):  # The N50/L50 values are inverted. Add a condition so if this is
                    # fixed in bbtools in future versions, it will still work.
                    stats_metrics["Scaffold N50"] = nl50[1].strip()
                else:
                    stats_metrics["Scaffold N50"] = nl50[0].strip()
            elif line.startswith("Main genome contig N/L50:"):
                nl50 = line.split(":")[-1].strip().split("/")
                if float(nl50[0].replace(' MB','')) < float(nl50[1].replace(' MB','')):
                    stats_metrics["Contigs N50"] = nl50[1].strip()
                else:
                    stats_metrics["Contigs N50"] = nl50[0].strip()

        return stats_metrics

def write_tsv(parsed_dict, output_file_name):

    with open(f"{output_file_name}.tsv", mode = 'w') as f:
        for key in parsed_dict.keys():
            f.write(f"{key}\t{parsed_dict[key]}\n")



if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument('-i', '--input', nargs =1, type=str, required=True, help = "Path to input file")
    parser.add_argument('-o', '--output', nargs =1, type=str, required=True, help= "Path to output file")

    args = parser.parse_args()

    input_file = str(args.input[0])
    contig_break = 2

    print(f"Running BBTools Stats with input file {input_file}")
    
    cmd = ['stats.sh',input_file]

    stats_output = subprocess.run(cmd, check = True, text = True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    stats_metrics = parse_output(stats_output.stdout)

    write_tsv(stats_metrics,str(args.output[0]))

