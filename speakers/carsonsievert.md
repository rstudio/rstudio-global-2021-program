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

# Custom Styling in Shiny & R Markdown with bootstraplib & thematic

Custom styling of Shiny and R Markdown often requires writing styling rules in both CSS and R. In particular, styles for HTML content (e.g., actionButton(), tabsetPanel(), titlePanel(), etc) derive from Bootstrap CSS, so customization is often done by overwriting that CSS, which is difficult to do 100% correctly. The bootstraplib package helps solve this problem by making it easy to customize (any version of) Bootstrap CSS from R. However, this only solves part of the problem since CSS doesn't necessarily effect output(s) rendered by R, such as plotOutput(). The thematic package helps solve this problem by providing auto theming of plotOutput()s (based on CSS) as well as a simple interface for styling any R graphic for any output format.

# Speaker bio

Carson Sievert is a human person.
