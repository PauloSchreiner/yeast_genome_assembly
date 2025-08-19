# LBCM Yeast Genome Assembly Pipeline

*A reproducible Snakemake pipeline for assembling yeast genomes using FASTP, MEGAHIT, RAGTAG, BUSCO and QUAST, by LBCM (Laboratório de Biologia Computacional e Molecular)* 

---

## Overview  
**Automated pipeline for:**  
- Quality control of Illumina reads (FASTP)  
- Genome assembly (MEGAHIT)  
- Reference-guided correction, scaffolding and patching (RagTag)  
- Completeness assessment (BUSCO)  
- Assembly metrics (QUAST)  

*Designed for assembling Illumina paired-end reads.*

---

## Quick Start  

### 1. Clone the repository  

```bash  
git clone https://github.com/PauloSchreiner/yeast_genome_assembly.git  
cd yeast_genome_assembly
```

### 2. Set up the environment

```bash
conda env create -f envs/assembly.yaml  
conda activate yeast_assembly  
```

### 3. Configure the pipeline

Edit `/config/config.yaml` as you wish:
```yaml
run_id: "testrun"                        # Unique identifier for the run, can be set manually. If empty, a timestamped run ID will be generated 
results_root: "results"                  # Base directory for all results
genomes_dir: data/raw                    # Directory containing genome folders
busco_lineage: saccharomycetes_odb10     # BUSCO database
reference: data/references/S288C.fa      # Path to reference genome for RagTag
threads: 6                               # Number of CPU cores to use
ram_percentage: 0.8                      # RAM fraction to use
```

### 4. Add the input

Add the raw sequencing data to the `data/raw` folder, as follows:
```bash
data/raw/  
     └─ SAMPLE_NAME/  
        ├─ SAMPLE_NAME_1.fq.gz  # Read 1  
        └─ SAMPLE_NAME_2.fq.gz  # Read 2  
```
The expected input consists of two paired-end Illumina reads. 
*Important: the filenames must end with "1.fq.gz" and "2.fq.gz" to be correctly selected.*

Add the reference genome (used in BUSCO) to the `data/references` folder, as such:
```bash
data/references
      ├── README.md
      ├── S288C.fa
      └── S288C.fa.fai
```
The ```README.md``` file is recommended to provide insight into the reference genome used, and a ```.fa.fai``` index file will be automatically generated — it helps with BUSCO performance. 

### 5. Run the pipeline

```bash
snakemake --cores all
```
Or, for full reproducibility and environment management:
```bash
snakemake --use-conda --cores all
```


--- 

## Directory tree

The project root directory looks like this:
```bash
.
├── config        # Customizable configurations (to change tools and their parameters)
├── envs          # Conda environment files 
├── external      # Data necessary for certain tools to run 
├── data          # User input goes here
|   ├─ raw        # Raw sequencing data goes here  
|   └─ references # Reference genome (used by some tools) goes here
├── results       # Contains the outputs of each run
└── workflow      # Contains the Snakemake workflow and scripts
    ├─ Snakefile  # The main pipeline script
    └─ scripts    # (Legacy) or utility scripts
```


---

## Output Structure

```bash
results/  
└─ run_TIMESTAMP/  
   └─ SAMPLE_NAME/  
      ├─ fastp/       # Trimmed reads and QC reports  
      ├─ megahit/     # Assembly contigs  
      ├─ ragtag/      # Corrected, scaffolded and patched assembly  
      ├─ busco/       # Completeness report (BUSCO)  
      └─ quast/       # Assembly metrics (QUAST)  
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
  - snakemake 
```

---

## Perspectives

### *Here are some features that I plan on adding in the near future:*

    
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


- **Expanding to genome annotation**:
    Why limit ourselves to assembling yeast genomes? This tool will later be expanded to include genome annotation with Augustus! 

- **Improving outputs**:
    Last but not least, improve the terminal outputs and create general reports of all pipeline for users to assess.  


*If you have suggestions, please open an issue within the repo! :D*

---

## Known Issues

### MEGAHIT Output Directory

**Beware of the MEGAHIT rule:**
MEGAHIT will fail if its output directory already exists. Because Snakemake automatically creates output directories for rule outputs, the workflow runs MEGAHIT in a temporary directory and moves the resulting contigs file to the expected location. This ensures compatibility and prevents workflow failures.