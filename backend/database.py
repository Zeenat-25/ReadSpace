import os

from dotenv import load_dotenv
from supabase import create_client, Client


# Load values from the .env file
load_dotenv()


# Get Supabase details
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")


# Check if values are missing
if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Supabase URL or Key is missing from .env")


# Connect Python to Supabase
supabase: Client = create_client(
    SUPABASE_URL,
    SUPABASE_KEY
)