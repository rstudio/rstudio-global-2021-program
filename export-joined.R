library(dplyr)
source("_helpers.R", local = TRUE)

talks <- readr::read_csv("simple_schedule.csv")
discussion <- readr::read_csv("discussion_sessions_normalized.csv") %>%
  rename(title_text = title) %>%
  rename(abstract_text = description) %>%
  mutate(abstract_html = paste0("<p>",
    vapply(abstract_text, htmltools::htmlEscape, character(1)),
    "</p>"
  )) %>%
  mutate(type = "discussion") %>%
  rename(time_gmt = start_time) %>%
  left_join(session_df, c("block", "track")) %>%
  rename(topic = session) %>%
  select(-summary)

full <- bind_rows(talks, discussion) %>% arrange(block, track, time_gmt)

readr::write_csv(full, "full_schedule.csv")

print(processx::run("aws", c(
  "s3",
  "cp",
  rprojroot::find_rstudio_root_file("full_schedule.csv"),
  "s3://rstudio-global-2021/schedule.csv"
)))
