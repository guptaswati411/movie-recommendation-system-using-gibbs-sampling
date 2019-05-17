# Movie Recommendation System using Gibbs Sampling

## Introduction
The aim of the project is to build a movie recommendation system. Based on a given set of ratings for movies by users, we want to predict a user's rating for a movie and provide recommendations based on that. To do so, we will use Bayesian techniques and Gibbs sampling.

## Data
To build this model, we used a subset of the movie ratings data provided by GroupLens. The data was obtained from [Kaggle](http://https://www.kaggle.com/rounakbanik/the-movies-dataset#ratings_small.csv). It contains close to 97000 ratings for over 6000 movies by more than 600 users. The data was cleaned to include movies which had at least 2 ratings and users who had rated at least 2 movies.

## Approach
The model we build will use collaborative filtering to predict the rating by a user for a movie. The principle behind collaborative filtering is that similar people will rate similar movies in a similar way. If A and B both like a movie X, and A also likes movie Y, B's likeliness towards Y would be closer to A's than any random user.

To evaluate similarity between users or movies, we introduce latent variables in our model. The latent variables will capture properties of a movie that makes a user like or dislike it. Some examples of such properties could be popularity of the cast, duration of the movie, amount of humor in the movie, etc.

## Defining the model
The following variables are used in the model

![params](/images/parameters.png)

We define the following model to predict the ratings

![model](/images/model.png)

### Priors
The following priors are assumed for the parameters

![priors](/images/priors.png)

### Conditionals
The derivation of the conditionals can be found in the [report](report.pdf)
