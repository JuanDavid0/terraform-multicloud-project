import json
import os
import hmac
import hashlib
import base64
import urllib.request
import urllib.parse
from datetime import datetime

# --- CLASE PARA GENERAR EL TOKEN DE SEGURIDAD (LA PARTE DIFÍCIL) ---
class AzureAuth:
    def get_authorization_token(self, verb, resource_type, resource_id, date, master_key):
        # Decodificar la llave maestra de Azure
        key = base64.b64decode(master_key)
        
        # Crear el mensaje que se va a firmar (Formato estricto de Microsoft)
        # Verb + ResourceType + ResourceLink + Date + ""
        text = (verb.lower() + '\n' + 
                resource_type.lower() + '\n' + 
                resource_id + '\n' + 
                date.lower() + '\n' + 
                '' + '\n')
        
        # Encriptar usando HMAC-SHA256
        body = text.encode('utf-8')
        digest = hmac.new(key, body, hashlib.sha256).digest()
        signature = base64.b64encode(digest).decode('utf-8')
        
        # Codificar para URL
        master_token = "master"
        token_version = "1.0"
        return urllib.parse.quote(f'type={master_token}&ver={token_version}&sig={signature}')

def lambda_handler(event, context):
    # 1. Obtener credenciales
    cosmos_endpoint = os.environ['COSMOS_ENDPOINT'].strip('/') # Quitamos slash final si existe
    cosmos_key = os.environ['COSMOS_KEY']
    
    # Nombres fijos que definimos en Terraform
    database_id = "ReplicaDB"
    container_id = "TablaUsuariosReplica"
    
    # Generador de tokens
    auth = AzureAuth()
    
    # Procesar registros de DynamoDB
    results = []
    
    for record in event['Records']:
        # Solo nos interesan las INSERCIONES o MODIFICACIONES
        if record['eventName'] in ['INSERT', 'MODIFY']:
            try:
                # --- A. PREPARAR EL DATO (JSON) ---
                new_image = record['dynamodb']['NewImage']
                document = {}
                
                # Convertir formato DynamoDB ({'S': 'val'}) a JSON normal
                for key, value in new_image.items():
                    if 'S' in value: document[key] = value['S']
                    elif 'N' in value: document[key] = float(value['N'])
                    elif 'BOOL' in value: document[key] = value['BOOL']
                    # Puedes agregar más tipos si lo necesitas (Listas, Mapas)
                
                # --- B. PREPARAR LA PETICIÓN HTTP A AZURE ---
                # La fecha debe ser UTC y en formato específico
                now = datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S GMT')
                
                # El ID del recurso para firmar es "dbs/<id>/colls/<id>"
                resource_link = f"dbs/{database_id}/colls/{container_id}"
                
                # Generar el token de autorización
                auth_token = auth.get_authorization_token(
                    verb="POST",
                    resource_type="docs",
                    resource_id=resource_link,
                    date=now,
                    master_key=cosmos_key
                )
                
                # URL final de la API: .../docs
                url = f"{cosmos_endpoint}/{resource_link}/docs"
                
                # Headers obligatorios para Cosmos DB REST API
                headers = {
                    'Authorization': auth_token,
                    'x-ms-date': now,
                    'x-ms-version': '2018-12-31',
                    'Content-Type': 'application/json',
                    'x-ms-documentdb-partitionkey': json.dumps([document.get('id')]) # Obligatorio
                }
                
                # --- C. ENVIAR (POST) ---
                json_data = json.dumps(document).encode('utf-8')
                req = urllib.request.Request(url, data=json_data, headers=headers, method='POST')
                
                with urllib.request.urlopen(req) as response:
                    print(f"Éxito: {response.status} - ID: {document.get('id')}")
                    results.append(f"OK: {document.get('id')}")
            
            except Exception as e:
                print(f"Error replicando ID {document.get('id')}: {str(e)}")
                # Imprimir respuesta de error si existe para debug
                results.append(f"Error: {str(e)}")
                
    return {
        'statusCode': 200,
        'body': json.dumps(results)
    }