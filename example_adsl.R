# Example: Basic ADSL derivation pattern (inspired by admiral)
# This is a simplified illustration. For real work, use the full admiral package
# and follow your company's validated templates.

library(dplyr)
library(admiral)
library(pharmaversesdtm)

# Load example SDTM data (CDISC Pilot style)
data("dm", package = "pharmaversesdtm")
data("ex", package = "pharmaversesdtm")
data("ds", package = "pharmaversesdtm")

dm <- convert_blanks_to_na(dm)
ex <- convert_blanks_to_na(ex)

# Start ADSL from DM
adsl <- dm %>%
  mutate(
    TRT01P = ARM,
    TRT01A = ACTARM
  )

# Derive treatment start/end dates (simplified)
ex_ext <- ex %>%
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "EXST"
  ) %>%
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN"
  )

adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = !is.na(EXSTDTM),
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first",
    by_vars = exprs(STUDYID, USUBJID)
  ) %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = !is.na(EXENDTM),
    new_vars = exprs(TRTEDTM = EXENDTM, TRTETMF = EXENTMF),
    order = exprs(EXENDTM, EXSEQ),
    mode = "last",
    by_vars = exprs(STUDYID, USUBJID)
  )

# Convert datetimes to dates
adsl <- adsl %>%
  derive_vars_dtm_to_dt(exprs(TRTSDTM, TRTEDTM))

# Example: Analysis population flags (simplified logic)
adsl <- adsl %>%
  mutate(
    SAFFL = if_else(!is.na(TRTSDT), "Y", "N"),
    ITTFL = if_else(ARM != "Screen Failure", "Y", "N")
  )

# View structure
glimpse(adsl)

# In production you would continue with more derivations
# (baseline, disposition, age groups, etc.) and then
# export with xportr for XPT files.
