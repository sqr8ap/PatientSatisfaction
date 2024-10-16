library(dplyr)

## PRE PROCESSING
library(tm)
library(SnowballC)

removeNumPunct <- function(x) gsub("[^[:alpha:][:space:]]*", "", x)

# Transform text data (train and test) into corpus for preprocessing
corpus0 <- Corpus(VectorSource(full.data$text))
corpus1 <- tm_map(corpus0, removeNumPunct)
corpus2 <- tm_map(corpus1, tolower)
corpus3 <- tm_map(corpus2, removePunctuation)
corpus4 <- tm_map(corpus3, removeNumbers)
corpus5 <- tm_map(corpus4, removeWords, stopwords("en"))
corpus6 <- tm_map(corpus5, stemDocument)

dtm1 <- DocumentTermMatrix(corpus6)
dtm2 <- removeSparseTerms(dtm1, sparse = 0.96)
dtm2.df <- as.data.frame(as.matrix(dtm2))


## EGA NETWORK SCORES
library(EGAnet)

topics.optimal <- EGA.fit(dtm2.df, model = "tmfg", plot.EGA = FALSE)

topics.optimal$EntropyFit
topics <- EGA(dtm2.df, model = "tmfg", steps = 4)

topics$dim.variables

netplot.topics <- plot(topics, label.size = 4, edge.size = 0.9,
                       node.size = colSums(topics$network)*4)

# Compute network scores for each topic
scores.drugs <- net.scores(dtm2.df,
                           A = topics$network, wc = topics$wc,
                           impute = "mean")
scores.drugs.df <- as.data.frame(scores.drugs$scores$std.scores)
colnames(scores.drugs.df) <- paste0('Rating',colnames(scores.drugs.df))
scores.drugs.df$rating <- factor(full.data$rating)

scores.drugs.df <- scores.drugs$scores$std.scores
colnames(scores.drugs.df) <- paste0("Rating", 1:ncol(scores.drugs.df))


full.data2 <- data.frame(full.data, scores.drugs.df)


## SENTIMENT ANALYSIS
library(SentimentAnalysis)

sentiment <- SentimentAnalysis::analyzeSentiment(full.data2$text)

# Merge the sentiment scores and number of words with full.data2:
full.data3 <- cbind(full.data2, sentiment)


## ZERO-SHOT CLASSIFICATION
library(devtools)
devtools::install_github("atomashevic/transforEmotion")
transforEmotion::setup_miniconda()
library(transforEmotion)

scores_drugs <- transformer_scores(
  text = df$text,
  classes = c("Positive", "Negative", "Neutral"),
  device = "auto") # will use CUDA-capable GPU (if able)

df <- do.call(rbind.data.frame, scores_drugs)
full.data4 <- data.frame(full.data3, df)


## MODEL CONSTRUCTION

# Train/test split
train <- df.sent.ega.zeroshot%>%
  dplyr::filter(DataGroup == 'Training')
test <- df.sent.ega.zeroshot%>%
  dplyr::filter(DataGroup == 'Testing')

# Construct model
library(caret)
set.seed(12345)
trainIndex <- createDataPartition(train$rating, p = .6, list = FALSE)
train.ml <- train[trainIndex, ]
test.ml <- train[-trainIndex, ]

fitControl <- trainControl(## 5-fold CV
  method = "repeatedcv",
  number = 5,
  ## repeated 5 times
  repeats = 5)

bagGrid <-  expand.grid(mtry = ncol(train[,c(3,4,5,7,9:42)]))

fit.bagging <- train(rating ~ ., 
                     data = train[,c(3,4,5,7,9:42)], 
                     method = "rf",
                     tuneGrid = bagGrid,
                     trControl = fitControl)

preds <- predict(fit.bagging, newdata = test[,c(3,4,5,7,9:42)])

