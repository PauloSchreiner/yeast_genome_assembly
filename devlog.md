# Devlog/notes


---

## CURRENT PLAN
1. Create the prototype of the pipeline and make it work.
This prototype should: 
- accept input (one or multiple genomes) and basic parameters such as GPU and RAM usage;
- process the inputs in an orderly but non-flexible manner;
- output the results in an orderly manner.
- have everything documented in a README file.
The prototype should be user-friendly, simple, and just work. 
*I find it safe to say this has already been achieved*

2. Add onto the prototype:
- Study other pipelines and understand how they are better than our prototype (here enters a review)
- Expand the accepted parameters
- Add modularity and flexibility as of the tools used in each step (for example, allow the user to choose between megahit and abyss)
- Document all changes made and new features in the README file.

---

## TO STUDY
- Anotação com Augustus
- Entender melhor as estatísticas e parâmetros do fastp e das outras ferramentas
- Estudar padrões do RagTag pra aumentar continuidade 
- Ler artigo Matheus e fazer revisão de pipelines de montagem de genomas de leveduras


## SHORT-TERM
- Is busco always giving the same results? Is this normal? 
- Resume functionality — use snakemake instead of bash?
- Config profiles, modularity and parameter customization 
    - in order to do this, we will need to change config file parsing and create some sort of super run_command function to handle the different commands to be run. 
    - then, to expand, it will be a matter of learning each tool's syntax and accepted parameters.
    - perhaps I will need to store the syntax and accepted parameters in an external file (JSON?)

- Run the following command and compare results:
    ```bash
    fastp -i NCYC357_test_L1_1.fq.gz -I NCYC357_test_L1_2.fq.gz -o result1complexity.fq.gz \
    -O result2complexity.fq.gz -q 28 --detect_adapter_for_pe --correction --trim_tail1=2 \
    --trim_tail2=2 --trim_front1=10 --trim_front2=10 --trim_poly_x -p -y
    ```

## LONG-TERM GOALS
- Turn it into a CLI tool (add argument handling, etc) 



--- 

DeepSeek's improvement ideas:
Areas for Improvement (Based on Your Plans)

    Resume Functionality
        Implement checkpointing (e.g., check for ragtag.patch.fasta before rerunning BUSCO).
        Add a --resume flag to skip completed steps.
    Parameter Customization
        Move tool-specific params (e.g., MEGAHIT --k-list) from pipeline_run.sh to config.yaml.
    Alternative Assemblers
        For yeast (small genomes), SPAdes or Unicycler (hybrid mode) may outperform MEGAHIT in some cases.
    Multi-Config Support
        Your configs/ directory idea is excellent. Consider templating (e.g., Jinja2) for dynamic configs.
    Output Reports
        Aggregate QUAST/BUSCO results across samples into a summary table (e.g., with pandas).
Quick Fixes/Suggestions
    FASTP: Add --detect_adapter_for_pe to auto-detect adapters.
    MEGAHIT: Explicitly set --k-min/--k-max for yeast (e.g., --k-list 21,33,55).
    RagTag: Use --aligner minimap2 (faster than default nucmer for yeast-sized genomes).
    BUSCO: Add --augustus_species saccharomyces to improve gene prediction.

Example Upgrade (Modular Tools)
In config.yaml, add:
yaml
assembler: "megahit"  # or "abyss", "spades"
megahit_params: "--k-list 21,33,55 --min-count 2"
abyss_params: "-k 55 -j 4"

Then in pipeline_run.sh:
bash
case "$ASSEMBLER" in
    "megahit") megahit $MEGAHIT_PARAMS ... ;;
    "abyss")   abyss-pe $ABYSS_PARAMS ... ;;
esac
