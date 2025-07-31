#!/bin/bash
# yeast_genome_assembly_pipeline.sh
# Full pipeline prototype with:
# - Project-root-relative paths
# - Comprehensive logging
# - Input validation
# - Error handling
# - Config file support


### --- Initialize Pipeline --- ###
set -euo pipefail  # Strict error handling

# 0. Set up directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 1. Set up logging
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/pipeline_$(date +%Y%m%d).log") 2>&1

echo "=== Pipeline started $(date) ==="
echo "Project root: $PROJECT_ROOT"

# 2. Load configuration
CONFIG_FILE="$PROJECT_ROOT/config.yaml"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Config file missing at $CONFIG_FILE"
    exit 1
fi

# Parse config
THREADS=$(grep '^threads:' "$CONFIG_FILE" | awk '{print $2}')
RAM_PERCENTAGE=$(grep '^ram_percentage:' "$CONFIG_FILE" | awk '{print $2}')
GENOMES_DIR="$PROJECT_ROOT/$(grep '^genomes_dir:' "$CONFIG_FILE" | awk '{print $2}')"
BUSCO_LINEAGE=$(grep '^busco_lineage:' "$CONFIG_FILE" | awk '{print $2}')
REFERENCE="$PROJECT_ROOT/$(grep '^reference:' "$CONFIG_FILE" | awk '{print $2}')"

# 3. Validate critical paths
if [[ ! -d "$GENOMES_DIR" ]]; then
    echo "ERROR: Genomes directory missing: $GENOMES_DIR"
    exit 1
fi

if [[ ! -f "$REFERENCE" ]]; then
    echo "ERROR: Reference genome missing: $REFERENCE"
    exit 1
fi

# 4. Enable color support (aesthetic purposes only)
if [ -t 1 ]; then
    export TERM=xterm-256color
fi



### --- Pipeline Functions --- ###
run_command() {
    # Color definitions
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'  
    local BLUE='\033[0;34m'
    local NC='\033[0m' # No Color

    local step=$1
    local cmd=$2
    
    # Print colored header
    echo -e "${BLUE}=== RUNNING ${CYAN}$step${BLUE} ===${NC}"
    # Clean and print command (collapse multiple spaces, keep single spaces)
    local cleaned_cmd=$(echo "$cmd" | tr -s ' ' | sed 's/^ *//;s/ *$//')
    echo -e "${BLUE}Command:${NC} ${CYAN}$cleaned_cmd${NC}"
    
    # Execute command 
    if eval "$cmd"; then
        echo -e "${GREEN}=== COMPLETED $step ===${NC}"
    else
        echo -e "${RED}!!! FAILED $step !!!${NC}"
        exit 1
    fi
}



### --- Main Pipeline --- ###
# Create timestamped results directory
RUN_DIR="$PROJECT_ROOT/results/run_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RUN_DIR"


# Process each genome
for genome_dir in "$GENOMES_DIR"/*; do
    genome=$(basename "$genome_dir")
    echo "=== PROCESSING $genome ==="
    
    # Find R1/R2 files (any prefix, must end with 1.fq.gz/2.fq.gz)
    shopt -s nullglob  # Ignore failed wildcards
    R1=("$genome_dir"/*1.fq.gz)
    R2=("$genome_dir"/*2.fq.gz)
    shopt -u nullglob  # Reset shell option
    # Validate exactly one R1/R2 pair exists
    if [[ ${#R1[@]} -eq 1 && ${#R2[@]} -eq 1 ]]; then
        echo "Read pair selected:"
        echo "  R1: $(basename "${R1[0]}")"
        echo "  R2: $(basename "${R2[0]}")"
    else
        echo "ERROR: Could not find exactly one R1/R2 pair in $genome_dir"
        [[ ${#R1[@]} -ne 1 ]] && echo "  Found ${#R1[@]} R1 files (*1.fq.gz)"
        [[ ${#R2[@]} -ne 1 ]] && echo "  Found ${#R2[@]} R2 files (*2.fq.gz)"
        exit 1
    fi

    # Create output directories
    OUTDIR="$RUN_DIR/$genome"
    mkdir -p "$OUTDIR"/{1_fastp,3_ragtag,4_busco,5_quast}

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

    # 4. Completeness assessment with BUSCO and quality assessment with QUAST (in parallel)
    run_command "BUSCO" \
        "busco -i '$OUTDIR/3_ragtag/ragtag.patch.fasta' \
              -o '$OUTDIR/4_busco' \
              -l '$BUSCO_LINEAGE' \
              -m genome -c $THREADS" 
    busco_pid=$!  # Store process ID
    
    # 5. Quality assessment with QUAST
    run_command "QUAST" \
        "quast.py '$OUTDIR/3_ragtag/ragtag.patch.fasta' \
                 -o '$OUTDIR/5_quast' \
                 --threads $THREADS" 
    quast_pid=$!  # Store process ID

    wait $busco_pid $quast_pid  # Wait for both processes specifically
    
done

echo "=== Pipeline completed successfully! ==="
echo "Results in: $RUN_DIR"
echo "Log file: $LOG_DIR/pipeline_$(date +%Y%m%d).log"
