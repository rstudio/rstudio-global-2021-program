This repository contains files relating to the Program and Schedule for [rstudio::global 2021](https://rstudio.com/conference/). It includes:

-   The "master data" about speakers and talks

-   Scripts for converting that data to YAML for downstream processes to consume

## Instructions for speakers

(These instructions assume you're familiar with Git and GitHub. If you're not, you can simply email your final talk title, abstract, speaker bio, and headshot to joe@rstudio.com with the subject "Program details".)

1.  Find your Markdown file under the `speakers/` directory.

    1.  Ensure the existing metadata is correct, and fill out any of the `null` links. (Do not add additional fields, they will be ignored.)

    2.  Edit the talk title and abstract. (Markdown is allowed, but it's probably best to stick to simple formatting.)

    3.  Fill out the speaker bio paragraph.

2.  **Provide a square headshot** by uploading a .jpg or .png to the `speakers/` directory. The filename must match your Markdown file, except for the file extension. (For example, Sean Lopp has `speakers/seanlopp.md`, so his headshot would need to be `speakers/seanlopp.jpg` or `speakers/seanlopp.png`.)

3.  Submit your changes as a PR and someone on the program committee will approve ASAP.

**You don't need to run any of the scripts in this repo**--just edit your Markdown file and provide the headshot.

You may submit as many changes/PRs as you want, up until the deadline of December 25.

Thank you again for your participation in rstudio::global 2021!
