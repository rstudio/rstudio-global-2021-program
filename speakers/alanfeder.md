---
talk_id: 224
type: lightning
track: C
blocks:
  - delta
  - juliett
name: Alan Feder
affiliation: Invesco
links:
  homepage: null
  twitter: https://twitter.com/AlanFeder
  github: https://github.com/AlanFeder
  linkedin: https://www.linkedin.com/in/alanfeder/
location: New York City, NY, USA
---

# Categorical Embeddings: New Ways to Simplify Complex Data

When building a predictive model in R, many of the functions (such as `lm()`, `glm()`, `randomForest`, `xgboost`, or neural networks in `keras`) require that all input variables are numeric.  If your data has categorical variables, you may have to choose between ignoring some of your data and too many new columns.

Categorical embeddings are a relative new method, utilizing methods popularized in Natural Language Processing that help models solve this problem and can help you understand more about the categories themselves.

While there are a number of online tutorials on how to use Keras (usually in Python) to create these embeddings, this talk will use [`embed::step_embed()`](https://embed.tidymodels.org/reference/step_embed.html), an extension of the `recipes` package, to create the embeddings.

# Speaker bio

Alan Feder is a Principal Data Scientist at Invesco, where he uses as much R as possible to solve problems and build products throughout the company.  Previously, he worked as a data scientist at AIG and an actuary at Swiss Re.  He studied statistics and mathematics at Columbia University.  He is unreasonably excited to spread the word about categorical embeddings.

Alan lives in New York City with his wife, Ashira, and two children, Matan and Sarit.
