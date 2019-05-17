# Movie Recommendation System using Gibbs Sampling

## Introduction
The aim of the project is to build a movie recommendation system. Based on a given set of ratings for movies by users, we want to predict a user's rating for a movie and provide recommendations based on that. To do so, we will use Bayesian techniques and Gibbs sampling.

## Data
To build this model, we used a subset of the movie ratings data provided by GroupLens. The data was obtained from [Kaggle](https://www.kaggle.com/rounakbanik/the-movies-dataset#ratings_small.csv). It contains close to 97000 ratings for over 6000 movies by more than 600 users. The data was cleaned to include movies which had at least 2 ratings and users who had rated at least 2 movies.

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
The derivation of the conditionals can be found in the [report](/Report.pdf). The final conditionals are

![mu](/images/mu_conditional.png)
![sigma](/images/sigma_conditional.png)
![gamma](/images/gamma_conditional.png)
![theta](/images/theta_conditional.png)

We have (U+M)x(L+1)+2 parameters to estimate. We build a Gibbs sampler to estimate these parameters.

## Data Exploration
We do a basic data exploration and see the distribution of number of ratings by a user, number of ratings for a movie and the rating distribution itself.

![movierating](/images/movie_rating.png)
![userrating](/images/user_rating.png)
![ratings](/images/ratings.png)

To evaluate the results of our model, we divide our data into training, validation and testing data. About 70\% is kept as training while the rest is equally divided in validation and testing. While sampling data for training, we made sure that all movies and users that appear in test or validation set have at least two entries in the training data.

## Gibbs Sampling
We now set up Gibbs sampling to evaluate parameters based on our training data. The following values were chosen as the initial values

![init](/images/init.png)

After removing the burn in samples, the average across all remaining samples was taken to get an estimate of the parameters. These parameters were then used to predict the ratings in validation set.
The graphs and details of different trials and their results are shown

### Case 1
L = 4, number of samples = 500, burn in = 200
![mu1](/images/mu_case1.png)
![sigma1](/images/Sigma_1.png)
![train1](/images/train_1.png)
![test1](/images/test_1.png)

The solid line is the man of predicted ratings and the dotted lines show the range between one standard deviation from the mean

### Case 2
L = 10, number of samples = 1000, burn in = 200
![mu2](/images/mu_case2.png)
![sigma2](/images/Sigma_2.png)
![train2](/images/train_2.png)
![test2](/images/test_2.png)


### Case 3
L = 20, number of samples = 1500, burn in = 1000
![mu3](/images/mu_case3.png)
![sigma3](/images/Sigma_3.png)
![train3](/images/train_3.png)
![test3](/images/test_3.png)


### Case 2
L = 2, number of samples = 5000, burn in = 4000
![mu4](/images/mu_case4.png)
![sigma4](/images/Sigma_4.png)
![train4](/images/train_4.png)
![test4](/images/test_4.png)

## Results
| Case | L | Samples | Burn in | Training error (RMSE) | Validation error (RMSE) |
| --- | --- | --- | --- | --- | --- |
1 | 4 | 500 | 200 | 0.66 | 0.87 |
2 | 10 | 1000 | 200 | 0.58 | 0.88 |
3 | 20 | 1500 | 1000 | 0.49 | 0.89 |
4 | 2 | 5000 | 4000 | 0.71 | 0.88 |

Based on the results we go with model 4. While the error on validation set is not the least, the value of mean had converged for model 4. Running it on the test set we get the following results

![test](/images/test.png)

The RMSE on test data was 0.86. The values of mean and variance were 3.46 and 0.6 respectively.

We see that the mean does not converge for lower sample sizes. Plotting the predicted data of validation and test set suggests presence of a bias. Running the model for more samples with a higher value of L could result in better accuracy.
