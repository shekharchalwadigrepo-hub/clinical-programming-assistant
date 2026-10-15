library(shiny)
library(bslib)
library(shinychat)
library(ellmer)

# ----- System Prompt -----
system_prompt <- "
You are an expert clinical statistical programmer AI agent specializing in CDISC standards.

You have tools available:
- explain_cdisc: Explain SDTM/ADaM concepts
- generate_admiral_code: Generate admiral-style R code

Always use the appropriate tool when the user asks for explanations or code.
Be precise, mention assumptions, and remind users that code needs validation.
"

# ----- Tools -----
explain_cdisc <- tool(
  function(topic) {
    responses <- list(
      "DM" = "DM (Demographics) is a Special-Purpose SDTM domain. It contains one record per subject with key variables: USUBJID, SUBJID, RFSTDTC, AGE, SEX, RACE, ETHNIC, ARM, ACTARM, COUNTRY, etc.",
      "AE" = "AE (Adverse Events) is an Events domain. Key variables include AESEQ, AETERM, AEDECOD, AEBODSYS, AESEV, AESER, AESTDTC, AEENDTC, AEREL.",
      "ADSL" = "ADSL is the Subject-Level Analysis Dataset (ADaM). One record per subject. It includes treatment variables (TRT01P/A), population flags (SAFFL, ITTFL), baseline characteristics, and disposition.",
      "AVAL" = "AVAL is the Analysis Value in ADaM Basic Data Structure (BDS) datasets. It is the numeric result used for statistical analysis.",
      "PARAMCD" = "PARAMCD is the Parameter Code in ADaM BDS datasets. It is a short code identifying the analysis parameter (e.g. ALT, SYSBP)."
    )
    responses[[toupper(topic)]] %||% paste("No detailed information available for:", topic)
  },
  name = "explain_cdisc",
  description = "Explain a CDISC SDTM domain or ADaM variable/concept.",
  arguments = list(
    topic = type_string("The topic to explain (e.g. DM, AE, ADSL, AVAL)")
  )
)

generate_admiral_code <- tool(
  function(derivation) {
    deriv <- toupper(derivation)
    if (grepl("TRTSDTM|TRTSDT", deriv)) {
      return("
# Derive treatment start datetime (TRTSDTM)
adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex,
    filter_add = !is.na(EXSTDTC),
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    mode = 'first',
    by_vars = exprs(STUDYID, USUBJID)
  )
")
    }
    if (grepl("SAFFL", deriv)) {
      return("
# Safety population flag
adsl <- adsl %>%
  mutate(SAFFL = if_else(!is.na(TRTSDT), 'Y', 'N'))
")
    }
    if (grepl("BASE", deriv)) {
      return("
# Baseline value (example for BDS)
adxx <- adxx %>%
  derive_var_base(
    by_vars = exprs(STUDYID, USUBJID, PARAMCD),
    source_var = AVAL,
    new_var = BASE
  )
")
    }
    paste("Code template for", derivation, "is not yet defined. Please ask for a specific derivation.")
  },
  name = "generate_admiral_code",
  description = "Generate example R code using admiral for an ADaM derivation.",
  arguments = list(
    derivation = type_string("What to derive (e.g. TRTSDTM, SAFFL, BASE)")
  )
)

# ----- UI -----
ui <- page_navbar(
  title = "Clinical Programming Agent",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  nav_panel(
    "Chat",
    layout_sidebar(
      sidebar = sidebar(
        title = "Try these prompts",
        tags$ul(
          tags$li("What is the DM domain?"),
          tags$li("Explain ADSL"),
          tags$li("Generate admiral code for TRTSDTM"),
          tags$li("How do I create SAFFL?"),
          tags$li("What is AVAL?")
        ),
        width = 280
      ),
      chat_ui("chat", height = "650px")
    )
  )
)

# ----- Server -----
server <- function(input, output, session) {
  # Create the agent
  agent <- ellmer::chat_ollama(
    model = "qwen2.5:3b",
    system_prompt = system_prompt
  )
  
  # Register tools
  agent$register_tool(explain_cdisc)
  agent$register_tool(generate_admiral_code)
  
  # Handle chat
  observeEvent(input$chat_user_input, {
    stream <- agent$stream_async(!!!input$chat_user_input)
    chat_append("chat", stream)
  })
}

shinyApp(ui, server)


# library(shiny)
# library(bslib)
# library(shinychat)
# library(ellmer)
# 
# # Define the system prompt first
# system_prompt <- "
# You are an expert clinical statistical programmer specializing in CDISC standards.
# 
# You help users with:
# - Creating and reviewing SDTM mapping specifications and code (raw → SDTM)
# - Building ADaM datasets (especially using the admiral R package patterns)
# - Generating Tables, Listings, and Figures (TLFs)
# - Explaining CDISC variables, derivations, and controlled terminology
# - Writing clean, traceable, and validated R or SAS code
# 
# Always:
# - Prefer admiral functions for ADaM when appropriate
# - Emphasize traceability and validation
# - Point out assumptions and potential issues
# - Provide complete, runnable code examples when asked
# - Remind users that outputs need human review and validation for regulatory use
# 
# Never invent clinical results or claim a dataset is fully validated.
# "
# 
# ui <- page_navbar(
#   title = "Clinical Programming Assistant",
#   theme = bs_theme(version = 5, bootswatch = "flatly"),
#   nav_panel(
#     "Chat",
#     layout_sidebar(
#       sidebar = sidebar(
#         title = "Instructions",
#         p("Ask for SDTM mappings, ADaM derivations, TLF code, or explanations of CDISC concepts."),
#         width = 300
#       ),
#       chat_ui("chat", height = "600px")
#     )
#   )
# )
# 
# server <- function(input, output, session) {
#   chat <- ellmer::chat_ollama(
#     model = "qwen2.5:3b",
#     system_prompt = system_prompt
#   )
#   
#   observeEvent(input$chat_user_input, {
#     stream <- chat$stream_async(!!!input$chat_user_input)
#     chat_append("chat", stream)
#   })
# }
# 
# shinyApp(ui, server)