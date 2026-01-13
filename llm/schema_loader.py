import json
import os

class SchemaLoader:
    def __init__(self, manifest_path):
        self.manifest_path = manifest_path

    def load_schema(self):
        """Loads Gold schema metadata from dbt manifest."""
        if not os.path.exists(self.manifest_path):
            raise FileNotFoundError(f"Manifest not found at {self.manifest_path}")

        with open(self.manifest_path, 'r') as f:
            manifest = json.load(f)

        schema_info = []

        # Iterate over nodes in the manifest
        for node_name, node in manifest['nodes'].items():
            # Filter for models in the 'marts' folder (Gold layer)
            # We check if 'marts' is in the original file path or if schema ends with 'gold'
            if node['resource_type'] == 'model' and ('marts' in node['original_file_path'] or 'gold' in node['schema']):
                
                table_info = {
                    "table_name": node['alias'], # Use alias as the actual table name
                    "schema": "gold" if node['schema'] == "public_gold" else node['schema'],
                    "description": node.get('description', ''),
                    "columns": []
                }

                for col_name, col_data in node.get('columns', {}).items():
                    table_info['columns'].append({
                        "name": col_name,
                        "type": col_data.get('data_type', 'UNKNOWN'),
                        "description": col_data.get('description', '')
                    })

                schema_info.append(table_info)

        return schema_info

if __name__ == "__main__":
    # Test execution
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    manifest_path = os.path.join(base_dir, 'dbt', 'target', 'manifest.json')
    loader = SchemaLoader(manifest_path)
    schema = loader.load_schema()
    print(json.dumps(schema, indent=2))
