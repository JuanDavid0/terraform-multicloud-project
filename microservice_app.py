from flask import Flask, render_template_string, request, redirect, url_for
import boto3
import os
from datetime import datetime

app = Flask(__name__)

# --- CONFIGURACIÓN ---
# Estas variables vendrán desde Terraform
TABLE_NAME = os.environ.get('DYNAMO_TABLE', 'Error-NoTableDefined')
BUCKET_NAME = os.environ.get('S3_BUCKET', 'Error-NoBucketDefined')
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')

# Clientes de AWS
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
s3 = boto3.client('s3', region_name=AWS_REGION)
table = dynamodb.Table(TABLE_NAME)

# --- HTML TEMPLATE (Interfaz Gráfica) ---
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Panel de Control Cloud</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f4f6f9; padding-top: 40px; }
        .card { box-shadow: 0 4px 6px rgba(0,0,0,0.1); border: none; }
        .header-title { color: #0d6efd; font-weight: bold; }
    </style>
</head>
<body>
<div class="container">
    <div class="text-center mb-5">
        <h1 class="header-title"> Gestión de AWS & Azure Sync</h1>
        <p class="text-muted">Desde este microservicio en Fargate, interactúas con AWS y se replica a Azure.</p>
    </div>

    <div class="row">
        <div class="col-md-6">
            <div class="card p-4">
                <h3> Registrar Usuario</h3>
                <p class="small text-muted">Se guardará en DynamoDB y replicará a CosmosDB.</p>
                <form action="/add_user" method="post">
                    <div class="mb-3">
                        <label>ID Usuario:</label>
                        <input type="text" name="user_id" class="form-control" placeholder="ej: user_100" required>
                    </div>
                    <div class="mb-3">
                        <label>Nombre Completo:</label>
                        <input type="text" name="nombre" class="form-control" placeholder="ej: Pepito Pérez" required>
                    </div>
                    <button type="submit" class="btn btn-primary w-100">Guardar en Base de Datos</button>
                </form>
            </div>
        </div>

        <div class="col-md-6">
            <div class="card p-4">
                <h3> Subir Archivo</h3>
                <p class="small text-muted">Se subirá a S3 y replicará a Blob Storage.</p>
                <form action="/upload_file" method="post" enctype="multipart/form-data">
                    <div class="mb-3">
                        <label>Seleccionar Archivo:</label>
                        <input type="file" name="file" class="form-control" required>
                    </div>
                    <button type="submit" class="btn btn-success w-100">Cargar a la Nube</button>
                </form>
            </div>
        </div>
    </div>

    {% if message %}
    <div class="alert alert-info mt-4 text-center" role="alert">
        {{ message }}
    </div>
    {% endif %}
    
    <div class="mt-5 text-center text-muted small">
        <p>Contenedor ID: <strong>{{ hostname }}</strong> | Bucket: {{ bucket }} | Tabla: {{ table }}</p>
    </div>
</div>
</body>
</html>
"""

@app.route('/')
def index():
    msg = request.args.get('msg', '')
    return render_template_string(HTML_TEMPLATE, 
                                  hostname=os.uname()[1], 
                                  message=msg,
                                  bucket=BUCKET_NAME,
                                  table=TABLE_NAME)

@app.route('/add_user', methods=['POST'])
def add_user():
    user_id = request.form['user_id']
    nombre = request.form['nombre']
    try:
        # Guardar en DynamoDB
        table.put_item(Item={
            'id': user_id,
            'nombre': nombre,
            'fecha': str(datetime.now())
        })
        return redirect(url_for('index', msg=f" Usuario '{nombre}' guardado en DynamoDB exitosamente."))
    except Exception as e:
        return redirect(url_for('index', msg=f" Error en DynamoDB: {str(e)}"))

@app.route('/upload_file', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return redirect(url_for('index', msg="No se seleccionó archivo"))
    
    file = request.files['file']
    if file.filename == '':
        return redirect(url_for('index', msg="Nombre de archivo vacío"))

    try:
        # Subir a S3
        s3.upload_fileobj(file, BUCKET_NAME, file.filename)
        return redirect(url_for('index', msg=f"Archivo '{file.filename}' subido a S3 exitosamente."))
    except Exception as e:
        return redirect(url_for('index', msg=f" Error en S3: {str(e)}"))

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)