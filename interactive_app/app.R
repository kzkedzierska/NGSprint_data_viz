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
source("cosmic_genes.R") # I copied cosmic genes there, 
# read more about COSMIC census here: https://cancer.sanger.ac.uk/census
# essentially this is a list of genes recognized as cancer genes

maf_data <- readRDS("data/maf_data_df.RDS")
normalized_counts <- readRDS("data/normalized_counts.RDS")
patient_ids <- colnames(normalized_counts)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("LGG - interactive expression plots"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectizeInput(inputId = "genes_to_plot",
                        label = "Genes to plot:",
                        choices = cosmic_genes,
                        selected = "IDH1", 
                        options = list(maxItems = 8)),
            selectizeInput(inputId = "patients_to_plot",
                           label = "Pateints to plot:",
                           choices = patient_ids,
                           selected = c("TCGA-HW-7495", "TCGA-DU-6405"), 
                           options = list(maxItems = 8))
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("expr_mut_plot"),
           plotOutput("expr_mut_patient_plot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$expr_mut_patient_plot <- renderPlot({
        # generate bins based on input$bins from ui.R
        # which genes are we intersted in?
        
        patients_of_interest <- input$patients_to_plot
        genes_of_interest <- input$genes_to_plot


        expression_vals <-
            normalized_counts[genes_of_interest, patients_of_interest, drop = FALSE] %>%
            as.data.frame() %>%
            rownames_to_column("Hugo_Symbol") %>%
            pivot_longer(names_to = "patient_id",
                         values_to = "norm_expression",
                         cols = -Hugo_Symbol)
        
        
        expression_vals %>%
            ggplot(aes(Hugo_Symbol, norm_expression, fill = patient_id)) +
            geom_bar(position = "dodge", stat = "identity") +
            theme_classic()
    })

    output$expr_mut_plot <- renderPlot({
        # generate bins based on input$bins from ui.R
        # which genes are we intersted in?
        
        genes_of_interest <- input$genes_to_plot
        # this will allow us to distinguish between no infomration about mutation
        # and no mutation
        patient_muts <-
            maf_data %>%
            mutate(patient_id = str_extract(Tumor_Sample_Barcode,
                                            "[^-]{4}-[^-]{2}-[^-]{4}")) %>%
            pull(patient_id) %>%
            unique()

        expression_vals <-
            normalized_counts[genes_of_interest,, drop = FALSE] %>%
            as.data.frame() %>%
            rownames_to_column("Hugo_Symbol") %>%
            pivot_longer(names_to = "patient_id",
                         values_to = "norm_expression",
                         cols = -Hugo_Symbol)

        mutation_data <-
            maf_data %>%
            filter(Hugo_Symbol %in% genes_of_interest) %>%
            mutate(patient_id = str_extract(Tumor_Sample_Barcode,
                                            "[^-]{4}-[^-]{2}-[^-]{4}")) %>%
            dplyr::select(patient_id, Hugo_Symbol, VARIANT_CLASS)

        expr_mut_df <-
            full_join(expression_vals, mutation_data) %>%
            # introduce WT for samples with no mutation in the gene
            mutate(VARIANT_CLASS = as.character(VARIANT_CLASS),
                   VARIANT_CLASS = ifelse(is.na(VARIANT_CLASS),
                                          yes = ifelse(patient_id %in% patient_muts,
                                                       yes = "WT",
                                                       no = "NA"),
                                          no = VARIANT_CLASS),
                   VARIANT_CLASS = factor(VARIANT_CLASS,
                                          levels = c("WT",
                                                     "SNV",
                                                     "deletion", "insertion",
                                                     "NA")))

        expr_mut_df %>%
            ggplot(aes(VARIANT_CLASS, norm_expression, color = VARIANT_CLASS,
                       shape = VARIANT_CLASS)) +
            geom_jitter() +
            geom_boxplot(color = "black", width = 0.3,
                         alpha = 0.7, outlier.shape = NA) +
            facet_wrap(~Hugo_Symbol) +
            theme_classic() +
            theme(legend.position = "none") +
            labs(y = "vst normalized expression",
                 x = "Variant classification")
        
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
