## Predicting Patient Satisfaction from Textual Pharmaceutical Reviews

This repository contains limited materials developed for a PSYC 5710 project in which I constructed a model to predict patient satisfaction from drug reviews using a variety of NLP techniques. 


### Pre-processing

Raw, unedited text can only be submitted to certain analyses without pre-processing. Therefore, I applied a series of manipulations to these bodies of text to produce data structures better suited for feature engineering. These manipulations included the conversion from a raw string format to a corpus format, the removal of numerical characters, punctuation, and stop words, stemming, and finally the formation of a document term matrix from the processed corpus. I utilized the 'tm' and 'SnowballC' packages for all pre-processing. 


### Results

After constructing and comparing several models, I fit my final model, which was a bagged random forest predicting on basic patient information as well as the following engineered features:

1. #### Sentiment Scores
Sentiment scores were derived from patients' raw textual reviews using the 'SentimentAnalysis' package. 

2. #### EGA Network Scores
Exploratory graph analysis (EGA) network scores were derived from pre-processed 

3. #### Zero-shot Classification Scores


### Performance

My final model yielded an RMSE of approximately 0.82 on unseen test data. 
