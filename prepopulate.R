library(dplyr)
library(purrr)
library(yaml)

slugify <- . %>% gsub("[ -]+", "", .) %>% tolower()

speaker_details_url <- "https://docs.google.com/spreadsheets/d/1PKlltk03RD9jAxMCKnMGOiFaMTpC_j0SYT47OzI3aDk/edit#gid=2077809528"

speakers <- googlesheets4::read_sheet(speaker_details_url)
speakers <- speakers %>% select(
  name = `What's your name?`,
  email = `Email Address`,
  affiliation = `What's your affiliation?`,
  country = `What country do you live in?`,
  tz = `What's your time zone?`
) %>% mutate(.before = 1, slug = slugify(name))

speakers$country <- speakers$country %>%
  gsub("U.S.", "United States", ., fixed = TRUE) %>%
  gsub("^USA?$", "United States", .) %>%
  gsub("UK", "United Kingdom", ., fixed = TRUE)

submissions_url <- "https://docs.google.com/spreadsheets/d/1b9Kr--fqvNk-fVse9APvWdSCwHtPx61iHhQPULflEIk/edit#gid=1099129659"
submissions <- googlesheets4::read_sheet(submissions_url) %>%
  filter(decision == "accept") %>%
  mutate(speaker_slug = slugify(name))

# Some speakers submitted their proposal by one name, but gave a subtly
# different name when asked for their details. We'll use the latter,
# because it was more recent.
submissions_to_speakers <- c(andrewbatran = "andrewtran",
  ericcronstrom = "ericgunnarcronstrom",
  meganbeckettandandrewcollier = "meganbeckett",
  michaelpage = "mikepage",
  rika = "rikagorn"
)
replace_idx <- match(submissions$speaker_slug, names(submissions_to_speakers))
submissions$speaker_slug[which(!is.na(replace_idx))] <- submissions_to_speakers[na.omit(replace_idx)]

joined <- submissions %>% full_join(speakers, by = c(speaker_slug = "slug"))

# Hack to join mattthomas to mikepage
joined$id[joined$speaker_slug == "mattthomas"] <- joined[joined$speaker_slug == "mikepage", "id"]

yaml_null <- structure("null", class = "verbatim")

# == Create speakers/*.md ========

dir.create("speakers", showWarnings = FALSE)
unlink(list.files("speakers", pattern = "*.md", full.names = TRUE))

joined %>%
  pwalk(function(...) {
    s <- tibble(...)
    destfile <- file.path("speakers", paste0(s$speaker_slug, ".md"))

    f <- file(destfile, "w+")
    on.exit(close(f))

    writeLines("---", f)
    yaml::write_yaml(list(
      talk_id = as.integer(s$id),
      name = s$name.y,
      affiliation = s$affiliation,
      links = list(
        homepage = yaml_null,
        twitter = yaml_null,
        github = yaml_null,
        linkedin = yaml_null
      ),
      location = s$country
    ), f)
    writeLines(c("---", ""), f)

    # Talk title/abstract
    writeLines(paste0("# ", s$title), f)
    writeLines("", f)
    writeLines(s$abstract, f)
    writeLines("", f)

    # Bio
    writeLines(paste0("# Speaker bio"), f)
    writeLines("", f)
    writeLines(paste0(s$name.y, " is a human person."), f)
  })

# # == Create talks/*.md ========
#
# dir.create("talks", showWarnings = FALSE)
# unlink(list.files("talks", pattern = "*.md", full.names = TRUE))
#
# joined %>%
#   pwalk(function(...) {
#     s <- tibble(...)
#     destfile <- file.path("talks", paste0(s$speaker_slug, ".md"))
#
#     f <- file(destfile, "w+")
#     on.exit(close(f))
#
#     writeLines("---", f)
#     yaml::write_yaml(list(
#       title = s$title,
#       links = list(
#         slides = yaml_null,
#         code = yaml_null
#       )
#     ), f)
#     writeLines(c("---", ""), f)
#     writeLines(paste0(s$name.y, " is a human person."), f)
#   })
