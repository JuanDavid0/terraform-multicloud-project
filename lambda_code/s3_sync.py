import json
import urllib3
import boto3
import os
import urllib.parse # <--- NUEVA LIBRERÍA NECESARIA

s3 = boto3.client('s3')
http = urllib3.PoolManager()

def lambda_handler(event, context):
    try:
        azure_sas_url = os.environ['AZURE_SAS_URL']
        
        # Obtener info del archivo subido
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        
        # El nombre viene codificado. Lo decodificamos a texto normal.
        raw_key = event['Records'][0]['s3']['object']['key']
        file_key = urllib.parse.unquote_plus(raw_key)
        # -----------------------
        
        print(f"Procesando archivo: {file_key} en bucket {bucket_name}")
        
        # 1. Descargar el archivo de S3 a la memoria temporal (/tmp)
        # Usamos 'file_key' (el nombre real con espacios) no 'raw_key'
        download_path = f"/tmp/{os.path.basename(file_key)}"
        
        s3.download_file(bucket_name, file_key, download_path)
        
        # 2. Subirlo a Azure Blob Storage
        # Dividir URL y Token (tu corrección anterior)
        base_url, sas_token = azure_sas_url.split('?', 1)
        
        # Construir URL final
        # Nota: Para subir a Azure, también deberíamos limpiar el nombre o usar el raw_key si queremos preservar caracteres seguros,
        # pero para simplicidad usaremos el nombre base.
        safe_filename = os.path.basename(file_key)
        # Codificamos solo el nombre para la URL de Azure por si acaso tiene espacios
        encoded_filename = urllib.parse.quote(safe_filename)
        
        upload_url = f"{base_url}/{encoded_filename}?{sas_token}"
        
        with open(download_path, 'rb') as data:
            headers = {
                'x-ms-blob-type': 'BlockBlob'
            }
            
            response = http.request(
                'PUT',
                upload_url,
                body=data.read(),
                headers=headers
            )
            
        print(f"Estado subida Azure: {response.status}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Archivo replicado a Azure')
        }
        
    except Exception as e:
        print(f"ERROR FATAL: {str(e)}")
        raise e