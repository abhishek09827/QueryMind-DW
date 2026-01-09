import os
import io
import json
from minio import Minio
from minio.error import S3Error

class MinioClient:
    def __init__(self):
        self.client = Minio(
            os.getenv('MINIO_ENDPOINT', "localhost:9000"),
            access_key="minioadmin",
            secret_key="minioadmin",
            secure=False
        )
        self.buckets = ["raw", "bronze", "silver"]
        self._setup_buckets()

    def _setup_buckets(self):
        """Ensure required buckets exist."""
        for bucket in self.buckets:
            if not self.client.bucket_exists(bucket):
                self.client.make_bucket(bucket)
                print(f"Bucket '{bucket}' created.")
            else:
                print(f"Bucket '{bucket}' already exists.")

    def upload_json(self, bucket_name, object_name, data):
        """Upload a dictionary as a JSON file."""
        try:
            json_data = json.dumps(data).encode('utf-8')
            data_stream = io.BytesIO(json_data)
            
            self.client.put_object(
                bucket_name,
                object_name,
                data_stream,
                length=len(json_data),
                content_type='application/json'
            )
            print(f"Uploaded {object_name} to {bucket_name}")
        except S3Error as e:
            print(f"Error uploading to MinIO: {e}")

    def upload_file(self, bucket_name, object_name, file_path):
        """Upload a local file."""
        try:
            self.client.fput_object(bucket_name, object_name, file_path)
            print(f"Uploaded {file_path} as {object_name} to {bucket_name}")
        except S3Error as e:
            print(f"Error uploading file: {e}")

if __name__ == "__main__":
    # Test connection
    minio_client = MinioClient()
