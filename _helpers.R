library(magrittr)

session_df <- local({
  sessionnames <- yaml::read_yaml("session-names.yml")

  mapply(names(sessionnames), sessionnames, FUN = function(nm, e) {
    if (is.list(e)) {
      tibble::tibble(block = rep_len(nm, length(e)), track = names(e), session = unlist(e))
    } else if (is.character(e)) {
      tibble::tibble(block = nm, track = NA_character_, session = e)
    }
  }, USE.NAMES = FALSE, SIMPLIFY = FALSE) %>% dplyr::bind_rows()
})

intellum_datetime <- . %>%
  lubridate::with_tz("America/New_York") %>%
  (lubridate::stamp("2008-01-30 14:30", "ymdHM"))
