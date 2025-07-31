# Yeast Genome Assembly Pipeline

## Overview
Pipeline for assembling a yeast genome using:
- **fastp** (read trimming)
- **MEGAHIT** (assembly)
- **RagTag** (scaffolding)
- **BUSCO** (completeness assessment)
- **QUAST** (quality evaluation)


## Directory structure
├── data # Raw sequencing data (immutable)
├── scripts
├── results
│   ├── 1_fastp
│   ├── 2_megahit
│   ├── 3_ragtag
│   ├── 4_busco
│   └── 5_quast
├── logs 
├── envs 
│   └── assembly.yaml # Conda environment
└── README.md 


## Creation log:
1. Create conda environment and check if all modules are working fine


## Preparo para publicação:
1. Exportar todas dependências do conda usando conda env export > envs/assembly_frozen.yaml 

