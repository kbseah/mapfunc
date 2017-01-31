#!/usr/bin/env Rscript

# Make gbtools plot and overlay with where reads have mapped

# Usage: Rscript gbt_map_plot.R --args <covstats> <ssu> <mapstats> <outfile> <library> <domain>

# Requires: gbtools package
# Output: <plot>.png

## Get arguments from command line
args <- commandArgs(trailingOnly=TRUE)
covstats <- args[2]
ssutab <- args[3]
mapstats <- args[4]
outfile <- args[5]
lib <- args[6]
dom <- args[7]


## Load library
library(gbtools)

## Load data
d <- gbt(covstats, ssu=ssutab)
mapsRaw <- read.table(mapstats, sep="\t", header=F)
maps <- data.frame(mapsRaw$V1,mapsRaw$V6)

## Prepare palette and legend
blackred = colorRampPalette(c("Black","Red"))
legendArr = c(0.25,0.5,0.75,1)
legendArr = c(1,round(legendArr * max(maps[,2])))
legendCol = sapply(legendArr,function(x) blackred(max(maps[,2]))[x])

## Do plot
png(file=outfile)
plot(d, ssu=T, marker=F, textlabel=F, assemblyName=paste(lib,dom,sep=" "))
for (i in dim(maps)[1]:1) { # Reverse sort
    points(gbtbin(as.character(maps[i,1]),
                  d,
                  slice=1),
           cutoff=200,
           col=blackred(max(maps[,2]))[maps[i,2]])
}
legend("topleft",legend=legendArr,fill=legendCol,cex=0.75,title="Reads mapped")
dev.off()
