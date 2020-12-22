library(magrittr)
library(parsermd)
library(commonmark)
library(yaml)

parse_file <- function(filename) {
  message(filename)
  rmd <- parse_rmd(filename)
  rmd_df <- as_tibble(rmd)

  if (!identical(rmd_df$type[[1]], "rmd_yaml_list")) {
    stop("Must begin with a YAML metadata block")
  }

  expected_types <- c("rmd_yaml_list", "rmd_heading", "rmd_markdown", "rmd_heading",  "rmd_markdown")
  if (!identical(rmd_df$type, expected_types)) {
    stop("Parsed rmd contained sections [",
      paste(rmd_df$type, collapse = ","),
      "]; we were expecting [",
      paste(expected_types, collapse = ","),
      "]")
  }

  talk_title <- rmd[[2]]$name
  talk_abstract_html <- rmd[[3]] %>% as_document %>% markdown_html

  speaker_bio <- rmd[[5]] %>% as_document %>% markdown_html

  speaker <- unclass(rmd[[1]])

  # TODO: Check speaker metadata requirements

  c(
    list(),
    speaker,
    bio = speaker_bio,
    speaker_slug = tools::file_path_sans_ext(basename(filename)),
    title = talk_title,
    abstract = talk_abstract_html
  )
}

parsed_speakers <- list.files("speakers", pattern = "*.md", full.names = TRUE) %>%
  lapply(parse_file)

# Sort by last name
full_names <- lapply(parsed_speakers, magrittr::extract2, i = "name") %>% unlist()
last_names <- full_names %>% strsplit(" ") %>% lapply(tail, n = 1) %>% unlist()
parsed_speakers <- parsed_speakers[order(tolower(last_names))]

talk_type <- vapply(parsed_speakers, magrittr::extract2, character(1), i = "type")

if (dir.exists("yaml_output")) {
  unlink("yaml_output", recursive = TRUE)
}
dir.create("yaml_output")

write_yaml(parsed_speakers[talk_type == "talk"], "yaml_output/talks.yml")
write_yaml(parsed_speakers[talk_type == "lightning"], "yaml_output/lightning.yml")

dir.create("yaml_output/speakers")
lapply(parsed_speakers, function(speaker) {
  write_yaml(speaker, file.path("yaml_output/speakers", paste0(speaker$speaker_slug, ".yml")))
}) %>% invisible()
