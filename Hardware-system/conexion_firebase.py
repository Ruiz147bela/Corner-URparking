import firebase_admin
from firebase_admin import credentials, firestore

# Conectar con Firebase
cred = credentials.Certificate("/ruta/a/credenciales.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def verificar_placa(placa):
    doc_ref = db.collection('reservas').document(placa)
    doc = doc_ref.get()
    if doc.exists:
        print(f"Placa {placa} encontrada, acceso permitido.")
        return True
    else:
        print(f"Placa {placa} no encontrada, acceso denegado.")
        return False
