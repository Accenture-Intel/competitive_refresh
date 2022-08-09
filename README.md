# Competitive Refresh

<h4 align="center">Be sure to :star: this repository so you can keep up to date on any updates!</h4>
<p align="center">
 <img src ='https://forthebadge.com/images/badges/made-with-python.svg'>
 <img src ='https://forthebadge.com/images/badges/open-source.svg'>
</p>

## 📑 Table of Contents 📑
 - [Description](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#description)
 - [Accenture - Intel Partnership](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#accenture---intel-partnership)
 - [Benchmark Details](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#benchmark-details)
 - [Environment Setup](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#environment-setup)
 - [Benchmark-Specific Code Deployment and Results](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#benchmark-specific-code-deployment-and-results)

## Description

As part of an Accenture-Intel partnership aimed at accelerating client transformation and driving co-innovation through cutting-edge technology and industry experience, we are showcasing performance and price-performance metrics across AWS instances on a variety of AI/ML use-cases. We invite you to explore our workloads and build upon them using Intel's platform.

## Accenture - Intel Partnership
What do you get when you combine a company that “delivers on the promise of technology and human ingenuity” and another that “shapes the future of technology”?
Accelerated co-innovation; capabilities alignment: the right experts at the right time; and consistent client outcomes thanks to trained Intel solution architects at Accenture. 

Renowned as titans in the high-tech space, Accenture and Intel share a single-minded focus to accelerate client transformation and drive co-innovation. The Accenture and Intel joint partnership bring together cutting-edge technology and unrivaled market & industry expertise allowing for significant expansion into the following portfolio offerings (towers): Multicloud, Network, Analytics and AI, and Digital Workspace. Each tower provides generates significant value not only to both Accenture and Intel, but also to their clients. These towers show the co-dependency Accenture and Intel have, with Intel bringing optimized AI offerings using its Xeon and adjacent technologies and Accenture bringing its Applied Intelligence Platform (AIP) & Solutions.AI offerings for intelligent revenue growth and advanced consumer engagement, for example. Together, Accenture and Intel push industries beyond their limits, providing consistent outcomes and evangelizing success for the benefit of their clients.

To learn more about this partnership, follow this <a href="https://www.accenture.com/us-en/services/high-tech/alliance-intel/" target="_blank">link</a>.

## Benchmark Details  
### Purpose
In order to update Intel processor positioning relative to competitors' most recent AWS instance offerings, we compared the performance of the Intel Ice Lake m6i against the AMD EPYC m6a and the AWS Graviton2 t4g & m6g. Using four use-cases meant to test commonly-used models and algorithms, we analyzed each instance's prediction time to determine a performance and price-to-performance metric relative to eachother, comparing both the stock model and the Intel oneAPI speedup accessible on the Intel and AMD instances.

<img width="857" alt="Screenshot 2022-08-09 111626" src="https://user-images.githubusercontent.com/107268111/183730984-5bbc3167-e237-43de-acbc-a5c9fb33226e.png">

## Environment Setup

### AWS Instance Launch

#### m6i and m6a EC2 Instances

Please follow the the instructions given below for setting up the environment. The guide will walk you through the process of setting up your system to run the model on the m6i EC2 instance. The procedure is the same for the m6a instance, just select the **m6a instance** from the _All instance families_ drop-down at the end of the setup.

##### Launching the Deep Learning AMI (DLAMI)
To launch the DLAMI, go to your AWS EC2 page and click 'Launch instances'.
![image](https://user-images.githubusercontent.com/91902558/157768843-a3a73db5-9e01-45c2-ac0b-285fa11d6c46.png)

In the searchbar, search 'Deep Learning AMI' and select AWS Marketplace. From the options, select the **Deep Learning AMI (Ubuntu 18.04) Version 57.0** option and press continue on the prompt.
![image](https://user-images.githubusercontent.com/91902558/157768743-dc568c48-5cc6-4951-b81d-ba24d6f6db55.png)

After pressing continue on the prompt, select the **m6i** instance from the _All instance families_ drop-down as recommended for this AMI and configure the instance details as needed. Click on the **Review and Launch** and **Launch** buttons at the bottom right corner of your screen, and follow the steps for key pairs.
![image](https://user-images.githubusercontent.com/91902558/157769116-01fc2a0a-4846-479f-b65f-2fe75df3468e.png)

Once all of that is complete, you can launch & connect to the Deep Learning AMI (Ubuntu 18.04) Version 57.0.

#### t4g and m6g EC2 Instances

The Graviton2 instances run on an ARM-based processor rather than x86 like Intel and AMD processors; as a result, the setup for these instances is slightly different from above. When searching for the AMI, instead of searching for the 'Deep Learning AMI', search for **Deep Learning AMI Graviton** and, from the *Community AMIs* section, select **Deep Learning AMI Graviton TensorFlow 2.7.0 (Ubuntu 20.04) 20220107**.

<img width="970" alt="Screenshot 2022-08-08 145200" src="https://user-images.githubusercontent.com/107268111/183521349-f17bae9f-ba79-426d-8b2c-1da7c50e7ab3.png">

### Instance Setup
Different instances require different instances and setup before running the benchmarks. Please run the below commands in your terminal after ssh-ing into the appropriate EC2 instance to setup packages and clone into the repo.

#### Intel Ice Lake m6i and AMD EPYC m6a
```
- git clone https://github.com/Accenture-Intel/competitive_refresh
```

#### AWS Graviton2 t4g & m6g
```
- curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -o Miniconda3-latest-Linux-aarch64.sh
- bash Miniconda3-latest-Linux-aarch64.sh
*restart your EC2 instance*
- conda create -n tf_bench python=3.8
- conda activate tf_bench
- conda install -c conda-forge tensorflow jupyter pandas
- pip install sklearn
- git clone https://github.com/Accenture-Intel/competitive_refresh
```

## Benchmark-Specific Code Deployment and Results

### Food Demand Forecasting - XGBoost Machine Learning

#### Description and Dataset
This benchmark uses an XGBoost regression model to predict demand for a meal delivery company. Given a dataset with 15 features and over 500,000 meal deliveries over 145 weeks, the goal is to predict the demand for various raw materials for the following 10 weeks. [Here](https://www.kaggle.com/datasets/kannanaikkal/food-demand-forecasting) is a link to the dataset for more information, but the CSVs are already in the repository and don't need to be downloaded. To learn more about the XGBoost algorithm, please check out our [XGBoost repo](https://github.com/Accenture-Intel/XGBoost#description-1).

#### Running the Benchmark
Once inside the xgboost folder, open a Jupyter Notebook and run the **food_demand_forecasting.ipynb** notebook file.

#### Results
Below are two graphs of the results of our tests. Both compare the relative prediction time improvements of each instance and software compared to the Intel Ice Lake m6i instance running stock XGBoost. The left graph compares pure prediction performance gain, and the right one compares the same performance gain but relative to the per-unit cost of each of the instances. In both cases, **Ice Lake with Intel daal4py optimizations have the highest metrics** across the tests. 

<img width="875" alt="Screenshot 2022-08-09 103302" src="https://user-images.githubusercontent.com/107268111/183721289-384b4185-5a26-48d1-aa92-c5528235635d.png">

### Chest X-Ray Pneumonia Detection - CNN Deep Learning

#### Description and Dataset
This benchmark uses an Convolutional Neural Network to predict whether a given chest X-ray shows that the patient has pneumonia. The dataset of 5,863 images of normal and pneumonic patients has already been downloaded in the repository, but can be found [here](https://www.kaggle.com/datasets/paultimothymooney/chest-xray-pneumonia) for more information. For more information about CNN, please check out our [CNN Hyperparameter Tuning repo](https://github.com/Accenture-Intel/Hyperparameter_Tuning/tree/main/cnn#description-1).

#### Running the Benchmark
If on an m6i or m6a instance, open Jupyter Notebook and run the **cnn_pneumonia.ipynb** inside the **conda_tensorflow2_p39** environment, which can be accessed through the *New* dropdown on the top right of the screen.

<img width="280" alt="Screenshot 2022-08-08 155854" src="https://user-images.githubusercontent.com/107268111/183530071-6ae71cf9-d961-478d-bf9f-fd01144b57b5.png">

If on a t4g or m6g instance, simply run the **cnn_pneumonia.py** script from the **tf_bench** conda environment in your terminal.

#### Results
Below are two graphs of the results of our tests. Both compare the relative prediction time improvements of each instance and software compared to the Intel Ice Lake m6i instance. The Ice Lake and EPYC instances are running built-in Intel oneDNN software optimizations on top of the Tensorflow neural network package, and the Graviton2 instances are running stock Tensorflow. The left graph compares pure prediction performance gain, and the right one compares the same performance gain but relative to the per-unit cost of each of the instances. In both cases, **Ice Lake with Intel oneDNN optimizations has the highest metrics** across the tests. 

<img width="875" alt="Screenshot 2022-08-09 104925" src="https://user-images.githubusercontent.com/107268111/183724320-a0026312-16cc-4a56-8152-caade48d7661.png">

### Mortgage Loan Prediction - Random Forest Regression

#### Description and Dataset
This benchmark uses a Random Forest regression model to predict the optimal mortgage loan amount to lend to a customer to minimize default risk. The dataset of over 2 billion rows and 108 columns should be downloaded from [this](https://capitalmarkets.fanniemae.com/credit-risk-transfer/single-family-credit-risk-transfer/fannie-mae-single-family-loan-performance-data) link. Doublecheck that the downloaded ZIP file's filename is exactly **ML_2020Q3Mortgage.zip**, and that the **ML_2020Q3Mortgage.csv** file that is extracted from that is in the same random_forest folder as the .py and .ipynb scripts. Alternatively, if you don't want to download the dataset you can use the ZIP file in the repo that contains a truncated version of the CSV with only 80% of the rows; if you use this, make sure that the filepath and name of the extracted CSV is the same as above.

#### Running the Benchmark
If on an m6i or m6a instance, run the **mortgage_prediction_daal_and_stock.py** script in your terminal (alternatively you can also run the .ipynb). If on a t4g or m6g, run the **mortgage_prediction_stock_only.py** script, because the Intel OneAPI daal4py software optimizer isn't compatible with ARM-based instances.

#### Results
Below are two graphs of the results of our tests. Both compare the relative prediction time improvements of each instance and software compared to the Intel Ice Lake m6i instance running stock scikit-learn Random Forests. The left graph compares pure prediction performance gain, and the right one compares the same performance gain but relative to the per-unit cost of each of the instances. In both cases, **Ice Lake with Intel daal4py optimizations have the highest metrics** across the tests. 

<img width="887" alt="Screenshot 2022-08-09 111305" src="https://user-images.githubusercontent.com/107268111/183729388-428ccdff-a339-47ce-b9eb-66e3fa040a0d.png">

### CoLA Grammatical Acceptability - BERT NLP Deep Learning

#### Description and Dataset

#### Running the Benchmark

#### Results

## Used By

This project is used by the following companies:
![ACN-Intel_logo](https://user-images.githubusercontent.com/91902558/157770015-ea092843-c4ee-4fb4-8207-31c0368d718b.png)
