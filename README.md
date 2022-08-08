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
'''
- git clone https://github.com/Accenture-Intel/competitive_refresh
'''

#### AWS Graviton2 t4g & m6g
'''
- curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -o Miniconda3-latest-Linux-aarch64.sh
- bash Miniconda3-latest-Linux-aarch64.sh
*restart your EC2 instance*
- conda create -n tf_bench python=3.8
- conda activate tf_bench
- conda install -c conda-forge tensorflow jupyter pandas
- pip install sklearn
- git clone https://github.com/Accenture-Intel/competitive_refresh
'''

## Benchmark-Specific Code Deployment and Results
- parameters, installs and code deployments, results

### Food Demand Forecasting - XGBoost Machine Learning

### Chest X-Ray Pneumonia Detection - CNN Deep Learning
- use the jupyter specific env with tensorflow!

### Mortgage Loan Prediction - Random Forest Regression

### CoLA Grammatical Acceptability - BERT NLP Deep Learning

## Appendix

### Sources

## Used By

This project is used by the following companies:
![ACN-Intel_logo](https://user-images.githubusercontent.com/91902558/157770015-ea092843-c4ee-4fb4-8207-31c0368d718b.png)





### Purpose 
The purpose behind tuning and testing our hyperparameters on each of the three platforms is to assess the respective platforms’ capabilities and see how efficiently and accurately each one is under the same circumstances.

A hyperparameter framework is an automated framework that choses randomized hyperparameters for a machine learning model. The model uses grid and random search to test all assumptions and hyperparameters to automatically discover optimal results. This hyperparameter framework eliminates the need for manual search by using the time efficient production of realistic results. If we were to do this manually it would be extremely time-consuming and inefficient as there’s millions of possible hyperparameters but only a few that you would want to use.
The frameworks are as follows:
·       OPTUNA
·       HyperOpt
·       SigOpt
 
### F1 score
 
We tested each of the framework’s performance based on training time and accuracy. We are defining training time as the amount of time in minutes that it took for each framework to complete 100 trials of hyperparameter optimization. Accuracy in this study by the respective F1 scores.
 
F1 is: $$ (Precision * recall)/(precion + recall) = TP/(TP + ½(FP + FN) $$
The scale is 0 to 1; 1 indicating perfect precision and recall, 0 indicating the worst of both. 
We use a F1 score instead of a accuracy score because an accuracy score would lead to incorrect and skewed results. An accuracy score looks at what has been correctly guessed whether they are positive or negative. That’s where F1 score comes in. Since we’re working with randomized parameters, we need to also know how many were wrong in order to better fine tune our parameters to meet our needs.

### Parameters  
Below is an visualization detailing the parameters and environment. This experiment utilizes the following software environment setup:
<div align="center">
 
| Machine Learning Solution | Software Specifications                                   |
| ------------------------- | ----------------------------------------------------------|
| ML Application            | Classification                                            |
| ML Model                  | XGBoost                                                   |
| ML Dataset                | Higgs Dataset                                             |
| Hardware Targets          | CPUs                                                      |
| AWS EC2 Instance(s)       | Intel Ice Lake m6i.4xlarge                                |

</div>
 
## Environment Setup & Code Deployment
Below are sets of instructions to follow to run the XGBoost scripts. The instructions will take you from start to finish, showing you how to setup the DLAMI, environment, library installs, and code deployment.

### Intel Ice Lake m6i.4xlarge ![image](http://badges.github.io/stability-badges/dist/stable.svg)
Please follow the instructions given below for setting up the environment. The guide will walk you through the process of setting up your system to run the model on the m6i EC2 instance.
#### Launching the Deep Learning AMI (DLAMI)
To launch the DLAMI, go to your AWS EC2 page and click 'Launch instances'.
![image](https://user-images.githubusercontent.com/91902558/157768843-a3a73db5-9e01-45c2-ac0b-285fa11d6c46.png)

In the searchbar, search 'Deep Learning AMI' and select AWS Marketplace. From the options, select the **Deep Learning AMI (Ubuntu 18.04) Version 57.0** option and press continue on the prompt.
![image](https://user-images.githubusercontent.com/91902558/157768743-dc568c48-5cc6-4951-b81d-ba24d6f6db55.png)

After pressing continue on the prompt, select the **m6i** instance from the _All inistance families_ drop-down as recommended for this AMI and configure the instance details as needed. Click on the **Review and Launch** and **Launch** buttons at the bottom right corner of your screen, and follow the steps for key pairs.
![image](https://user-images.githubusercontent.com/91902558/157769116-01fc2a0a-4846-479f-b65f-2fe75df3468e.png)

Once all of that is complete, you can launch & connect to the Deep Learning AMI (Ubuntu 18.04) Version 57.0

#### Cloning into Repo for Install and Code Deployment 
- clone into repo
To access the scripts and install requirements from one place, clone into the Hypothesis_Testing repository. In the repository you will find several scripts and documents necessary for running the workloads, including required library installs.
```
pip install xgboost
pip install scikit-learn
pip install numpy
pip install optuna
pip install pandas
pip install hyperopt
git clone https://github.com/Accenture-Intel/Hyperparameter_Tuning
cd Hyperparameter_Tuning
python3 xgb_stock.py
```

_Note: Additionally, you can use the following alternative files to run the workloads as part of the benchmark: `xgb_hyperopt.py` ; `xgb_optuna.py` ; `xgb_sigopt.py`

## Results 
Below is a chart of our results from the tests we conducted. In the end, the total tuning time for SigOpt is 1.93x faster than Optuna and 1.5x faster than Hyperopt. F1 score for each was SigOpt with 0.7596, Optuna 0.7612, and Hyperopt with 0.7611.

![image](https://user-images.githubusercontent.com/107082305/173399987-77cece57-24ec-4969-ac1c-5b37933886d6.png)


## Appendix 
### Parameters
Below are the parameters and their respective ranges tuned in the hyperparameter tuning process
![image](https://user-images.githubusercontent.com/107082305/173400160-65ddd7c8-7420-4096-9226-980cdb511628.png)

### Sources
- http://hyperopt.github.io/hyperopt/
- https://optuna.org/
- https://sigopt.com/

## Used By

This project is used by the following companies:
![ACN-Intel_logo](https://user-images.githubusercontent.com/91902558/157770015-ea092843-c4ee-4fb4-8207-31c0368d718b.png)

