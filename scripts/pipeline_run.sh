#!/bin/bash
# pipeline_run.sh
# https://github.com/PauloSchreiner/yeast_genome_assembly 


###### --- INITIALIZE PIPELINE --- ######
set -euo pipefail  # Strict error handling

# Color setup (aesthetic purposes)
if [ -t 1 ]; then
    export RED='\033[0;31m' GREEN='\033[0;32m' CYAN='\033[0;36m' BLUE='\033[0;34m' PURPLE='\033[0;35m' ORANGE='\033[38;5;208m' NC='\033[0m'
else 
    export RED='' GREEN='' CYAN='' BLUE='' NC='' PURPLE='' ORANGE=''
fi


# Set up directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")" 
TOOL_DATA_DIR="$PROJECT_ROOT/tool_data" # Centralized tool data directory
export BUSCO_CONFIG_FILE="$TOOL_DATA_DIR/busco/config.ini" # Necessary for BUSCO
export BUSCO_DOWNLOADS_PATH="$TOOL_DATA_DIR/busco/downloads"


# Create timestamped run directory within /output/
RUN_DIR="$PROJECT_ROOT/output/run_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RUN_DIR"


# Set up logging into the run directory
RUN_LOG_DIR="$RUN_DIR/log"
mkdir -p "$RUN_LOG_DIR"
exec > >(tee -a "$RUN_LOG_DIR/pipeline_$(date +%Y%m%d).log") 2>&1

echo -e "${GREEN}=== Pipeline started $(date) ==="
echo -e "${BLUE}Project root:${CYAN} $PROJECT_ROOT ${NC}"


# Load configuration
CONFIG_FILE="$PROJECT_ROOT/config/config.yaml"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}ERROR: Config file missing at${NC} $CONFIG_FILE"
    exit 1
fi


# Parse config
THREADS=$(grep '^threads:' "$CONFIG_FILE" | awk '{print $2}')
RAM_PERCENTAGE=$(grep '^ram_percentage:' "$CONFIG_FILE" | awk '{print $2}')
GENOMES_DIR="$PROJECT_ROOT/input/$(grep '^genomes_dir:' "$CONFIG_FILE" | awk '{print $2}')"
REFERENCE="$PROJECT_ROOT/input/$(grep '^reference:' "$CONFIG_FILE" | awk '{print $2}')"
BUSCO_LINEAGE=$(grep '^busco_lineage:' "$CONFIG_FILE" | awk '{print $2}')


# Validate critical paths
if [[ ! -d "$GENOMES_DIR" ]]; then
    echo -e "${RED}ERROR: Genomes directory missing: $GENOMES_DIR"
    exit 1
fi

if [[ ! -f "$REFERENCE" ]]; then
    echo -e "${RED}ERROR: Reference genome missing: $REFERENCE"
    exit 1
fi





###### --- PIPELINE FUNCTIONS --- ######
run_command() {
    local step=$1
    local cmd=$2
    
    # Print colored header
    echo -e "${BLUE}=== RUNNING ${PURPLE}$step${BLUE} ===${NC}"
    # Clean and print command (collapse multiple spaces, keep single spaces)
    local cleaned_cmd=$(echo "$cmd" | tr -s ' ' | sed 's/^ *//;s/ *$//')
    echo -e "${CYAN}Command:${NC} $cleaned_cmd"
    
    # Execute command 
    if eval "$cmd"; then
        echo -e "${GREEN}=== COMPLETED $step ===${NC}"
    else
        echo -e "${RED}!!! FAILED $step !!!${NC}"
        exit 1
    fi
}




###### --- MAIN PIPELINE LOOP --- ######

for genome_dir in "$GENOMES_DIR"/*/; do
    genome=$(basename "$genome_dir")
    echo -e "${ORANGE}=== PROCESSING $genome === ${NC}"
    
    # Find R1/R2 files (any prefix, must end with 1.fq.gz/2.fq.gz)
    shopt -s nullglob  # Ignore failed wildcards
    R1=("$genome_dir"/*1.fq.gz)
    R2=("$genome_dir"/*2.fq.gz)
    shopt -u nullglob  # Reset shell option
    # Validate exactly one R1/R2 pair exists
    if [[ ${#R1[@]} -eq 1 && ${#R2[@]} -eq 1 ]]; then
        echo -e "${BLUE}Read pair selected: ${NC}"
        echo -e "${GREEN}  R1:${CYAN} $(basename "${R1[0]}") ${NC}"
        echo -e "${GREEN}  R2:${CYAN} $(basename "${R2[0]}") ${NC}"
    else
        echo -e "${RED}ERROR: Could not find exactly one R1/R2 pair in $genome_dir ${NC}"
        [[ ${#R1[@]} -ne 1 ]] && echo "  Found ${#R1[@]} R1 files (*1.fq.gz)"
        [[ ${#R2[@]} -ne 1 ]] && echo "  Found ${#R2[@]} R2 files (*2.fq.gz)"
        exit 1
    fi

    # Create output directories
    OUTDIR="$RUN_DIR/$genome"
    mkdir -p "$OUTDIR"/{1_fastp,3_ragtag,4_busco,5_quast} # Do not create /2_megahit/ in this step - it is created automatically when running megahit

    # 1. Read trimming with fastp
    run_command "FASTP" \
        "fastp --in1 '$R1' --in2 '$R2' \
              --out1 '$OUTDIR/1_fastp/clean_R1.fq.gz' \
              --out2 '$OUTDIR/1_fastp/clean_R2.fq.gz' \
              --trim_poly_x --correction \
              --html '$OUTDIR/1_fastp/report.html' \
              --json '$OUTDIR/1_fastp/report.json' \
              --thread $THREADS"

    # 2. Assembly with MEGAHIT
    run_command "MEGAHIT" \
        "megahit -1 '$OUTDIR/1_fastp/clean_R1.fq.gz' \
                -2 '$OUTDIR/1_fastp/clean_R2.fq.gz' \
                -o '$OUTDIR/2_megahit' \
                -t $THREADS \
                --memory $RAM_PERCENTAGE"

    # 3. Correcting, scaffolding and patching with RagTag
    run_command "RAGTAG" \
        "ragtag.py correct '$REFERENCE' '$OUTDIR/2_megahit/final.contigs.fa' \
                -o '$OUTDIR/3_ragtag' \
                -t $THREADS"

    run_command "RAGTAG" \
        "ragtag.py scaffold '$REFERENCE' '$OUTDIR/3_ragtag/ragtag.correct.fasta' \
                -o '$OUTDIR/3_ragtag' \
                -t $THREADS" 

    run_command "RAGTAG" \
        "ragtag.py patch '$REFERENCE' '$OUTDIR/3_ragtag/ragtag.scaffold.fasta' \
                -o '$OUTDIR/3_ragtag' \
                -t $THREADS"

    # 4. Completeness assessment with BUSCO
    run_command "BUSCO" \
        "busco -i '$OUTDIR/3_ragtag/ragtag.patch.fasta' \
              -o 'busco_results' \
              -l '$BUSCO_LINEAGE' \
              -m genome -c $THREADS \
              --out_path '$OUTDIR/4_busco'"
    
    # 5. Quality assessment with QUAST
    run_command "QUAST" \
        "quast.py '$OUTDIR/3_ragtag/ragtag.patch.fasta' \
                 -o '$OUTDIR/5_quast' \
                 --threads $THREADS" 


done

echo -e "${GREEN}=== Pipeline completed successfully! === ${NC}"
echo -e "${BLUE}Results in: $RUN_DIR ${NC}"
echo -e "${CYAN} Log file: $RUN_DIR/pipeline_$(date +%Y%m%d).log ${NC}"
