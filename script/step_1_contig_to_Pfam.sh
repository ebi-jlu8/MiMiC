#Metagenome pipeline.
#Neeraj Kumar
#last update Feb 2021
#use : bash metagenome_pipeline.sh
#
# updates by JLu Oct 2024
#*********************************************#
#tools requirement :

#for MGnify internal use, used prodigal from singularity and Hmmr from hps.
#3.Prodigal
#4.Hmmer
#5.Pfam database

#******* Usage ******************************************

# bash step_1_contig_to_Pfam.sh -h
# bash step_1_contig_to_Pfam.sh -i PathToInputFolder -d PathToPfamDatabase -t optionforProdigal(meta or single)  

#*************** making option for the user to pass the arguments from command line **********

	if [ "$1" == "-h" ]; then
		echo -e "\n\n"
		echo -e "********  Usage ***********************\n\n"
		echo -e "Usage: bash step_1_contig_to_Pfam.sh -i PathToInputFolder -d PathToPfamDatabase -t optionforProdigal(meta or single)\n\n"
		echo -e "[options]\n"		
		echo -e "	-i : this is the path for genome or metagenome assembly folder to be annotated"
		echo -e "	-d : this is the folder for hmmpress pfam database"
		echo -e "	-t : this provides an option to prodigal to be in metagenomic mode or single genome mode mode\n\n"
		exit 0
	fi

	while getopts i:d:t: flag
		do
		    case "${flag}" in
		        i) input_fna=${OPTARG};;
		        d) PfamPath=${OPTARG};;
		        t) Type=${OPTARG};;
		    esac
		done


# Check if any required arguments are missing
if [ -z "$input_fna" ] || [ -z "$PfamPath" ] || [ -z "$Type" ]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 -i <input_fna> -d <PfamPath> -t <Type>"
    exit 1
fi

#****** creating directory for output ***************************

if [ ! -d output_faa ]; then
  mkdir output_faa
fi
if [ ! -d output_pfam ]; then
  mkdir output_pfam
fi
if [ ! -d output_fna ]; then
  mkdir output_fna
fi

#******************  path for tools *****************************************
#Prodigal
ProdigalPath_cmd="singularity exec $SINGULARITY_CACHEDIR/quay.io_microbiome-informatics_prodigal:2.6.3.sif prodigal" 
#hmmscan
hmmscanPath=/hps/software/users/rdf/metagenomics/service-team/software/hmmer/3.4/hmmscan

# running script for each genome or metagenome

for i in $input_fna/*.fna;  
		do
    # Extract the base filename without suffix and extension
    filename=$(basename "$i")          # Get the file name
    sample_name=$(echo "$filename" | sed 's/.fna//')  # Remove the suffix (_R1 or _R2) and the .fna extension
    echo "$filename"

#prodigal --> gene prediction
			$ProdigalPath_cmd  -i $input_fna/"$filename" -p $Type -a output_faa/"$sample_name".faa -c -m -q -f sco -d output_fna/"$sample_name".fna	
			echo "$i	prodigal finished">>output_faa/Prodigal.log
			ProteinCount=$(grep -c "^" output_faa/'$sample_name'.faa) #-------------- Counting proteins
		
			echo -e "'$i'\t$ProteinCount" >> output_faa/protein_Count.txt 
			echo "$i	hmmscan started">>output_pfam/hmmscan.log

#hmmscan ----> pfam prediction
	
			$hmmscanPath --cpu 20 --acc --noali --cut_ga --tblout  output_pfam/$i.faa.table_results $PfamPath/Pfam-A_2019.hmm   output_faa/$i.faa
			echo "$i	hmmscan finished" >> output_pfam/hmmscan.log

		done

echo -e "processing is finished \n\n" 
#Reference
#Prodigal
#2.Hyatt D, Chen GL, Locascio PF, Land ML, Larimer FW, Hauser LJ. Prodigal:
#prokaryotic gene recognition and translation initiation site identification. BMC 
#Bioinformatics. 2010 Mar 8;11:119. doi: 10.1186/1471-2105-11-119. PubMed PMID:
#20211023; PubMed Central PMCID: PMC2848648.

#Hmmscan

#http://hmmer.org/






