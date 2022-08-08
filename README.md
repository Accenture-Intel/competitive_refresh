# Competitive Refresh

<h4 align="center">Be sure to :star: this repository so you can keep up to date on any updates!</h4>
<p align="center">
 <img src ='https://forthebadge.com/images/badges/made-with-python.svg'>
 <img src ='https://forthebadge.com/images/badges/open-source.svg'>
</p>

# UPDATE TOC SECTION BY SECTION

## 📑 Table of Contents 📑
 - [Description](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#description)
 - [Accenture - Intel Partnership](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#accenture---intel-partnership)
 - [Benchmark Details](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#benchmark-details)
 - [Environment Setup & Code Deployment](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#environment-setup--code-deployment)
 - [Results](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#results)
 - [Appendix](https://github.com/Accenture-Intel/competitive_refresh/edit/main/README.md#appendix)

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

<img width="855" alt="Screenshot 2022-08-08 134510" src="https://user-images.githubusercontent.com/107268111/183511220-e6fd1268-c08f-407d-8358-3fd8813656de.png">

## Environment Setup & Code Deployment

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
 
**SHOW LINK OF HOW TO GET DATASET!**

### Food Demand Forecasting - XGBoost Machine Learning

#### Description and Dataset

#### Running the Benchmark
Once inside the xgboost folder, open a Jupyter Notebook and run the **food_demand_forecasting.ipynb** notebook file.

#### Results


### Chest X-Ray Pneumonia Detection - CNN Deep Learning
- use the jupyter specific env with tensorflow!

#### Description and Dataset

#### Running the Benchmark
If on an m6i or m6a instance, open Jupyter Notebook and run the **cnn_pneumonia.ipynb** inside the **conda_tensorflow2_p39** environment, which can be accessed through the *New* dropdown on the top right of the screen.

<img width="280" alt="Screenshot 2022-08-08 155854" src="https://user-images.githubusercontent.com/107268111/183530071-6ae71cf9-d961-478d-bf9f-fd01144b57b5.png">

If on a t4g or m6g instance, simply run the **cnn_pneumonia.py** script from the **tf_bench** conda environment in your terminal.

#### Results


### Mortgage Loan Prediction - Random Forest Regression

#### Description and Dataset

#### Running the Benchmark
If on an m6i or m6a instance, run the **mortgage_prediction_daal_and_stock.py** script in your terminal (alternatively you can also run the .ipynb). If on a t4g or m6g, run the **mortgage_prediction_stock_only.py** script, because the Intel OneAPI daal4py software optimizer isn't compatible with ARM-based instances.

#### Results


### CoLA Grammatical Acceptability - BERT NLP Deep Learning

#### Description and Dataset

#### Running the Benchmark

#### Results

## Appendix

### Sources
- oneapi
- all the diff datasets

## Used By

This project is used by the following companies:
![ACN-Intel_logo](https://user-images.githubusercontent.com/91902558/157770015-ea092843-c4ee-4fb4-8207-31c0368d718b.png)
