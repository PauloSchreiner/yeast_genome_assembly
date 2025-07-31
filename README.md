# Yeast Genome Assembly Pipeline
*A reproducible workflow for assembling yeast genomes using FASTP, MEGAHIT, RAGTAG, BUSCO and QUAST*  

---

## Overview  
Automated pipeline for:  
- Quality control of Illumina reads (FASTP)  
- Genome assembly (MEGAHIT)  
- Reference-guided scaffolding (RagTag)  
- Completeness assessment (BUSCO)  
- Assembly metrics (QUAST)  

**Target Users**: Bioinformaticians and yeast researchers.  
**Key Tools**: FASTP, MEGAHIT, RagTag, BUSCO, QUAST.  

---

## Quick Start  

### 1. Clone the repository  

```bash  
git clone https://github.com/PauloSchreiner/yeast-genome-assembly.git  
cd yeast-genome-assembly
```

### 2. Set up the environment

```bash
conda env create -f envs/assembly.yaml  
conda activate yeast_assembly  
```

### 3. Configure the pipeline

Edit config.yaml:
```bash
threads: 8                # CPU cores to use  
ram_percentage: 0.75      # Fraction of RAM for MEGAHIT (0-1)  
genomes_dir: "raw_data"   # Input directory with FASTQ files  
busco_lineage: "saccharomycetes_odb10"  
reference: "references/S288C.fa"  
```

### 4. Add the input

Add the input to the ```/raw_data``` folder, as follows:
```bash
raw_data/  
└─ SAMPLE_NAME/  
   ├─ SAMPLE_NAME_1.fq.gz  # Read 1  
   └─ SAMPLE_NAME_2.fq.gz  # Read 2  
```



Add the reference genome (used in BUSCO) to the ```/references``` folder, as such:
```bash
└─ references
   ├── README.md
   ├── S288C.fa
   └── S288C.fa.fai
```
Obs.: the .fai index file is generated automatically if missing, and the README.md file is recommended to provide insight into the reference genome used. 


### 5. Run the pipeline
```bash
chmod +x ./scripts/pipeline_run.sh    # Make the file executable
./scripts/pipeline_run.sh    # Enjoy!
```


--- 

## Output Structure

```bash
results/  
└─ run_TIMESTAMP/  
   └─ SAMPLE_NAME/  
      ├─ 1_fastp/       # Trimmed reads and QC reports  
      ├─ 2_megahit/     # Assembly contigs  
      ├─ 3_ragtag/      # Scaffolded assembly  
      ├─ 4_busco/       # Completeness report (BUSCO)  
      └─ 5_quast/       # Assembly metrics (QUAST)  
```

--- 

## Dependencies

- **Conda** (Miniconda or Anaconda)
- **Tools installed via `assembly.yaml`**:
```yaml
dependencies:
  - fastp >=0.23.2
  - megahit >=1.2.9
  - ragtag >=2.1.0
  - busco >=5.4.3
  - quast >=5.2.0
```

---

## Perspectives

### *Here are some features that I plan on adding in the near future:*

- **Resume Failed Runs**:  
    Currently, the pipeline must restart from scratch if interrupted. Future versions will:
    - Detect completed steps (via output file checks or checkpointing)
    - Allow partial restarts from the last valid step  
    - Include a `--resume` flag to continue runs  
    - Preserve intermediate results for debugging  

    
- **Customizable parameters**: 
    As of right now, the pipeline is very rigid — in order to edit the parameters of each tool, one must edit the pipeline_run.sh script. In future versions, I want the users to be able to edit such parameters in the config.yaml file.


- **Modularity and alternative tools**: 
    I want to study existing yeast assembly pipelines and find add alternative tools to this pipeline (such as ABySS as a MEGAHIT alternative for the assembly step) and ensure the pipeline is modular and customizable according to the user's needs.


- **Saving alternative config profiles**: 
    Save and compare multiple parameter sets. Allow the user to save multiple config files with different run parameters (and perhaps even with different tools) and call the specific config file they want upon running the pipeline. This would allow the user to compare multiple parameters without losing the previous ones. 
    - **Implementation:**
    ```bash
    ./pipeline_run.sh --config config_abyss.yaml  # Use ABySS params
    ./pipeline_run.sh --config config_megahit.yaml # Use MEGAHIT params
    ```

    - **Directory structure:**
    ```bash
    configs/
    ├── default.yaml      # Baseline parameters
    ├── quick_run.yaml    # Faster, lower sensitivity
    └── high_quality.yaml # Slower, more stringent
    ``` 
    
    - **Automatic logging:**
      - Archive used configs in results/run_*/config_backup.yaml
      - Generate comparative reports when different configs are tested


*If you have suggestions, please open an issue within the repo! :D*


