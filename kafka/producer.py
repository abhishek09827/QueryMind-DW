import time
import json
import csv
import os
from kafka import KafkaProducer
from kafka.admin import KafkaAdminClient, NewTopic
from kafka.errors import TopicAlreadyExistsError

# Configuration
KAFKA_BOOTSTRAP_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092').split(',')
KAFKA_BOOTSTRAP_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092').split(',')
DATASETS_DIR = os.getenv('DATASETS_DIR', '/opt/airflow/datasets')
if not os.path.exists(DATASETS_DIR):
    # Fallback for local testing if not in Docker
    DATASETS_DIR = os.path.join(os.path.dirname(__file__), '../datasets')
TOPICS = {
    'orders': 'olist_orders_dataset.csv',
    'customers': 'olist_customers_dataset.csv',
    'payments': 'olist_order_payments_dataset.csv',
    'items': 'olist_order_items_dataset.csv',
    'products': 'olist_products_dataset.csv',
    'sellers': 'olist_sellers_dataset.csv',
    'reviews': 'olist_order_reviews_dataset.csv',
    'geolocation': 'olist_geolocation_dataset.csv'
}

def create_topics(admin_client, topic_names):
    """Create Kafka topics if they don't exist."""
    new_topics = []
    for topic in topic_names:
        new_topics.append(NewTopic(name=topic, num_partitions=1, replication_factor=1))
    
    try:
        admin_client.create_topics(new_topics=new_topics)
        print("Topics created:", topic_names)
    except TopicAlreadyExistsError:
        print("Topics already exist.")
    except Exception as e:
        print(f"Error creating topics: {e}")

def delivery_report(err, msg):
    if err is not None:
        print(f'Message delivery failed: {err}')
    else:
        # print(f'Message delivered to {msg.topic()} [{msg.partition()}]')
        pass

def produce_data(producer):
    """Read CSVs and stream to Kafka."""
    for topic, filename in TOPICS.items():
        filepath = os.path.join(DATASETS_DIR, filename)
        if not os.path.exists(filepath):
            print(f"File not found: {filepath}, skipping...")
            continue
        
        print(f"Streaming {filename} to topic '{topic}'...")
        
        with open(filepath, mode='r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            count = 0
            for row in reader:
                # Send data
                producer.send(topic, value=row).add_callback(delivery_report)
                count += 1
                
                # Simulate streaming
                if count % 100 == 0:
                    print(f"Sent {count} records to {topic}")
                    producer.flush()
                    # time.sleep(0.1) # Uncomment to slow down
                    
            print(f"Finished sending {count} records to {topic}")
    
    producer.flush()

if __name__ == "__main__":
    # Wait for Kafka to be ready
    print("Waiting for Kafka...")
    time.sleep(5) 
    
    # Create Admin Client
    admin_client = KafkaAdminClient(bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS, client_id='admin')
    create_topics(admin_client, list(TOPICS.keys()))
    
    # Create Producer
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )
    
    produce_data(producer)
    producer.close()
