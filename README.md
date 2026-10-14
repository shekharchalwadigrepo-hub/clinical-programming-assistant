# Clinical Programming Assistant

Shiny application with an integrated LLM chatbot specialized for clinical trial programming (CDISC **SDTM**, **ADaM**, and **TLFs**).

The chatbot is designed to help with:
- SDTM mapping specifications and code generation
- ADaM dataset derivations (especially using `{admiral}` patterns)
- Tables, Listings, and Figures (TLF) code
- Explanations of CDISC variables and standards

> **Important**: Generated code and datasets require full human review, validation, and traceability before use in any regulated submission. Do not send real patient data or PHI to external LLM APIs without proper safeguards.

## Features

- Modern chat UI via `{shinychat}` + `{ellmer}`
- System prompt tuned for clinical programming
- Ready for local development and Posit Connect deployment
- Example ADaM derivation script (`example_adsl.R`)
- Extensible for data upload, tool calling, and RAG

## Project Structure

```
.
├── app.R                 # Main Shiny application
├── example_adsl.R        # Example ADaM (ADSL) derivation using admiral style
├── README.md
├── LICENSE
├── .gitignore
└── clinical-programming-assistant.Rproj
```

## Prerequisites

- R ≥ 4.1
- An LLM API key (OpenAI, Anthropic, or local model via Ollama)
- (Optional) Posit Connect account for publishing

## Quick Start

1. Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/clinical-programming-assistant.git
cd clinical-programming-assistant
```

2. Create a `.Renviron` file in the project root (never commit this file):

```
OPENAI_API_KEY=sk-your-key-here
# Alternatives:
# ANTHROPIC_API_KEY=sk-ant-...
# Or use Ollama locally (no key needed)
```

3. Install dependencies:

```r
install.packages(c(
  "shiny", "bslib", "shinychat", "ellmer",
  "admiral", "pharmaversesdtm", "dplyr", "haven", "rsconnect"
))
```

4. Run the app:

```r
shiny::runApp()
```

## Deploying to Posit Connect

```r
# First time only
rsconnect::connectUser()          # or connectCloudUser() for Connect Cloud

# Deploy (do not include .Renviron)
rsconnect::deployApp(
  appDir = ".",
  appTitle = "Clinical Programming Assistant",
  launch.browser = TRUE
)
```

On the Connect server, add the API key as an environment variable / secret (Settings → Variables).

## Customizing the Chatbot

Edit the `system_prompt` in `app.R` to add:
- Your company’s coding standards
- Preferred packages or templates
- Study-specific rules

You can also switch providers:

```r
# OpenAI
chat <- ellmer::chat_openai(model = "gpt-4o-mini", system_prompt = system_prompt)

# Anthropic
chat <- ellmer::chat_anthropic(model = "claude-3-5-sonnet-latest", system_prompt = system_prompt)

# Local Ollama
chat <- ellmer::chat_ollama(model = "llama3.1", system_prompt = system_prompt)
```

## Next Development Ideas

- Data upload tab that injects schema / specs into the chat context
- Tool calling so the model can execute admiral functions or query uploaded data
- RAG over CDISC Implementation Guides and internal standards
- Metadata-driven code generation pipelines
- Integration with `{sdtm.oak}` for raw → SDTM

## License

MIT License – see [LICENSE](LICENSE).

## Disclaimer

This is a developer tool / accelerator. It does not replace validated programming processes, quality control, or regulatory review. Use at your own risk and always validate outputs.
