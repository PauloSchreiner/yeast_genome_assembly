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



