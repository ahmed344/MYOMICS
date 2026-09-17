# MYOMICS

Individual RNA abnormality detection in muscle biopsies.

Paired-end RNA-seq is aligned with STAR, then DROP 1.6.1 is used for
aberrant splicing (FRASER2) and aberrant expression (OUTRIDER). Both
steps run inside the DROP Biocontainer started by `docker_drop.sh`.

## Layout

| Path | Role |
| --- | --- |
| `docker_drop.sh` | Interactive `quay.io/biocontainers/drop:1.6.1` container (STAR, samtools, Snakemake 7.32) |
| `alignment/` | GENCODE download, STAR genome index, PE alignment, BAM indexing |
| `drop/` | DROP project config, sample table, and launcher for FRASER2 then OUTRIDER |

Large data stay on the host HDD mount, not in this git repo.

## Container

From the host:

```bash
bash docker_drop.sh
```

The container is named `myomics-drop`, limited to 200 GB RAM and 24 CPUs, and
uses your host UID so written files are not root-owned. Bind mounts:

| Container path | Host path |
| --- | --- |
| `/workspace` | this repository |
| `/workspace/data` | `/home/ahmed/Data/MYOMICS` |
| `/workspace/data_hdd` | `/home/ahmed/Data/HDD/Data/MYOMICS` |

`HOME` is `/tmp/myomics_home` so Snakemake and R can write inside the image.
Do not run the alignment Snakefile or `drop/run.sh` on the host.

## Alignment (`alignment/`)

Snakemake 7 workflow that:

1. Downloads GENCODE v50 GRCh38 primary-assembly FASTA and GTF
2. Builds a STAR genome index (`sjdbOverhang` = read length − 1 = 74 for 75 bp reads)
3. Aligns each Illumina PE sample (`*_R1_001.fastq.gz` / `*_R2_001.fastq.gz`)
4. Indexes BAMs with samtools
5. Writes `mapping_summary.tsv` (input reads and unique-map %)

STAR flags follow ENCODE long RNA-seq / DROP-style defaults (two-pass, gene
counts, MAPQ 60 for unique maps). Runtime knobs (paths, threads, RAM) live in
`alignment/config.yaml`; protocol flags are under `star.align` in the same file.
The Snakemake CLI profile is `alignment/profiles/drop/config.yaml`.

Inside the container:

```bash
cd /workspace/alignment
snakemake --profile profiles/drop              # index + align
snakemake --profile profiles/drop star_index
snakemake --profile profiles/drop -n           # dry-run
snakemake --profile profiles/drop -R star_index   # rebuild index
```

Default container paths in `alignment/config.yaml`:

| Key | Path |
| --- | --- |
| FASTA / GTF / STAR index | `/workspace/data_hdd/alignment/gencode_v50_GRCh38` |
| FASTQs | `/workspace/data_hdd/260630_MYOMICS-MO_Malfatti` |
| BAMs | `/workspace/data_hdd/alignment/star/{sample}/` |
| STAR temp | `/tmp/myomics_star` |

STAR `--outTmpDir` must be a real Linux filesystem (FIFOs). It cannot live on
the HDD bind mount. Empty `samples.names` means auto-discover every pair in
`fastq_dir`; names starting with `Undetermined` are skipped.

Per-sample outputs:

- `{sample}_Aligned.sortedByCoord.out.bam` (+ `.bai`)
- `{sample}_Log.final.out`
- `{sample}_ReadsPerGene.out.tab`

## DROP (`drop/`)

DROP 1.6.1 project for the `muscle` cohort: FRASER2 aberrant splicing and
OUTRIDER aberrant expression. MAE and RNA variant calling are off.

Tracked files (do not run `drop init` on the host):

| File | Role |
| --- | --- |
| `drop/config.yaml` | Project title, genome, FRASER2 / OUTRIDER cutoffs |
| `drop/sample_annotation.tsv` | BAM paths, DROP group, strand, disease status |
| `drop/profiles/drop/config.yaml` | Snakemake CLI profile (16 cores, HDD `latency-wait`) |
| `drop/run.sh` | `drop init` if needed, then the requested module |

`drop init` creates `Snakefile`, `Scripts/`, `.drop/`, and `.wBuild/` inside
the container. Those are gitignored.

Reference (same GENCODE v50 files as alignment):

- Assembly: hg38 (`chr*` names)
- FASTA: `/workspace/data_hdd/alignment/gencode_v50_GRCh38/GRCh38.primary_assembly.genome.fa`
- GTF: `gencode.v50.primary_assembly.annotation.gtf`
- Results: `/workspace/data_hdd/drop` (HTML under `html/`)

`sample_annotation.tsv` lists 16 muscle RNA-seq libraries (8 controls `_C`, 8
patients `_P`). BAMs are the STAR outputs above. Libraries are paired-end,
reverse-stranded, `IntersectionStrict` with overlapping counts.

Inside the container:

```bash
bash /workspace/drop/run.sh dryrun
bash /workspace/drop/run.sh fraser      # aberrantSplicing / FRASER2
bash /workspace/drop/run.sh outrider    # aberrantExpression / OUTRIDER
bash /workspace/drop/run.sh all         # fraser then outrider
bash /workspace/drop/run.sh init        # drop init only
```

## References

- [DROP](https://github.com/gagneurlab/drop) — Detection of RNA Outliers Pipeline
- [DROP protocol](https://www.nature.com/articles/s41596-020-00462-5) — *Nature Protocols*
- [GENCODE](https://www.gencodegenes.org/) — human reference used for indexing and DROP
