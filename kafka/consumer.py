import json
import time
import sys
import os
from datetime import datetime
from kafka import KafkaConsumer

# Add project root to path to import minio.utils
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from data_utils.utils import MinioClient

# Configuration
KAFKA_BOOTSTRAP_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092').split(',')
TOPICS = ['orders', 'customers', 'payments', 'items', 'products', 'sellers', 'reviews', 'geolocation']
GROUP_ID = 'data-lake-loader'
BATCH_SIZE = 100  # Number of records to buffer before writing to MinIO
BATCH_TIMEOUT_SEC = 10

class DataLakeConsumer:
    def __init__(self):
        self.minio = MinioClient()
        self.consumer = KafkaConsumer(
            *TOPICS,
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            group_id=GROUP_ID,
            auto_offset_reset='earliest',
            value_deserializer=lambda x: json.loads(x.decode('utf-8'))
        )
        self.buffer = {topic: [] for topic in TOPICS}
        self.last_flush_time = time.time()

    def flush_buffer(self, topic):
        """Write buffered data to MinIO."""
        if not self.buffer[topic]:
            return

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{topic}/batch_{timestamp}.json"
        
        # Upload to MinIO 'raw' bucket
        self.minio.upload_json('raw', filename, self.buffer[topic])
        
        print(f"Flushed {len(self.buffer[topic])} records to raw/{filename}")
        self.buffer[topic] = []

    def consume(self):
        print("Starting Data Lake Consumer...")
        try:
            for message in self.consumer:
                topic = message.topic
                data = message.value
                
                self.buffer[topic].append(data)
                
                # Check flush conditions
                if len(self.buffer[topic]) >= BATCH_SIZE:
                    self.flush_buffer(topic)
                
                # Time-based flush check (periodically check all topics)
                current_time = time.time()
                if current_time - self.last_flush_time > BATCH_TIMEOUT_SEC:
                    for t in TOPICS:
                        self.flush_buffer(t)
                    self.last_flush_time = current_time
                    
        except KeyboardInterrupt:
            print("Stopping consumer...")
        finally:
            # Flush remaining data
            for topic in TOPICS:
                self.flush_buffer(topic)
            self.consumer.close()

if __name__ == "__main__":
    # Wait for Kafka/MinIO to be ready
    time.sleep(10)
    
    loader = DataLakeConsumer()
    loader.consume()
