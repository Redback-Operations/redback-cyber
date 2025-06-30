#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import paho.mqtt.client as mqtt
import json
import time 
import ssl  # Importing ssl certificates - ensures data transmitted is encrypted
import datetime
import base64
import hashlib
from datetime import datetime
from cryptography.fernet import Fernet  # Importing cryptography library

encryption_key = Fernet.generate_key()
cipher_suite = Fernet(encryption_key)

class MQTTDataFrameHandler:
    def __init__(self, broker_address, topic, max_retries=3, retry_interval=5):
        self.broker_address = broker_address
        self.topic = topic
        self.client = mqtt.Client()
        self.client.on_message = self._on_message
        self.data = None
        self.error = None
        self.max_retries = max_retries
        self.retry_interval = retry_interval

    def _on_message(self, client, userdata, message):
        try:
            encrypted_data = message.payload
            data_json = cipher_suite.decrypt(encrypted_data).decode('utf-8')
            self.data = pd.read_json(data_json)
            self.data['timestamp'] = time.time()
        except Exception as e:
            self.error = str(e)

    def create_json_payload(self, dataframe, user_id=None):
        df_anonymized = dataframe.copy()

        if 'name' in df_anonymized.columns:
            df_anonymized['name'] = df_anonymized['name'].apply(lambda x: 'Anonymous individual' if x else x)

        if 'mac_address' in df_anonymized.columns:
            def encode_mac(mac):
                hashed_mac = hashlib.md5(mac.encode()).digest() #nosec
                encoded_mac = base64.b64encode(hashed_mac).decode()[:10] #nosec
                return encoded_mac
        
            df_anonymized['mac_address'] = df_anonymized['mac_address'].apply(lambda x: encode_mac(x) if x else x)

        data_json = df_anonymized.to_json(orient='split')

        payload = {
            'timestamp': datetime.utcnow().isoformat(),
            'data': json.loads(data_json)
        }

        if user_id:
            payload['user_id'] = user_id

        return json.dumps(payload)

    def receive_data(self, timeout=10):
        retries = 0
        while retries < self.max_retries:
            try:
                self.client.connect(self.broker_address, 1883, 60)
                self.client.subscribe(self.topic)
                self.client.loop_start()
                start_time = time.time()
                while self.data is None and (time.time() - start_time) < timeout:
                    if self.error:
                        print(f"Error while receiving data: {self.error}")
                        break
                self.client.loop_stop()
                return self.data
            except Exception as e:
                print(f"Connection error: {e}. Retrying in {self.retry_interval} seconds...")
                retries += 1
                time.sleep(self.retry_interval)
        print("Max retries reached. Failed to receive data.")
        return None

    def send_data(self, df, user_id=None):
        retries = 0
        while retries < self.max_retries:
            try:
                json_payload = self.create_json_payload(df, user_id)
                self.client.connect(self.broker_address, 1883, 60)
                self.client.publish(self.topic, json_payload)
                self.client.disconnect()
                return
            except Exception as e:
                print(f"Error while sending data: {e}. Retrying in {self.retry_interval} seconds...")
                retries += 1
                time.sleep(self.retry_interval)
        print("Max retries reached. Failed to send data.")

def main():
    broker_address = "test.mosquitto.org"
    topic = "test/topic"

    handler = MQTTDataFrameHandler(broker_address, topic)

    handler.client.tls_set(ca_certs="ca.crt", certfile="client.crt", keyfile="client.key", tls_version=ssl.PROTOCOL_TLS)
    handler.client.username_pw_set("client_username", "client_password")

if __name__ == "__main__":
    main()

