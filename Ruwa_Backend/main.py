
from typing import Optional

from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials, firestore



cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

VALID_DIRECTIONS = ["north", "south", "east", "west"]

@app.get("/")
def health_check():
    return {"status": "Ruwa backend is running"}

from firebase_admin import auth

@app.post("/signup")
def signup(email: str, password: str, full_name: str):
    try:
        # Step 1: create the login credentials in Firebase Authentication
        user_record = auth.create_user(
            email=email,
            password=password
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Could not create account: {str(e)}")

    # Step 2: create their profile document in Firestore, using the same UID
    user_data = {
        "full_name": full_name,
        "email": email
    }
    db.collection("users").document(user_record.uid).set(user_data)

    return {"message": "Account created", "uid": user_record.uid}

    

@app.get("/users/{user_id}")
def get_user(user_id: str):
    doc = db.collection("users").document(user_id).get()
    if doc.exists:
        return doc.to_dict()
    raise HTTPException(status_code=404, detail="User not found")

security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    token = credentials.credentials

    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token["uid"]
    except Exception:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired Firebase ID token."
        )


class GardenData(BaseModel):
    facade_direction: str
    length: float = Field(gt=0)
    width: float = Field(gt=0)
    care_preference: str = Field(min_length=1)






VALID_DIRECTIONS = {"north", "south", "east", "west"}


@app.put("/garden")
def save_garden(
    garden: GardenData,
    uid: str = Depends(get_current_user)
):
    direction = garden.facade_direction.strip().lower()
    care = garden.care_preference.strip()

    if direction not in VALID_DIRECTIONS:
        raise HTTPException(
            status_code=400,
            detail="Direction must be north, south, east, or west."
        )

    if not care:
        raise HTTPException(
            status_code=400,
            detail="Care preference is required."
        )

    garden_data = {
        "facade_direction": direction,
        "length": garden.length,
        "width": garden.width,
        "care_preference": care
    }

    try:
        db.collection("users").document(uid).set(
            {"garden": garden_data},
            merge=True
        )
        return {
            "message": "Garden saved successfully.",
            "garden": garden_data
        }
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Could not save garden."
        )


@app.get("/garden")
def get_garden(uid: str = Depends(get_current_user)):
    try:
        doc = db.collection("users").document(uid).get()

        if not doc.exists:
            raise HTTPException(
                status_code=404,
                detail="User profile not found."
            )

        user_data = doc.to_dict() or {}
        garden = user_data.get("garden")

        if not garden:
            raise HTTPException(
                status_code=404,
                detail="No garden has been saved yet."
            )

        return garden

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Could not retrieve garden."
        )




from fastapi import Query

# Retrieve plants from the Firestore collection
@app.get("/plants")
def get_plants():
    try:
        docs = db.collection("plants").stream()

        plants = []
        for doc in docs:
            plant = doc.to_dict()
            plant["document_id"] = doc.id
            plants.append(plant)

        return {
            "count": len(plants),
            "plants": plants
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail="Could not retrieve plants from Firestore."
        )


# Search by full or partial plant name
@app.get("/plants/search")
def search_plants(q: str = Query(..., min_length=1)):
    try:
        query = q.strip().casefold()

        if not query:
            raise HTTPException(
                status_code=400,
                detail="Search term cannot be empty."
            )

        docs = db.collection("plants").stream()
        results = []

        for doc in docs:
            plant = doc.to_dict()

            scientific_name = str(
                plant.get("Scientific_Name") or ""
            ).casefold()

            arabic_name = str(
                plant.get("Arabic_Name") or ""
            ).casefold()

            if query in scientific_name or query in arabic_name:
                plant["document_id"] = doc.id
                results.append(plant)

        return {
            "count": len(results),
            "results": results
        }

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Plant search failed."
        )


# Retrieve the details of one plant
@app.get("/plants/{plant_id}")
def get_plant(plant_id: str):
    try:
        doc = db.collection("plants").document(plant_id).get()

        if not doc.exists:
            raise HTTPException(
                status_code=404,
                detail="Plant not found."
            )

        plant = doc.to_dict()
        plant["document_id"] = doc.id
        return plant

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Could not retrieve plant details."
        )
