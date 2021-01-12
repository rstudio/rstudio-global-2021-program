library(googlesheets4)
library(dplyr)
library(lubridate)

source("_session_helpers.R")

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
  is.na(order) ~ NA_integer_,
  order < 3 ~ 1L,
  order >= 3 ~ 2L
))

df3 <- df2 %>%
  group_by(block, track, sub_block) %>%
  mutate(offset = ifelse(sub_block == 2, 60*60, 0) + cumsum(duration_secs) - duration_secs) %>%
  ungroup() %>%
  mutate(
    precise_start = base_time + seconds(offset),
    precise_end = precise_start + duration_secs
  )

df4 <- df3 %>%
  select(talk_id, start = precise_start, duration = duration_secs)

readr::write_csv(df4, "talk_times.csv")

df5 <- df3 %>%
  group_by(block, track, sub_block) %>%
  summarise(start = min(precise_start), discuss_start = max(precise_end)) %>%
  arrange(block, sub_block, track) %>%
  mutate(discuss_end = case_when(
    is.na(track) ~ lubridate::ceiling_date(discuss_start, unit = "hours") + lubridate::minutes(20),
    TRUE ~ lubridate::ceiling_date(discuss_start, unit = "hours")
  )) %>%
  mutate(discuss_duration = as.double(discuss_end - discuss_start, units = "secs")) %>%
  left_join(session_df, by = c("block", "track")) %>%
  mutate(topic = case_when(
    is.na(track) ~ paste(sep = "/", "Discussion", session),
    TRUE ~ paste(sep = "/", "Discussion", paste("Track", track), session)
  )) %>%
  mutate(title = case_when(
    is.na(track) ~ "Keynote Q&A",
    TRUE ~ paste0("Discussion: ", session, " ", sub_block)
  ))
