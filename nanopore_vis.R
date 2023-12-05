library(shiny)
library(igvShiny)

options(browser="google-chrome")
options(shiny.port=3000)
options(shiny.host="0.0.0.0")
options(shiny.maxRequestSize = 100 * 1024^2)
dir.create("tracks")
addResourcePath("tracks", "tracks")

ui = shinyUI(fluidPage(
    sidebarLayout(
        sidebarPanel(
            fileInput("target", label="Choose target fasta file",
                      accept = c(".fa", ".fasta")),
            actionButton("upload", "Upload reference genome"),
            br(),
            fileInput("sequences", label="Choose sequence file",
                      accept = c(".fq", ".fastq", ".gz")),
            actionButton("runAlign", "Run alignment"),
            hr(),
            width=2
        ),
        mainPanel(
            igvShinyOutput('igvShiny_0'),
            br(),
            hr(),
            verbatimTextOutput('igvShiny_1'),
            br(),
            uiOutput("links"),
            width=10
        )
    )))


server = function(input, output, session) {
   observeEvent(input$upload, {
       print("upload ref")
       ref <- input$target
       file.copy(ref$datapath, "ref.fa", overwrite = TRUE)
       system(paste("samtools faidx ref.fa"))
       genomeOptions <- parseAndValidateGenomeSpec(genomeName="local",
                                                   stockGenome=FALSE,
                                                   dataMode="localFiles",
                                                   fasta="ref.fa",
                                                   fastaIndex="ref.fa.fai")
       
       output$igvShiny_0 <- renderIgvShiny({
           cat("--- staring render genome\n");
           x <- igvShiny(genomeOptions,
                         displayMode="SQUISHED",
                         tracks=list()
                         )
           return(x)
           
       })
       output$igvShiny_1 <- renderText({"target genome uploaded!"})
   })
   
   observeEvent(input$runAlign, {
        print("Run alignment")
        seqs <- input$sequences
        bam <- paste0(sub(".f.*$", "", seqs$name), ".bam")
        system(paste0("minimap2 -ax splice ref.fa ", seqs$datapath, " | samtools sort - -o tracks/", bam, "; samtools index tracks/", bam))
        if(file.exists(paste0("tracks/", bam))) {
            print(normalizePath(paste0("tracks/", bam)))
            output$igvShiny_1 <- renderText({"Alignment done!"})
        }
        loadBamTrackFromURL(session, id="igvShiny_0",trackName="align",
                            bamURL=paste0("http://0.0.0.0:3000/tracks/", bam),
                            indexURL=paste0("http://0.0.0.0:3000/tracks/", bam, ".bai"))

        fstat <- system(paste0("samtools flagstat tracks/", bam), intern=TRUE)
        fstat <- paste(c(paste0("samtools flagstat tracks/", bam), fstat), collapse="\n")
        output$igvShiny_1 <- renderText({fstat})
        output$links <- renderUI({
            tagList(
                tags$text("Alignments:"),
                tags$a(bam, href=paste0("tracks/", bam)),
                tags$a(paste0(bam, ".bai"), href=paste0("tracks/", bam, ".bai"))
            )
        })
    })
}

shinyApp(ui, server)
## runApp(app, port=3000)
