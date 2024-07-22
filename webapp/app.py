import streamlit as st
import pymongo
import os

# Initialize connection.
# Uses st.cache_resource to only run once.
@st.cache_resource
def init_connection():
    return pymongo.MongoClient(**st.secrets["mongo"])

client = init_connection()

# Pull data from the collection.
# Uses st.cache_data to only rerun when the query changes or after 10 min.
#@st.cache_data(ttl=600)
def get_data():
    db = client.wizdemo
    os.write(1, f"{db.list_collection_names()}\n".encode()) 
    items = db.sample_data.find()
    items = list(items)  # make hashable for st.cache_data
    os.write(1, f"{len(items)}\n".encode()) 
    return items

items = get_data()
# Print results.
for item in items:
    os.write(1, f"{item['name']}\n".encode()) 
    st.write(f"{item['name']}")
