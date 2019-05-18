rm(list = ls())
library(invgamma)
library(data.table)
library(mnormt)
library(coda)
library(ggplot2)

gamma_m_sample=function(xm,ym,sigma2,sig_gamma)
{
  inverse=solve(sig_gamma)
  variance=solve((t(xm)%*%xm)/sigma2+inverse)
  mean=variance%*%t(xm)%*%ym/sigma2
  sample=rmnorm(1,mean,variance)
  return (sample)
}

theta_u_sample=function(xu,yu,sigma2,sig_theta)
{
  inverse=solve(sig_theta)
  variance=solve((t(xu)%*%xu)/sigma2+inverse)
  mean=variance%*%t(xu)%*%yu/sigma2
  sample=rmnorm(1,mean,variance)
  return (sample)
}

gibbs=function (mdata,L,m,gamma_var,theta_var)
{
  data=copy(mdata)
  n=length(data$rating)
  
  total_avg=mean(data$rating)
  user_avg=aggregate(rating~userId,data,mean)
  movie_avg=aggregate(rating~movieId,data,mean)
  
  theta=matrix(0,nrow=length(user_avg[,1]),ncol=L+1)
  theta[,1]<-user_avg[,2]-total_avg
  thetasamples=array(0,c(m,length(user_avg[,1]),L+1))
  
  gamma=matrix(0,nrow=length(movie_avg[,1]),ncol=L+1)
  gamma[,1]<-movie_avg[,2]-total_avg
  gammasamples=array(0,c(m,length(movie_avg[,1]),L+1))
  
  mu=total_avg
  musamples=array(0,m)
  
  sigma2=var(data$rating)
  sigma2samples=array(0,m)
  
  I=diag(L+1)
  sig_gamma=I*gamma_var
  sig_theta=I*theta_var
  
  for (i in 1:m)
  {
    print(i)
    y_mu=rowSums(theta[data$uindex,-1]*gamma[data$mindex,-1])+theta[data$uindex,1]+gamma[data$mindex,1]
    mu=rnorm(1,mean(data$rating-y_mu),sqrt(sigma2/n))
    sigma2=rinvgamma(1,n/2,sum((data$rating-y_mu-mu)^2)/2)
    for (movie in movieids)
    {
      index=match(movie,movieids)
      g_index=which(data$mindex==index)
      ym=data$rating[g_index]-mu-theta[data$uindex[g_index],1]  
      xm=cbind(1,theta[data$uindex[g_index],-1])
      gamma[index,]<-gamma_m_sample(xm,ym,sigma2,sig_gamma)
    }
    for (user in userids)
    {
      index=match(user,userids)
      g_index=which(data$uindex==index)
      ym=data$rating[g_index]-mu-gamma[data$mindex[g_index],1]
      xm=cbind(1,gamma[data$mindex[g_index],-1])
      theta[index,]<-theta_u_sample(xm,ym,sigma2,sig_theta)
    }
    musamples[i]<-mu
    sigma2samples[i]<-sigma2
    thetasamples[i,,]<-theta
    gammasamples[i,,]<-gamma
  }
  r=list("mu"=musamples,"sigma2"=sigma2samples,"theta"=thetasamples,"gamma"=gammasamples)
  return(r)
}

mcmcplots=function(gibbsresult)
{
  cumuplot(mcmc(gibbsresult$mu),main="Cumulative plot of mu",ylab="mu")
  cumuplot(mcmc(gibbsresult$sigma2),main="Cumulative plot of sigma^2",ylab="sigma^2")
  cumuplot(mcmc(gibbsresult$gamma[,1,]))
  cumuplot(mcmc(gibbsresult$theta[,1,]))
  plot(mcmc(gibbsresult$mu),trace=F)
  plot(mcmc(gibbsresult$sigma2),trace=F)
  plot(mcmc(gibbsresult$gamma[,1,]),trace=F)
  plot(mcmc(gibbsresult$theta[,1,]),trace=F)
  print(effectiveSize(gibbsresult$mu))
  print(effectiveSize(gibbsresult$sigma2))
  print(effectiveSize(gibbsresult$gamma[,1,]))
  print(effectiveSize(gibbsresult$theta[,1,]))
}

plot_results=function(data,gibbsresult,burnin)
{
  m=length(gibbsresult$mu)
  mu_final=mean(gibbsresult$mu[c(burnin:m)])
  sigma2final=mean(gibbsresult$sigma2[c(burnin:m)])
  gamma_final=colMeans(gibbsresult$gamma[c(burnin:m),,], dim=1)
  theta_final=colMeans(gibbsresult$theta[c(burnin:m),,], dim=1)
  
  predicted=mu_final+gamma_final[data$mindex,1]+theta_final[data$uindex,1] + rowSums(theta_final[data$uindex,-1]*gamma_final[data$mindex,-1])
  
  compare=as.data.frame(predicted)
  compare$actual=data$rating
  
  hist(compare$actual-compare$predicted, main="Distribution of errors in training data",xlab="Error",ylab="Frequency")
  print(sd(compare$actual-compare$predicted))
  
  meantable=aggregate(predicted~actual,compare,mean)
  sdtable=aggregate(predicted~actual,compare,sd)
  
  plot(compare$actual,compare$predicted,main="Comparison on training data",xlab="Actual rating",ylab="Predicted rating")
  lines(meantable$actual,meantable$predicted,lwd=2)
  lines(sdtable$actual,meantable$predicted+sdtable$predicted,lty=2)
  lines(sdtable$actual,meantable$predicted-sdtable$predicted,lty=2)
}

validation_results=function(gibbsresult,testdata,burnin)
{
  m=length(gibbsresult$mu)
  mu_final=mean(gibbsresult$mu[c(burnin:m)])
  sigma2final=mean(gibbsresult$sigma2[c(burnin:m)])
  gamma_final=colMeans(gibbsresult$gamma[c(burnin:m),,], dim=1)
  theta_final=colMeans(gibbsresult$theta[c(burnin:m),,], dim=1)
  
  predicted=mu_final+gamma_final[testdata$mindex,1]+theta_final[testdata$uindex,1] + rowSums(theta_final[testdata$uindex,-1]*gamma_final[testdata$mindex,-1])
  
  compare=as.data.frame(predicted)
  compare$actual=testdata$rating
  
  hist(compare$actual-compare$predicted, main="Distribution of errors in test data",xlab="Error",ylab="Frequency")
  print(sd(compare$actual-compare$predicted))
  
  meantable=aggregate(predicted~actual,compare,mean)
  sdtable=aggregate(predicted~actual,compare,sd)
  
  plot(compare$actual,compare$predicted,main="Comparison on test data",xlab="Actual rating",ylab="Predicted rating")
  lines(meantable$actual,meantable$predicted,lwd=2)
  lines(sdtable$actual,meantable$predicted+sdtable$predicted,lty=2)
  lines(sdtable$actual,meantable$predicted-sdtable$predicted,lty=2)
}

movie=read.csv("ratings_small.csv")
perusercount=aggregate(rating~userId,movie,length)
hist(perusercount$rating,breaks=50,main="Distribution of ratings for movie", xlab="Number of ratings",ylab="Count of movies")
permoviecount=aggregate(rating~movieId,movie,length)
hist(permoviecount$rating,breaks=50,main="Distribution of ratings by user", xlab="Number of ratings",ylab="Count of users")
hist(movie$rating,breaks=5,main="Distribution of ratings", xlab="Rating",ylab="Count of movies")

n=length(movie$rating)

total_avg=mean(movie$rating)
user_avg=aggregate(rating~userId,movie,mean)
movie_avg=aggregate(rating~movieId,movie,mean)

userids=user_avg[,1]
movieids=movie_avg[,1]

userindex=match(movie$userId,userids)
movieindex=match(movie$movieId,movieids)

movie$uindex<-userindex
movie$mindex<-movieindex

test_ind <- sample(seq_len(n), size = floor(0.32*n))

temp=as.data.frame(table(movie$movieId[-test_ind]))
allowed=as.data.frame(temp[temp$Freq>2,]$Var1)
names(allowed)<-("movie")
test_ind=test_ind[movie$movieId[test_ind]%in%allowed$movie]

temp=as.data.frame(table(movie$userId[-test_ind]))
allowed=as.data.frame(temp[temp$Freq>2,]$Var1)
names(allowed)<-("user")
test_ind=test_ind[movie$userId[test_ind]%in%allowed$user]

movie_train=movie[-test_ind,]

validation_ind=sample(test_ind, size = floor(length(test_ind)/2))
test_ind=test_ind[!test_ind%in%validation_ind]

movie_validate=movie[validation_ind,]
movie_test=movie[test_ind,]

# Case 1
test2=gibbs(movie_train,4,500,1,1)
mcmcplots(test2)
plot_results(movie_train,test2,200)
validation_results(test2,movie_test,200)

# Case 2
test3=gibbs(movie_train,10,1000,1,1)
mcmcplots(test3)
plot_results(movie_train,test3,200)
validation_results(test3,movie_validate,200)

# Case 3
test4=gibbs(movie_train,20,1500,1,1)
mcmcplots(test4)
plot_results(movie_train,test4,1000)
validation_results(test4,movie_validate,1000)

# Case 4
test5=gibbs(movie_train,2,5000,1,1)
mcmcplots(test5)
plot_results(movie_train,test5,4000)
validation_results(test5,movie_validate,4000)


# Evaluate on test set
validation_results(test5,movie_test,4000)
print(mean(test5$mu[c(4000:5000)]))
print(mean(test5$sigma2[c(4000:5000)]))