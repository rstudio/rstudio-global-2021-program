library(googlesheets4)
library(dplyr)
library(lubridate)

source("_helpers.R")

url <- "https://docs.google.com/spreadsheets/d/1M6tEh7LBb0VejHSwfxE-6Fvn7kQJIPYrIyhH9UqCcpk/edit#gid=1179995302"
if (!exists("speaker_program_df")) {
  speaker_program_df <- read_sheet(url, sheet = "speaker-program")
}

url2 <- "https://docs.google.com/spreadsheets/d/19NMt0A9vXzUV5eNhGkUPY3r7dFSsXcgPx4GAnxnU2ds/edit#gid=0"
if (!exists("host_df")) {
  host_df <- read_sheet(url2, sheet = "hosts") %>%
    rowwise() %>%
    mutate(hosts = paste(collapse = " and ", na.omit(c(name, `co-host`)))) %>%
    ungroup() %>%
    select(block, track, session_topic, hosts)
}

stopifnot(all(table(speaker_program_df$talk_id) == 2))

df <- speaker_program_df %>%
  mutate(base_time = parse_date_time(`Europe/London`, "m d, H:M p") %>% `year<-`(2021)) %>%
  mutate(duration_secs = case_when(
    is.na(actual_duration) ~ duration * 60,
    TRUE ~ suppressWarnings(period_to_seconds(ms(actual_duration)))
  )) %>%
  select(talk_id, block, track, name, actual_duration, order, base_time, duration_secs)

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
  summarise(.groups = "drop", name = paste(name, collapse = ", "), start = min(precise_start), discuss_start = max(precise_end)) %>%
  arrange(block, sub_block, track) %>%
  mutate(discuss_end = case_when(
    is.na(track) ~ lubridate::ceiling_date(discuss_start, unit = "hours") + lubridate::minutes(20),
    TRUE ~ lubridate::ceiling_date(discuss_start, unit = "hours")
  )) %>%
  mutate(discuss_duration = as.double(discuss_end - discuss_start, units = "secs")) %>%
  left_join(session_df, by = c("block", "track")) %>%
  left_join(host_df, by = c("block", "track")) %>%
  mutate(topic = case_when(
    is.na(track) ~ paste(sep = "/", "Discussion", session),
    TRUE ~ paste(sep = "/", "Discussion", paste("Track", track), session)
  )) %>%
  mutate(title = case_when(
    is.na(track) ~ paste0("Q&A: ", name),
    TRUE ~ paste0("Discussion: ", session, " ", sub_block)
  )) %>%
  mutate(description = case_when(
    is.na(track) ~ paste0("Join ", hosts, " for audience Q&A with keynote speaker ", name, "."),
    TRUE ~ paste0("Join ", hosts, " for audience Q&A with the preceding speakers in this session.")
  )) %>%
  mutate(summary = case_when(
    is.na(track) ~ paste0("Live audience Q&A with keynote speaker ", name, "."),
    TRUE ~ paste0("Live audience Q&A and discussion with session hosts and speakers for the ",
      ifelse(sub_block == 1, "first", "second"),
      " half of the \"",
      session,
      "\" session.")
  )) %>%
  select(topic, block, track, title, summary, description, start_time = discuss_start, duration = discuss_duration)

readr::write_csv(df5 %>% select(-topic), "discussion_sessions_normalized.csv")

df6 <- df5 %>%
  arrange(start_time) %>%
  group_by(topic, title, summary, duration) %>%
  summarise(.groups = "drop",
    time1 = intellum_datetime(start_time[[1]]),
    desc1 = description[[1]],
    time2 = intellum_datetime(start_time[[2]]),
    desc2 = description[[2]]
  ) %>%
  arrange(time1)

readr::write_csv(df6, "discussion_sessions.csv")
# googlesheets4::gs4_create(, sheets = df6)
