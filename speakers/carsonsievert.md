---
talk_id: 163
type: lightning
name: Carson Sievert
affiliation: null
links:
  homepage: null
  twitter: null
  github: null
  linkedin: null
location: null
---

# Custom theming in Shiny & R Markdown with bslib & thematic

Custom theming in Shiny and R Markdown often requires writing styling rules in both CSS and R. In particular, styles for HTML content (e.g., `actionButton()`, `tabsetPanel()`, `titlePanel()`, etc) derive from Bootstrap CSS, so customization is traditionally done by overwriting that CSS, which is difficult to do 100% correctly. The `{bslib}` package helps solve this problem by making it easy to customize (any version of) Bootstrap CSS defaults from R. However, this only solves part of the problem since CSS doesn't necessarily effect output(s) rendered by R, such as `plotOutput()`. The thematic package helps solve this problem by providing auto theming of `plotOutput()`s (based on CSS) as well as a simple interface for styling any R graphic for any output format.

# Speaker bio

Carson is a software engineer at RStudio working on projects that bridge R with web technologies, such as `{shiny}`, `{bslib}`, `{thematic}`, and `{plotly}`. Before joining RStudio in late 2018, Carson worked as consultant, delivering analytical and scientific software to organizations such as the Library of Congress, NOAA, Sandia National Labs, and plotly. Carson began consulting part-time during his PhD in statistics at Iowa State, where his work on the R package `{plotly}` was recognized by the ASA with the 2017 Chambers Award. His book "Interactive data visualization with R, plotly, and shiny"" is freely available online at https://plotly-r.com.
