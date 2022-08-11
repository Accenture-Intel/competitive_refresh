#!/usr/bin/env python
# coding: utf-8

# In[ ]:


get_ipython().system('pip install datasets evaluate transformers[sentencepiece]')


# In[16]:


from datasets import load_dataset
from transformers import AutoTokenizer, DataCollatorWithPadding
import numpy as np
import tensorflow as tf
import time


# In[13]:


print(tf.__version__)


# In[2]:


task = "cola"
dataset = load_dataset("glue", task)
checkpoint = "bert-base-uncased"
tokenizer = AutoTokenizer.from_pretrained(checkpoint)


# In[14]:


dataset


# In[3]:


task_to_keys = {
    "cola": ("sentence", None),
    "mnli": ("premise", "hypothesis"),
    "mnli-mm": ("premise", "hypothesis"),
    "mrpc": ("sentence1", "sentence2"),
    "qnli": ("question", "sentence"),
    "qqp": ("question1", "question2"),
    "rte": ("sentence1", "sentence2"),
    "sst2": ("sentence", None),
    "stsb": ("sentence1", "sentence2"),
    "wnli": ("sentence1", "sentence2"),
}


# In[4]:


sentence1_key, sentence2_key = task_to_keys[task]


# In[5]:


def tokenize_function(examples):
    if sentence2_key is None:
        return tokenizer(examples[sentence1_key], truncation=True)
    return tokenizer(examples[sentence1_key], examples[sentence2_key], truncation=True)


# In[7]:


tokenized_datasets = dataset.map(tokenize_function, batched=True)


# In[8]:


data_collator = DataCollatorWithPadding(tokenizer=tokenizer, return_tensors="tf")


# In[9]:


tf_train_dataset = tokenized_datasets["train"].to_tf_dataset(
    columns=["attention_mask", "input_ids", "token_type_ids"],
    label_cols=["labels"],
    shuffle=True,
    collate_fn=data_collator,
    batch_size=8,
)

tf_validation_dataset = tokenized_datasets["validation"].to_tf_dataset(
    columns=["attention_mask", "input_ids", "token_type_ids"],
    label_cols=["labels"],
    shuffle=False,
    collate_fn=data_collator,
    batch_size=8,
)


# In[10]:


from transformers import TFAutoModelForSequenceClassification

model = TFAutoModelForSequenceClassification.from_pretrained(checkpoint, num_labels=2)


# In[24]:


from tensorflow.keras.losses import SparseCategoricalCrossentropy

model.compile(
    optimizer="adam",
    loss=SparseCategoricalCrossentropy(from_logits=True),
    metrics=["accuracy"],
)
start = time.time()
model.fit(
    tf_train_dataset,
    validation_data=tf_validation_dataset,
)
end = time.time() - start
print("Training Time: ", end)


# # Fine Tuning 

# In[25]:


from tensorflow.keras.optimizers.schedules import PolynomialDecay

batch_size = 8
num_epochs = 3
# The number of training steps is the number of samples in the dataset, divided by the batch size then multiplied
# by the total number of epochs. Note that the tf_train_dataset here is a batched tf.data.Dataset,
# not the original Hugging Face Dataset, so its len() is already num_samples // batch_size.
num_train_steps = len(tf_train_dataset) * num_epochs
lr_scheduler = PolynomialDecay(
    initial_learning_rate=5e-5, end_learning_rate=0.0, decay_steps=num_train_steps
)
from tensorflow.keras.optimizers import Adam

opt = Adam(learning_rate=lr_scheduler)


# In[28]:


model = TFAutoModelForSequenceClassification.from_pretrained(checkpoint, num_labels=2)
loss = tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True)
model.compile(optimizer=opt, loss=loss, metrics=["accuracy"])


# In[29]:


start_tune = time.time()
model.fit(tf_train_dataset, validation_data=tf_validation_dataset, epochs=3)
end_tune = time.time() - start_tune
print("Fine Tuning Training Time: ", end_tune)


# In[30]:


preds = model.predict(tf_validation_dataset)["logits"]


# In[31]:


class_preds = np.argmax(preds, axis=1)
print(preds.shape, class_preds.shape)


# In[33]:


import evaluate

metric = evaluate.load("glue", "cola")
metric.compute(predictions=class_preds, references=dataset["validation"]["label"])


# In[ ]:




