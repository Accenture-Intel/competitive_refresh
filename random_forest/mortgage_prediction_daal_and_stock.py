#!/usr/bin/env python
# coding: utf-8

# In[ ]:


get_ipython().system('pip install scikit-learn-intelex')


# In[ ]:


get_ipython().system('unzip ML_2020Q3Mortage.zip')


# In[ ]:


# organize notebook format
# To expand output so that it shows all data columns 
import pandas as pd
import daal4py as d4p
import numpy as np
import time
pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 500)
pd.set_option('display.width', 1000)

# to hide warnings
import warnings
warnings.filterwarnings('ignore')


# In[ ]:


df_ml = pd.read_csv('ML_2020Q3Mortage.csv')


# In[ ]:


df_ml


# In[ ]:


#10% of full dataset to test daal model 
# train_dataset = df_ml.iloc[:277199,:]


# In[ ]:


from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error


# In[ ]:


# split data to train/test
X = df_ml.drop(['LOAN_ID','ORIG_UPB'], axis=1)
y = df_ml.ORIG_UPB

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=2)


# In[ ]:


# delete unused further data to free up GPU memory
del df_ml , X ,y


# In[ ]:


d4p.daalinit()


# In[ ]:


model = d4p.decision_forest_regression_training(nTrees=100)


# In[ ]:


# model 
start_stock = time.time()
reg = RandomForestRegressor().fit(X_train, y_train)
end_stock = time.time() - start_stock
print("Stock training time: ", end_stock)


# In[ ]:


start_pred = time.time()
reg.predict(X_test)
end_pred = time.time() - start_pred
print('Stock pred time: ', end_pred)


# In[ ]:


# optimized model 
start = time.time()
train_result = model.compute(X_train, y_train)
end = time.time() - start
print("Intel optimized training time: ", end)


# In[ ]:


start_pred = time.time()
pred_algo = d4p.decision_forest_regression_prediction(fptype='float')
predict_res = pred_algo.compute(X_test, train_result.model)
end_pred = time.time() - start_pred
print('Intel pred time: ', end_pred)

