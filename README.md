# mapfunc workflow

The `mapfunc` pipeline uses the Diamond read mapper to search for protein-coding genes in metagenomic read libraries, by mapping against the Uniprot database. The aim is to look for genes of interest that may have been misassembled or mispredicted by gene-callers.

## 0. Align metagenome reads to Swissprot database with Diamond

Obtain current version of Swiss-Prot as Fasta sequences from [Uniprot](http://www.uniprot.org/downloads)

Build diamond database from the Fasta file:

```bash
diamond makedb --in uniprot_sprot.fasta -d uniprot_sprot_2017_01
```

Run `diamond blastx` on sensitive mode. Example command:

```bash
diamond blastx -v \
               -d /opt/extern/bremen/symbiosis/seah/mapall/uniprot_sprot_2017_01 \
               -q 1418_A_*R1*.fastq.gz \
               -p 24 \
               -o 1418A_v_uniprot_sprot.diamond.blastx.daa \
               -f 100 \
               --sensitive \
               --max-target-seqs 1 \
               --tmpdir /dev/shm
```

## 1. Get lists of reads mapping to target genes

From Uniprot, export accession numbers of proteins corresponding to target gene. This can be done by parsing the `uniprot_sprot.dat` file, or by the [web interface query](http://www.uniprot.org/uniprot).

For each target, there should be a separate text file, containing simple list of accession numbers separated by linebreaks.

Make a tab-separated table of the target lists, with a name for each target in the first column, and path to the file in second column (`target_list`).

Make another tab-separated table of the `.daa` output files from `diamond`, with the library name in the first column, and path to the file in the second column (`daa_list`).

Example command:

```bash
perl mapfunc_gethits.pl --daa daa_list \
                        --target target_list \
                        --outdir ./output \
                        --outfile mapfunc_hitslog_001 \
                        --threads 8
```

## 2. Extract reads sequences that map to target genes

Given raw reads and lists from previous step, extract the Fastq formatted reads

Requires the output files produced in the previous step (`--outfile`), which contain paths to files containing lists of sequences that map to each target.

Also requires tab-separated tables of paths to the original read files, with library name in the first column and path to the read file in the second column (`readsfwd_all` and `readsrev_all`)

```bash
perl mapfunc_getreads.pl --hitslog mapfunc_hitslog_001 \
                         --readsf readsfwd_all \
                         --readsr readsrev_all
```

## 3. Map extract reads onto assembly for coverage statistics

Requires corresponding reference assembly of each metagenome: make tab-separated table of assemblies, with library name in first column, and path to assembly Fasta file in second column (`asssembly_list`).

Also requires the `hitslog` from step 1.

```bash
perl mapfunc_mapassem.pl --assem assembly_list \
                         --hitslog mapfunc_hitslog_001 \
                         --threads 8 \
                         --outdir ./output
```

## 4. Calculate coverage statistics and make GC-coverage plots

Summary stats of mapping are summarized from the `scafstats` output from step 3, and plotted onto GC-coverage plots with `gbtools`.

Requires the hitslog file from step 1, and also coverage-GC statistics and SSU marker tables for input to `gbtools` to draw plots.

Turn on plot-drawing with `--plots` option (off by default).

Turn on tabulation of numbers of reads mapped with the `--table` option (off by default).

```bash
perl mapfunc_tabplot.pl --covstats covstats_list \
                        --ssu ssu_tab_list \
                        --hitslog mapfunc_hitslog_001 \
                        --outtab mapfunc_tabulate.out \
                        --outdir ./output \
                        --plotdir ./plots \
                        --plot \
                        --table
```

## Dependencies

 * `diamond` v0.8+
 * `bbmap.sh`
 * `seqtk`
 * `gzip`
 * `tsp` (for scheduling jobs)
 * `R`,`Rscript`, and R package `gbtools` - for plots

## TO DO

 * For coverage plots with overlay - remove SSU marker (distracting) and add text label of counts beside each contig with hits (do not show for counts < 5)
 * Boxplots of hits per protein of interest, but with values first standardized to library size and average protein length
 * Add two or three more metabolic genes that are expected to be present, as well as non-metabolic genes (e.g. RecA?)

