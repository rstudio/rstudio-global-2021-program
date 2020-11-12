---
talk_id: 293
type: talk
name: Aaron Jacobs
affiliation: Crescendo Technology
links:
  homepage: null
  twitter: null
  github: null
  linkedin: null
location: Canada
---

# Introducing xrprof: A New Way to Profile R

This talk will introduce the xrprof project, a new sampling profiler for R. Unlike existing tools, it can be used to profile R code that is already running -- in fact, it is designed to be safe to point at R code running "in production", while working with existing R tools.

Taking inspiration from the {jointprof} package, xrprof can also show function calls at the C/C++ level alongside those from R. This can be immensely useful for diagnosing problems in packages that make heavy use of compiled code.

xrprof is available as a standalone program for Linux and Windows, or as an R package. It also works seamlessly when R is run inside Docker, and can even be run in complex environments like Kubernetes clusters.

# Speaker bio

Aaron Jacobs is a human person.
