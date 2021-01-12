library(googlesheets4)
library(dplyr)
library(lubridate)

url <- "https://docs.google.com/spreadsheets/d/1M6tEh7LBb0VejHSwfxE-6Fvn7kQJIPYrIyhH9UqCcpk/edit#gid=1179995302"
if (!exists("speaker_program_df")) {
  speaker_program_df <- read_sheet(url, sheet = "speaker-program")
}

stopifnot(all(table(speaker_program_df$talk_id) == 2))

df <- speaker_program_df %>%
  mutate(base_time = parse_date_time(`Europe/London`, "m d, H:M p") %>% `year<-`(2020)) %>%
  mutate(duration_secs = case_when(
    is.na(actual_duration) ~ duration * 60,
    TRUE ~ suppressWarnings(period_to_seconds(ms(actual_duration)))
  )) %>%
  select(talk_id, block, track, actual_duration, order, base_time, duration_secs)

df2 <- df %>% mutate(sub_block = case_when(
  is.na(order) ~ NA_character_,
  order < 3 ~ "top",
  order >= 3 ~ "bottom"
))

df3 <- df2 %>%
  group_by(block, track, sub_block) %>%
  mutate(offset = ifelse(sub_block == "bottom", 60*60, 0) + cumsum(duration_secs) - duration_secs) %>%
  ungroup() %>%
  mutate(precise_start = base_time + seconds(offset))

df4 <- df3 %>%
  select(talk_id, start = precise_start, duration = duration_secs)

readr::write_csv(df4, "talk_times.csv")
