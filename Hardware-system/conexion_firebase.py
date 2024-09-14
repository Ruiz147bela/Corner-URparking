import firebase_admin
from firebase_admin import credentials, firestore

# Configurar Firebase
cred = credentials.Certificate("/Users/isabela/Desktop/Corner-URparking/iOS-app/ur-parking-68811-firebase-adminsdk-5bpqm-58ecf1becb.json")  
firebase_admin.initialize_app(cred)
db = firestore.client()

# Función para verificar la placa
def verificar_placa(placa):
    doc_ref = db.collection('reservas').document(placa)
    doc = doc_ref.get()
    if doc.exists:
        print(f"Placa {placa} verificada. Acceso permitido.")
        return True
    else:
        print("Acceso denegado.")
        return False
