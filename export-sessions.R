library(magrittr)
library(parsermd)
library(commonmark)
library(yaml)
library(dplyr)
library(htmltools)
library(tidyr)

source("_helpers.R")

`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}

blocknames <- c("alfa", "bravo", "charlie", "delta", "echo", "foxtrot", "golf",
  "hotel", "india", "juliett", "kilo", "lima")
blocktimes <- unlist(read_yaml("block-times-gmt.yml"))

talk_times <- readr::read_csv("talk_times.csv") %>%
  group_by(talk_id) %>%
  summarise(.groups = "drop",
    time1 = start[[1]], time2 = start[[2]], duration = mean(duration)
  )

sessionnames <- read_yaml("session-names.yml")

normalize_social <- function(x, url_prefix) {
  if (is.null(x)) {
    return(NA_character_)
  }

  x <- sub("^@", "", x, perl = TRUE)

  if (grepl("^[\\da-zA-Z_]+$", x)) {
    paste0(url_prefix, x)
  } else if (grepl(url_prefix, x, fixed = TRUE)) {
    x
  } else if (grepl(sub("www\\.linkedin\\.", "linkedin\\.", url_prefix), x, fixed = TRUE)) {
    x
  } else {
    stop("Unexpected URL: ", x)
  }
}

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

  talk_title <- rmd[[2]]$name %>% markdown_html %>% sub("^<p>", "", .) %>% sub("</p>\n?$", "", .)
  talk_title_text <- rmd[[2]]$name %>% markdown_text %>% sub("\n+$", "", .)
  talk_abstract_html <- rmd[[3]] %>% as_document %>% markdown_html
  talk_abstract_text <- rmd[[3]] %>% as_document %>% markdown_text

  speaker_bio <- rmd[[5]] %>% as_document %>% markdown_html
  if (grepl("is a human person.</p>", speaker_bio)) {
    speaker_bio <- ""
  }
  speaker_bio_text <- rmd[[5]] %>% as_document %>% markdown_text
  if (grepl("is a human person.", speaker_bio_text)) {
    speaker_bio_text <- ""
  }

  speaker <- unclass(rmd[[1]])

  # Sanity check blocks
  blocks <- speaker$blocks
  stopifnot(length(blocks) == 2)
  stopifnot(all(blocks %in% blocknames))
  block1_index <- which(blocknames == blocks[[1]])
  stopifnot(length(block1_index) == 1)
  stopifnot(identical(blocknames[block1_index + 6], blocks[[2]]))

  if (!is.null(speaker$links$homepage)) {
    with(httr::parse_url(speaker$links$homepage), {
      stopifnot(!is.null(scheme))
      stopifnot(!is.null(hostname))
    })
  }

  speaker$links$homepage <- if (!is.null(speaker$links$homepage)) speaker$links$homepage else NA_character_
  speaker$links$twitter <- normalize_social(speaker$links$twitter, "https://twitter.com/")
  speaker$links$github <- normalize_social(speaker$links$github, "https://github.com/")
  speaker$links$linkedin <- normalize_social(speaker$links$linkedin, "https://www.linkedin.com/in/")

  links <- list(
    Homepage = speaker$links$homepage,
    Twitter = speaker$links$twitter,
    GitHub = speaker$links$github,
    LinkedIn = speaker$links$linkedin
  )
  links <- links[!vapply(links, is.na, logical(1))]

  links_html <- if (length(links) > 0) {
    htmltools::p(class = "speaker-links",
      mapply(names(links), links, FUN = function(nm, url) {
        if (!is.na(url)) {
          htmltools::tags$a(href = url,
            htmltools::tags$img(
              src = paste0("https://rstudio-global-2021.s3.amazonaws.com/icons/", tolower(nm), ".png"),
              alt = nm,
              style = "border: none; width: 20px; height: 20px;"
            )
          )
        }
      }, SIMPLIFY = FALSE, USE.NAMES = FALSE)
    ) %>% as.character()
  }

  # TODO: Check speaker metadata requirements

  stopifnot(length(speaker_bio) == 1)
  stopifnot(length(links_html) <= 1)

  slug <- tools::file_path_sans_ext(basename(filename))

  headshot <- list.files(path = rprojroot::find_rstudio_root_file("speakers"),
    pattern = paste0(slug, "\\.(png|jpg)$"))
  stopifnot(length(headshot) <= 1)
  headshot <- if (length(headshot) == 1) {
    paste0("https://rstudio-global-2021.s3.amazonaws.com/speakers/", headshot)
  } else {
    ""
  }

  # Flatten structure so all members are single-element vectors. This will make
  # data framing everything easier.
  speaker$block_1 <- speaker$blocks[[1]]
  speaker$block_2 <- speaker$blocks[[2]]
  speaker$blocks <- NULL
  speaker <- c(speaker, speaker$links)
  speaker$links <- NULL

  speaker <- lapply(speaker, `%||%`, b = "")

  as_tibble(c(
    speaker,
    summary = speaker_bio,
    summary_text = speaker_bio_text,
    bio = paste0(speaker_bio, links_html),
    headshot = headshot,
    speaker_slug = slug,
    title = talk_title,
    title_text = talk_title_text,
    abstract = talk_abstract_html,
    abstract_text = talk_abstract_text
  ))
}

speakers <- list.files("speakers", pattern = "*.md", full.names = TRUE) %>%
  lapply(parse_file) %>%
  bind_rows() %>%
  arrange(tolower(name)) %>%
  left_join(talk_times, by = "talk_id")

talk_labels <- c(lightning = "Lightning Talk", talk = "Talk", keynote = "Keynote")

df <- speakers %>%
  # mutate(time1 = blocktimes[block_1], time2 = blocktimes[block_2]) %>%
  select(name, affiliation, headshot, summary, bio)

readr::write_csv(df, "export.csv")
# googlesheets4::gs4_create(, sheets = df)

df2 <- speakers %>%
  left_join(session_df, by = c("block_1" = "block", "track")) %>%
  mutate(topic = paste0(talk_labels[type],
    ifelse(type != "keynote", paste0("/Track ", track, "/", session), "")
  )) %>%
  select(
    talk_id,
    topic,
    title,
    abstract = abstract_text,
    speaker = name,
    speaker_summary = summary_text, time1, time2, duration) %>%
  mutate(time1 = intellum_datetime(time1), time2 = intellum_datetime(time2)) %>%
  group_by(talk_id, topic, title, abstract, time1, time2, duration) %>%
  summarise(.groups = "drop",
    speaker_info = paste(collapse = "\n",
      mapply(speaker, speaker_summary, FUN = function(name, summary) {
        paste0("Speaker: ", name, "\n\n", summary)
      })
    )
  ) %>%
  mutate(abstract_with_bio = paste(sep = "\n", abstract, speaker_info), .after = "abstract") %>%
  select(-speaker_info)

df2_sorted <- df2[match(unique(speakers$talk_id), df2$talk_id),]
stopifnot(nrow(df2_sorted) == nrow(df2))
df2 <- df2_sorted

readr::write_csv(df2, "export_sessions.csv")
# googlesheets4::gs4_create(, sheets = df2)

session_to_speakers <- speakers %>%
  select(session = title, name) %>%
  group_by(session) %>%
  summarise(name = paste(name, collapse = ", "))

speaker_to_session <- speakers %>%
  select(name, session = title)

# googlesheets4::gs4_create(sheets = list(session_to_speakers = session_to_speakers, speaker_to_session = speaker_to_session))

# Resize images if necessary
jpeg_files <- list.files("speakers", pattern = "*.jpg", full.names = TRUE)
png_files <- list.files("speakers", pattern = "*.png", full.names = TRUE)

for (file in c(jpeg_files, png_files)) {
  img <- magick::image_read(file)
  if (magick::image_info(img)$width != 300) {
    message("Resizing ", file)
    img <- magick::image_resize(img, magick::geometry_size_pixels(300, preserve_aspect = TRUE))
    magick::image_write(img, file)
  }
}

if (TRUE) {

message("Syncing speaker headshots to S3")
# Upload speaker headshots to S3
print(processx::run("aws", c(
  "s3",
  "sync",
  "--exclude=*.md",
  rprojroot::find_rstudio_root_file("speakers"),
  "s3://rstudio-global-2021/speakers/"
)))

}


simple_schedule <- speakers %>%
  pivot_longer(starts_with("block_"), names_to = "block_num", values_to = "block") %>%
  mutate(time = ifelse(block_num == "block_1", format(time1), format(time2)), .after = "time2") %>%
  select(talk_id, type, block, track, name, title_text, time, duration) %>%
  # Group by everything but name
  group_by(talk_id, type, block, track, title_text, time, duration) %>%
  summarise(.groups = "drop", name = paste(name, collapse = "\n")) %>%
  relocate(name, .before = title_text) %>%
  arrange(block, time, track)

googlesheets4::write_sheet(simple_schedule,
  "https://docs.google.com/spreadsheets/d/1wYf7w-Elg5vSeZkKjRFeWzShVPXqDXJzy6vrYUyJm0c/edit#gid=0",
  "Sheet1")
