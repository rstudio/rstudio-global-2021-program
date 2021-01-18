---
talk_id: 293
url: https://global.rstudio.com/student/page/40593
type: talk
track: C
blocks:
  - foxtrot
  - lima
name: Aaron Jacobs
affiliation: Crescendo Technology
links:
  homepage: https://unconj.ca
  twitter: https://twitter.com/unconj1
  github: https://github.com/atheriel
  linkedin: null
location: Toronto, Canada
---

# Introducing xrprof: A New Way to Profile R

Tracking down performance issues in R code usually means using R's built-in `Rprof()` profiler or one of the packages built around it. But the changing nature of the R community (towards more deployed applications) makes local profiling workflows frustrating, which is why I have written a new profiler: xrprof.

xprof is compatible with existing R tools, but unlike them it can be used to profile R code that is already running -- in fact, it is designed to be safe to point at R code running "in production". xrprof also works seamlessly when R is run inside Docker, and can even be run in complex environments like Kubernetes clusters.

Taking inspiration from the {jointprof} package, xrprof can also show function calls at the C/C++ level alongside those from R. This can be immensely useful for diagnosing problems in packages that make heavy use of compiled code.

# Speaker bio

Aaron Jacobs is a Senior Data Scientist on the R&D team at Crescendo, a technology company in the sports betting space with a large internal R ecosystem. Prior to Crescendo he worked in Canadian public policy research. Aaron has a strong interest in the engineering side of data science and the emerging use of R "in production". He is the author of several CRAN and GitHub packages, as well as xrprof -- a new R profiling tool.
