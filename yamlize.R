library(magrittr)
library(parsermd)
library(commonmark)
library(yaml)

blocknames <- c("alfa", "bravo", "charlie", "delta", "echo", "foxtrot", "golf",
  "hotel", "india", "juliett", "kilo", "lima")
blocktimes <- unlist(read_yaml("block-times-gmt.yml"))

normalize_social <- function(x, url_prefix) {
  if (is.null(x)) {
    return(NULL)
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

  talk_title <- rmd[[2]]$name
  talk_abstract_html <- rmd[[3]] %>% as_document %>% markdown_html

  speaker_bio <- rmd[[5]] %>% as_document %>% markdown_html
  if (grepl("is a human person.</p>", speaker_bio)) {
    speaker_bio <- ""
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

  speaker$links$twitter <- normalize_social(speaker$links$twitter, "https://twitter.com/")
  speaker$links$github <- normalize_social(speaker$links$github, "https://github.com/")
  speaker$links$linkedin <- normalize_social(speaker$links$linkedin, "https://www.linkedin.com/in/")

  links <- list(
    Homepage = speaker$links$homepage,
    Twitter = speaker$links$twitter,
    GitHub = speaker$links$github,
    LinkedIn = speaker$links$linkedin
  )
  links <- links[!vapply(links, is.null, logical(1))]

  links_html <- if (length(links) > 0) {
    htmltools::p(class = "speaker-links",
      mapply(names(links), links, FUN = function(nm, url) {
        if (!is.null(url)) {
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

  c(
    list(),
    speaker,
    bio = paste0(speaker_bio, links_html),
    headshot = headshot,
    speaker_slug = slug,
    title = talk_title,
    abstract = talk_abstract_html
  )
}

parsed_speakers <- list.files("speakers", pattern = "*.md", full.names = TRUE) %>%
  lapply(parse_file)
pluck_chr <- function(name, default = "") {
  vapply(parsed_speakers, function(x) {
    res <- x[[name]]
    if (is.null(res)) {
      default
    } else if (is.character(res) && length(res) == 1) {
      res
    } else {
      stop("Unexpected value: ", deparse(res))
    }
  }, character(1))
}

# last_names <- full_names %>% strsplit(" ") %>% lapply(tail, n = 1) %>% unlist()
parsed_speakers <- parsed_speakers[order(tolower(pluck_chr("name")))]
# rm(last_names)

full_names <- pluck_chr("name")

talk_type <- pluck_chr("type")
location <- pluck_chr("location")

tracks <- pluck_chr("track")
blocks <- vapply(parsed_speakers, magrittr::extract2, character(2), i = "blocks")
time1 <- blocktimes[blocks[1,,drop=TRUE]] %>% unname()
time2 <- blocktimes[blocks[1,,drop=TRUE]] %>% unname()

df <- tibble::tibble(
  name = full_names,
  affiliation = pluck_chr("affiliation"),
  headshot = pluck_chr("headshot"),
  bio = pluck_chr("bio"),
  time1,
  time2
)

readr::write_csv(df, "export.csv")

if (TRUE) {

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

message("Syncing speaker headshots to S3")
# Upload speaker headshots to S3
processx::run("aws", c(
  "s3",
  "sync",
  "--exclude=*.md",
  rprojroot::find_rstudio_root_file("speakers"),
  "s3://rstudio-global-2021/speakers/"
))

}
