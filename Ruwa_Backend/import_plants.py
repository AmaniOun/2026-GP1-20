
import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore

# Connect to Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("firebase-key.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()
collection = db.collection("plants")

# Read the latest dataset
df = pd.read_excel(
    "Ruwa_dataset.xlsx",
    sheet_name="Plants"
)

# Correct the typo in the Excel column name
if "Recored_Type" in df.columns:
    if "Record_Type" in df.columns:
        raise ValueError(
            "Both Recored_Type and Record_Type exist. Resolve the duplicate."
        )
    df.rename(
        columns={"Recored_Type": "Record_Type"},
        inplace=True
    )

# Validate required columns
required_columns = [
    "Plant_ID",
    "Scientific_Name",
    "Arabic_Name",
    "Climate_Tolerance",
    "Record_Type",
]

missing_columns = [
    col for col in required_columns
    if col not in df.columns
]

if missing_columns:
    raise ValueError(
        f"Missing required columns: {missing_columns}"
    )

if df.empty:
    raise ValueError("Dataset is empty. Import cancelled.")

# Validate plant IDs
df["Plant_ID"] = df["Plant_ID"].astype("string").str.strip()

if df["Plant_ID"].isna().any() or (df["Plant_ID"] == "").any():
    raise ValueError("Missing or empty Plant_ID found.")

if df["Plant_ID"].duplicated().any():
    raise ValueError("Duplicate Plant_ID values found.")

# Validate record types
df["Record_Type"] = df["Record_Type"].astype("string").str.strip()

allowed_types = {"Validated", "Predicted"}
actual_types = set(df["Record_Type"].dropna().tolist())

if df["Record_Type"].isna().any() or not actual_types.issubset(allowed_types):
    raise ValueError(
        f"Record_Type must contain only {allowed_types}. "
        f"Found: {actual_types}"
    )

new_ids = set(df["Plant_ID"].tolist())

print(f"Validated {len(df)} plants.")
print(f"Record types found: {actual_types}")

# Read existing documents before updating
existing_docs = list(collection.stream())
existing_ids = {doc.id for doc in existing_docs}

print(f"Existing Firebase plant records: {len(existing_ids)}")
print(f"Old records to remove: {len(existing_ids - new_ids)}")

def clean_value(value):
    if pd.isna(value):
        return None
    if hasattr(value, "item"):
        return value.item()
    return value

# Replace records and delete obsolete IDs in batches
batch = db.batch()
batch_count = 0

def commit_batch():
    global batch, batch_count
    if batch_count:
        batch.commit()
    batch = db.batch()
    batch_count = 0

# Write the new dataset
for _, row in df.iterrows():
    record = {
        column: clean_value(value)
        for column, value in row.items()
    }

    plant_id = record["Plant_ID"]
    batch.set(collection.document(plant_id), record)
    batch_count += 1

    if batch_count == 400:
        commit_batch()

# Delete records not included in the new dataset
for old_id in existing_ids - new_ids:
    batch.delete(collection.document(old_id))
    batch_count += 1

    if batch_count == 400:
        commit_batch()

commit_batch()

# Verify Firebase matches the Excel dataset
final_docs = list(collection.stream())
final_ids = {doc.id for doc in final_docs}

print(f"Final Firebase plant count: {len(final_docs)}")

if final_ids != new_ids:
    raise RuntimeError(
        "Verification failed: Firebase IDs do not match the Excel dataset."
    )

print("SUCCESS: Firebase matches the new dataset.")
