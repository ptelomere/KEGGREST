library(KEGGREST)
library(RUnit)

## checker helper
.checkLOL <- function(res)
{
    all(checkTrue(class(res)=="list"),
        checkTrue(class(res[[1]])=="list"),
        checkTrue(length(res) > 0))
}

.checkCharVec <- function(res)
{
    all(checkTrue(class(res)=="character"),
        checkTrue(length(res) > 0))
}

.checkPlainText <- function(res)
{
    all(checkTrue(class(res)=="character"),
        checkTrue(length(res) == 1))
}

.checkNamedCharVec <- function(res)
{
    .checkCharVec(res) &&
        checkTrue(length(names(res)) > 0)
}

.checkUnnamedCharVec <- function(res)
{
    .checkCharVec(res) &&
        is.null(names(res))
}

test_keggInfo <- function()
{
    res <- keggInfo("kegg")
    .checkPlainText(res)
    res <- keggInfo("pathway")
    .checkPlainText(res)
    res <- keggInfo("hsa")
    .checkPlainText(res)

}

test_keggList <- function()
{
    res <- keggList("pathway")
    .checkCharVec(res)
    res <- keggList("pathway", "hsa")
    .checkCharVec(res)
    res <- keggList("organism")
    checkTrue("matrix" %in% class(res))
    res <- keggList("hsa")
    .checkCharVec(res)
    res <- keggList("T01001")
    .checkCharVec(res)
    res <- keggList(c("hsa:10458", "ece:Z5100"))
    .checkCharVec(res)
    res <- keggList(c("cpd:C01290","gl:G00092"))
    .checkCharVec(res)
    res <- keggList(c("C01290+G00092"))
    .checkCharVec(res)
}

## The thorough thing to do would be to hit /list/x for each
## x in listDatabases, but that might slam KEGG too hard and
## make them mad. Instead we hit /info. KEGG does not like
## /info/organism for some reason so we will test /list/organism.
test_listDatabases <- function()
{
    dbs <- listDatabases()
    for (db in dbs)
    {
        if (db != "organism")
        {
            res <- keggInfo(db)
            .checkPlainText(res)
        }
    }
    res <- keggList("organism")
    checkTrue("matrix" %in% class(res))
}


test_keggFind <- function()
{
    res <- keggFind("genes", c("shiga", "toxin"))
    .checkCharVec(res)
    res <- keggFind("genes", "shiga toxin")
    .checkCharVec(res)
    res <- keggFind("compound", "C7H10O5", "formula")
    .checkCharVec(res)
    res <- keggFind("compound", "O5C7", "formula")
    .checkCharVec(res)
    res <- keggFind("compound", 174.05, "exact_mass")
    .checkCharVec(res)
    res <- keggFind("compound", 300:310, "mol_weight")
    .checkCharVec(res)
}

test_keggGet <- function()
{
    res <- keggGet(c("cpd:C01290", "gl:G00092"))
    .checkLOL(res)
    res <- keggGet(c("C01290", "G00092"))
    .checkLOL(res)
    res <- keggGet(c("hsa:10458", "ece:Z5100"))
    .checkLOL(res)
    res <- keggGet("ec:1.1.1.1")
    .checkLOL(res)
    .checkLOL(res[[1]]$REFERENCE)
    res <- keggGet(c("hsa:10458", "ece:Z5100"), "aaseq")
    checkTrue("AAStringSet" %in% class(res))
    res <- keggGet(c("hsa:10458", "ece:Z5100"), "ntseq")
    checkTrue("DNAStringSet" %in% class(res))
    png <- keggGet("hsa05130", "image")
    checkTrue("array" %in% class(png))
}

test_keggGet_2 <- function()
{
    res <- keggGet("br:br08901")
    .checkCharVec(res)
    res <- keggGet(c("br:br08901", "ece:Z5100"))
    .checkCharVec(res)
    res <- keggGet(c("ece:Z5100", "br:br08901"))
    .checkLOL(res)
    res <- keggGet("path:map00010")
    res <- res[[1]]
    .checkNamedCharVec(res$DISEASE)
    res <- keggGet("md:M00001")
    .checkNamedCharVec(res[[1]]$REACTION)
    .checkNamedCharVec(res[[1]]$ORTHOLOGY)
    res <- keggGet("ds:H00001")
    .checkLOL(res)
    .checkUnnamedCharVec(res[[1]]$GENE)
    .checkUnnamedCharVec(res[[1]]$MARKER)
    res <- keggGet("dr:D00001")
    x <- res[[1]]$PRODUCT
    checkTrue(all(names(x) == c("PRODUCT","GENERIC","OTHER")))
    checkTrue(grepl("^ ", res[[1]]$BRITE[2]))
    res <- keggGet("ev:E00001")
    .checkCharVec(res[[1]]$CATEGORY)
    res <- keggGet("ko:K00001")
    checkTrue(names(res[[1]]$ENTRY) == "KO")
    ## DBLINK parser?
    res <- keggGet("genome:T00001")
    x <- res[[1]]$CHROMOSOME
    checkTrue(all(names(x) == c("CHROMOSOME", "SEQUENCE", "LENGTH")))
    x <- res[[1]]$TAXONOMY
    checkTrue(all(names(x) == c("TAXONOMY", "LINEAGE")))
    res <- keggGet("mgnm:T30001")
    ## metagenome has multiple TAXONOMY sections! fixme
    .checkCharVec(res[[1]]$ANNOTATION)
     res <- keggGet("hsa:645954")
     .checkNamedCharVec(res[[1]]$ORGANISM)
     ## IS DNAStringSet the best object for a nucleotide sequence? fixme
     checkTrue(class(res[[1]]$NTSEQ) %in% "DNAStringSet")
     res <-keggGet("cpd:C00001")
     .checkUnnamedCharVec(res[[1]]$REACTION)
     checkTrue(length(res[[1]]$REACTION)> 300)
     res <- keggGet("gl:G00001")
     checkTrue("COMPOSITION" %in% names(res[[1]]))
     res <- keggGet("rn:R00001")
     checkTrue("EQUATION" %in% names(res[[1]]))
     res <- keggGet("rp:RP00001")
     checkTrue("ENTRY1" %in% names(res[[1]]))
     checkTrue("ENTRY2" %in% names(res[[1]]))
     res <- keggGet("rc:RC00001")
     .checkUnnamedCharVec(res[[1]]$REACTION)
     res <- keggGet("ec:1.1.1.1")
     .checkUnnamedCharVec(res[[1]]$REACTION)
     .checkUnnamedCharVec(res[[1]]$ALL_REAC) ## not ideal fixme (?)
     #res <- keggGet("vgnm:NC_018104")
     #checkTrue(is.na(names(res[[1]]$ENTRY))) # not ideal fixme
     res <- keggGet("hsa:10458")
     checkTrue("AAStringSet" %in% class(res[[1]]$AASEQ))
     checkTrue("DNAStringSet" %in% class(res[[1]]$NTSEQ))
    # fixme do something with CODON_USAGE?


}

test_keggConv <- function()
{
    res <- keggConv("eco", "ncbi-geneid")
    .checkCharVec(res)
    res <- keggConv("ncbi-geneid", "eco")
    .checkCharVec(res)
    res <- keggConv("ncbi-gi", c("hsa:10458", "ece:Z5100"))
    .checkCharVec(res)
}

test_keggLink <- function()
{
    res <- keggLink("pathway", "hsa")
    .checkCharVec(res)
    res <- keggLink("hsa", "pathway")
    .checkCharVec(res)
    res <- keggLink("pathway", c("hsa:10458", "ece:Z5100"))
    .checkCharVec(res)
}

test_mark_and_color_pathways_by_objects  <- function(){
  url <- mark.pathway.by.objects("path:eco00260",
                                 c("eco:b0002", "eco:c00263"))
  .checkCharVec(url)
  checkTrue(grep("http://", url)==1)
  url <- color.pathway.by.objects("path:eco00260",
                                  c("eco:b0002", "eco:c00263"),
                                  c("#ff0000", "#00ff00"),
                                  c("#ffff00", "yellow"))
  .checkCharVec(url)
  checkTrue(grep("http://", url)==1)
}


test_reference_parser <- function()
{
    res <- keggGet("path:map00010")[[1]]
    refs <- res$REFERENCE[[1]]
    checkTrue(length(refs) > 0)
}