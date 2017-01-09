getwd()
install.packages("gplots")
install.packages("RColorBrewer")
library(gplots)
library(RColorBrewer)
library(randomForest)
library(caret)
setwd("D://Sunstone//kaggle//Otto")
#Reading the training and test data sets
train <- read.csv("train.csv", header = T)
test <- read.csv("test.csv", header = T)
head(train)
str(train)
summary(train)
# We see that there are 93 features dimensions and 1 dimension for the class of the 
# Otto Product. We also have one id coloumn as a row identifier.
# All the variables are numeric except the class.
sum(is.na(train))
#Shows that there are no missing values and data is properly read and formatted


# Since there are so many features to play with my mission would be to reduce the 
# dimensions to a smaller sets of variables to consider. 

#-----Using Principal Component Analysis (PCA) to find uncorrelated linear-----# 
#dimensions which capture maxium variance in the data.

#----Rescaling the data to make them comparable across products class----#
train.sc <-train #Making a copy of the train data as we dont want to mess up the actual data
train.sc[, 2:94] <- scale(train[, 2:94], center = TRUE)
summary(train.sc) # Now mean value for every feature is 0.

#--------Average mean feature values for each class--------#
Class_mean <- aggregate(. ~ target, data = train.sc, mean)
Class_mean <- Class_mean[,-2]#Removing the id coloumn as this makes no sense
rownames(Class_mean) <- Class_mean[,1]#Changing the rownames to the class names
Class_mean <- Class_mean[,-1]
#Now we have the mean feaure rating for all the classes.
#To access such type of data, we can use heat maps.
#Lets analyze only first 10 features.
heatmap.2(as.matrix(Class_mean[,-1]), 
          col = brewer.pal(9, "RdBu"), trace = "none", key = F,dendrogram = "none", 
          main = "\n\n\n\nHeatmap - Class Features", xlab = "Features")
#We can see that there is quite a color pattern which emerges from this heatmap.
# feat_27,61,46,4,63,60,54,80,28,4,82,26,42 have similar color pattern. A class that 
# has high value on one also has higher values on the others

#now lets formalize our insights drawn from the heat map.
#---------------------------------PCA--------------------------------#

#1. PCA process helps reduce the complexity by forming linear combination of variables 
#   called components, such that the component captures maxium variance from all 
#   variables as a single linear function. This continues till there are as many components
#   as their are variables. WE can reduce the complexity by only treating few components
#   which explains the maximum variance in the data.

train.pc <- prcomp(train.sc[,-c(1,95)], scale = T)

summary(train.pc)
plot(train.pc, type = "l")
biplot(train.pc,cex =c(3,1))
#This plot is too dense to make much sense out of it

Class_mean.pr <- prcomp(Class_mean, scale = T)
summary(Class_mean.pr)
screeplot(Class_mean.pr, type = "l")
biplot(Class_mean.pr, main = "Class_Identification", cex =c(1.5,1))
#-------@@@@@@@@@@@@ ADD the CHART Here--@@@@@@@@@@@@@---------#

#Class_2,3,4,5 are are located in close proximity and are defined by similar group of features
#Class_6 is very unique and is located away from all others
#Class_1,7,9 are also appearing in close proximity
#Class 8 is somewhat uniquely placed as well.

fit <- randomForest(target ~., data = train[,-1], ntree = 400, importance = TRUE)
varImpPlot(fit, sort = T)
plot(fit)

var.imp <- data.frame(importance(fit, type=2))
var.imp$Variables <- row.names(var.imp)
var.imp[order(var.imp$MeanDecreaseGini,decreasing = T),]

#Add the importance table. We see that after 100 trees, the error decrease is almost
#negligible

#Now lets predict the target variable based on on our model
train$target.pred <- predict(fit, train[,-1])
confusionMatrix(data = train$target.pred, reference = train$target)

#          Reference
#Prediction Class_1 Class_2 Class_3 Class_4 Class_5 Class_6 Class_7 Class_8 Class_9
#Class_1    1913       0       0       0       0       0       0       0       0
#Class_2       1   16086     145      41       0       0      12       5       7
#Class_3       0      34    7853      18       0       0       2       1       0
#Class_4       0       0       3    2628       0       0       3       0       0
#Class_5       0       0       0       3    2738       0       0       0       0
#Class_6       1       0       1       0       0   14131       0       2       0
#Class_7       1       1       1       1       1       2    2822       1       1
#Class_8       7       1       1       0       0       2       0    8451       8
#Class_9       6       0       0       0       0       0       0       4    4939

#Overall Statistics

#Accuracy : 0.9949          
#95% CI : (0.9943, 0.9954)

#######-----Predicting for the test data-------########

test$target <- predict(fit, test[,-1])
submission <- data.frame(id=test$id, Class_1=NA, Class_2=NA, Class_3=NA, Class_4=NA, Class_5=NA, Class_6=NA, Class_7=NA, Class_8=NA, Class_9=NA)
rf <- randomForest(train[,-c(1,95,96)], as.factor(train$target), ntree=100, importance=TRUE)
plot(rf)
rf
submission[,2:10] <- (predict(rf, test[,-c(1,95)], type="prob") + 0.01)/1.09
confusionMatrix(data = train$target.pred, reference = train$target)
write.csv(submission, file="3rdRandomForest.csv", row.names = F)
#0.59620 - Logloss
