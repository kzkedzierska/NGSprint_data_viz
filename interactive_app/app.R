#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(ggsci)
source("cosmic_genes.R") # I copied cosmic genes there, 
# read more about COSMIC census here: https://cancer.sanger.ac.uk/census
# essentially this is a list of genes recognized as cancer genes

# Things called only once
# Read in data
maf_data <- readRDS("data/maf_data_df.RDS")
normalized_counts <- readRDS("data/normalized_counts.RDS")
tcga_subtype_data <- readRDS("data/tcga_subtype_data.RDS")

# Define constants
patient_ids <- 
    colnames(normalized_counts)

patients_with_mut_data <-
    maf_data %>%
    mutate(patient_id = str_extract(Tumor_Sample_Barcode,
                                    "[^-]{4}-[^-]{2}-[^-]{4}")) %>%
    pull(patient_id) %>%
    unique()

# Interactive part
# Define user interface (UI) for application
ui <- fluidPage(
    
    # Application title
    titlePanel("LGG - interactive expression plots"),
    
    sidebarLayout(
        sidebarPanel(
            selectizeInput(inputId = "genes_to_plot",
                           label = "Genes to plot:",
                           choices = cosmic_genes,
                           selected = c("IDH1", "TP53"), 
                           multiple = TRUE,
                           options = list(maxItems = 10))
        ),
        mainPanel(
            tabsetPanel(
                tabPanel(
                    "Expression by mutation status",
                    verbatimTextOutput("mut", placeholder = FALSE),
                    plotOutput("expr_mut_plot")
                ),
                tabPanel(
                    "Expression by subtype",
                    verbatimTextOutput("subtype", placeholder = FALSE),
                    plotOutput("expr_subtype")
                )
            )
        )
    )
)

# Define server that reacts to user input
server <- function(input, output) {
    
    # data frames recalculated with changing input
    # expression
    expression_vals <-
        reactive({
            normalized_counts[input$genes_to_plot, , drop = FALSE] %>%
                as.data.frame() %>%
                rownames_to_column("Hugo_Symbol") %>%
                pivot_longer(names_to = "patient_id",
                             values_to = "norm_expression",
                             cols = -Hugo_Symbol)
        })
    # somatic mutations
    mutation_data <-
        reactive({
            maf_data %>%
                filter(Hugo_Symbol %in% input$genes_to_plot) %>%
                mutate(patient_id = str_extract(Tumor_Sample_Barcode,
                                                "[^-]{4}-[^-]{2}-[^-]{4}")) %>%
                dplyr::select(patient_id, Hugo_Symbol, VARIANT_CLASS)
        })
    output$subtype <- 
        renderText("Compare expression levels per subtype.")
    
    output$mut <- 
        renderText("Compare expression levels per mutational status.")
    
    output$expr_mut_plot <- renderPlot({
        
        # this will allow us to distinguish between no infomration about mutation
        # and no mutation

        expr_mut_df <-
            full_join(expression_vals(), mutation_data()) %>%
            # introduce WT for samples with no mutation in the gene
            mutate(VARIANT_CLASS = as.character(VARIANT_CLASS),
                   # VARIANT_CLASS:
                   # * not NA => VARIANT_CLASS, i.e. classification of mutation
                   # * NA and id present in patients_with_mut_data => no mutation in gene
                   # * NA and not in patients_with_mut_data => no mutation data for patient
                   VARIANT_CLASS = ifelse(is.na(VARIANT_CLASS),
                                          yes = ifelse(patient_id %in% patients_with_mut_data,
                                                       yes = "WT",
                                                       no = "NA"),
                                          no = VARIANT_CLASS),
                   
                   # setting factors ordereing
                   VARIANT_CLASS = factor(VARIANT_CLASS,
                                          levels = c("WT",
                                                     "SNV",
                                                     "deletion", "insertion",
                                                     "NA")))

        expr_mut_df %>%
            ggplot(aes(VARIANT_CLASS, norm_expression, 
                       color = VARIANT_CLASS,
                       shape = VARIANT_CLASS)) +
            geom_jitter() +
            geom_boxplot(color = "black", width = 0.3,
                         alpha = 0.7, outlier.shape = NA) +
            facet_wrap(~Hugo_Symbol) +
            theme_classic() +
            scale_color_simpsons() +
            theme(legend.position = "none", 
                  text = element_text(size = 20)) +
            labs(y = "vst normalized expression",
                 x = "Variant classification")
        
    })
    
    output$expr_subtype <-
        renderPlot({
            expression_vals() %>%
                left_join(tcga_subtype_data, 
                          by = c("patient_id" = "patient")) %>%
                ggplot(aes(`Transcriptome.Subtype`, norm_expression, 
                           color = `Transcriptome.Subtype`)) +
                geom_jitter() +
                geom_boxplot(color = "black", width = 0.3,
                             alpha = 0.7, outlier.shape = NA) +
                facet_wrap(~Hugo_Symbol) +
                theme_classic() +
                scale_color_futurama() +
                theme(legend.position = "none", 
                      text = element_text(size = 20)) +
                labs(y = "vst normalized expression",
                     x = "Transcriptome based subtype")
        })
}

# Run the application 
shinyApp(ui = ui, server = server)
