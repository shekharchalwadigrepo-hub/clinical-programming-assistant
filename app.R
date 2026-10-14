library(shiny)
library(bslib)
library(shinychat)
library(ellmer)

# Define the system prompt first
system_prompt <- "
You are an expert clinical statistical programmer specializing in CDISC standards.

You help users with:
- Creating and reviewing SDTM mapping specifications and code (raw → SDTM)
- Building ADaM datasets (especially using the admiral R package patterns)
- Generating Tables, Listings, and Figures (TLFs)
- Explaining CDISC variables, derivations, and controlled terminology
- Writing clean, traceable, and validated R or SAS code

Always:
- Prefer admiral functions for ADaM when appropriate
- Emphasize traceability and validation
- Point out assumptions and potential issues
- Provide complete, runnable code examples when asked
- Remind users that outputs need human review and validation for regulatory use

Never invent clinical results or claim a dataset is fully validated.
"

ui <- page_navbar(
  title = "Clinical Programming Assistant",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  nav_panel(
    "Chat",
    layout_sidebar(
      sidebar = sidebar(
        title = "Instructions",
        p("Ask for SDTM mappings, ADaM derivations, TLF code, or explanations of CDISC concepts."),
        width = 300
      ),
      chat_ui("chat", height = "600px")
    )
  )
)

server <- function(input, output, session) {
  chat <- ellmer::chat_ollama(
    model = "qwen2.5:3b",
    system_prompt = system_prompt
  )
  
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(!!!input$chat_user_input)
    chat_append("chat", stream)
  })
}

shinyApp(ui, server)