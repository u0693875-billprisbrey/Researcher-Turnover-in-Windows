# Script to render parameterized reports


# BRUTE FORCE
rmarkdown::render(
  here::here("Reports and Analyses", "Demonstrating Brute Force Fit.Rmd"),
  params = list(showPI = FALSE, showAll = TRUE),
  output_file = here::here("Reports and Analyses", "Demonstrating Brute Force Fit for All Employees.html")
  )

rmarkdown::render(
  here::here("Reports and Analyses", "Demonstrating Brute Force Fit.Rmd"),
  params = list(showPI = TRUE, showAll = FALSE),
  output_file = here::here("Reports and Analyses", "Demonstrating Brute Force Fit for PIs.html")
)
