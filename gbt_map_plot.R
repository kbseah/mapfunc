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
maps <- data.frame(ID=mapsRaw$V1,Maps=mapsRaw$V6)

## Prepare palette and legend
blackred = colorRampPalette(c("Black","Red"))
#legendArr = c(0.25,0.5,0.75,1)
#legendArr = c(1,round(legendArr * max(maps[,2])))
#legendCol = sapply(legendArr,function(x) blackred(max(maps[,2]))[x])

## Do plot
png(file=outfile)
plot(d, ssu=F, marker=F, textlabel=F, assemblyName=paste(lib,dom,sep=" "))
for (i in dim(maps)[1]:1) { # Reverse sort
    # Extract data for contigs with mapped reads from gbt object
    tmpbin <- gbtbin(as.character(maps[,1]),
                     d,
                     slice=1)
    tmpbin2 <- merge(tmpbin$scaff,maps,by.x="ID",by.y="ID")
    # Render points for contigs with mapped reads of interest
    points(x=tmpbin2$Ref_GC,
           y=tmpbin2$Avg_fold,
           pch=21,
           cex=sqrt(tmpbin2$Length)/100,
           col=blackred(max(tmpbin2$Maps)+1)[tmpbin2$Maps+1]) # Color scaled by mapping hits. Plus 1 because any zero values will mess up the color vector
    # Display text label only if more than 10 reads mapping
    tmpbin3 <- subset(tmpbin2,Maps > 10)
    # Render text label
    text(x=tmpbin3$Ref_GC,
         y=tmpbin3$Avg_fold,
         as.character(tmpbin3$Maps),
         cex=0.75,
         pos=4)
}
#legend("topleft",legend=legendArr,fill=legendCol,cex=0.75,title="Reads mapped")
dev.off()
