from datetime import datetime, timedelta
import os
import json

import firebase_admin
from firebase_admin import credentials, messaging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from database import supabase


app = FastAPI(
    title="ReadSpace API",
    version="1.0.0"
)




# =========================================================
# FIREBASE PUSH NOTIFICATIONS
# =========================================================

firebase_ready = False

try:
    if not firebase_admin._apps:

        # ---------------------------------------------
        # Render / Production
        # Reads Firebase JSON directly from env variable
        # ---------------------------------------------
        firebase_json = os.getenv(
            "FIREBASE_SERVICE_ACCOUNT_JSON"
        )

        if firebase_json:
            service_account_info = json.loads(
                firebase_json
            )

            cred = credentials.Certificate(
                service_account_info
            )

            firebase_admin.initialize_app(cred)
            firebase_ready = True

        # ---------------------------------------------
        # Local Development
        # Uses firebase-service-account.json file
        # ---------------------------------------------
        else:
            firebase_file = os.getenv(
                "FIREBASE_SERVICE_ACCOUNT",
                "firebase-service-account.json"
            )

            if os.path.exists(firebase_file):
                cred = credentials.Certificate(
                    firebase_file
                )

                firebase_admin.initialize_app(cred)
                firebase_ready = True

    else:
        firebase_ready = True

except Exception as firebase_error:
    print(
        "Firebase initialization skipped:",
        firebase_error
    )


def send_push_notification(
    token: str | None,
    title: str,
    body: str,
    data: dict | None = None
):
    if not firebase_ready or not token:
        return False

    try:
        message = messaging.Message(
            token=token,
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            data={
                str(key): str(value)
                for key, value in (
                    data or {}
                ).items()
            }
        )

        messaging.send(message)
        return True

    except Exception as push_error:
        print(
            "Push notification failed:",
            push_error
        )
        return False

# =========================================================
# CORS
# Allows React dashboard to communicate with FastAPI
# =========================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "https://readspace-dashboard.vercel.app",
],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =========================================================
# DATETIME HELPER
# =========================================================

def parse_supabase_datetime(value):
    if not value:
        return None

    text = str(value).strip()

    if text.endswith("Z"):
        text = text[:-1] + "+00:00"

    try:
        return datetime.fromisoformat(text)
    except ValueError:
        pass

    if "." in text:
        main_part, rest = text.split(".", 1)
        timezone_part = ""
        fraction_part = rest

        if "+" in rest:
            fraction_part, timezone_part = rest.split("+", 1)
            timezone_part = "+" + timezone_part
        else:
            minus_index = rest.find("-")
            if minus_index > 0:
                fraction_part = rest[:minus_index]
                timezone_part = rest[minus_index:]

        fraction_part = fraction_part[:6].ljust(6, "0")
        fixed_text = main_part + "." + fraction_part + timezone_part
        return datetime.fromisoformat(fixed_text)

    raise ValueError(f"Invalid datetime value: {value}")


# =========================================================
# REQUEST MODELS
# =========================================================
class AddStudentRequest(BaseModel):
    student_id: str
    name: str
    email: str
    phone: str
    course: str
    year: str
    division: str

class AddLibrarianRequest(BaseModel):
    employee_id: str
    name: str
    email: str
    role: str

class IssueBookRequest(BaseModel):
    student_id: str
    accession_number: str
    librarian_id: str


class ReturnBookRequest(BaseModel):
    accession_number: str
    librarian_id: str

class AddBookRequest(BaseModel):
    title: str
    author: str
    isbn: str
    publisher: str
    edition: str
    category: str
    accession_number: str
    barcode: str


class FcmTokenRequest(BaseModel):
    token: str


# =========================================================
# HOME
# =========================================================

@app.get("/")
def home():
    return {
        "success": True,
        "message": "ReadSpace Backend is Running"
    }


# =========================================================
# GET ALL BOOKS
# =========================================================

@app.get("/books")
def get_books():
    try:
        response = (
            supabase
            .table("books")
            .select("*")
            .execute()
        )

        return response.data

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }


# =========================================================
# GET BOOKS WITH COPY STATUS
# =========================================================

@app.get("/books/status")
def get_books_with_status():
    try:
        response = (
            supabase
            .table("book_copies")
            .select(
                """
                id,
                accession_number,
                barcode,
                status,
                books (
                    id,
                    title,
                    author,
                    isbn,
                    category
                )
                """
            )
            .order("accession_number")
            .execute()
        )

        return response.data

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }






# =========================================================
# SEARCH BOOK AVAILABILITY FOR STUDENT APP
# =========================================================

@app.get("/books/search")
def search_books(q: str = ""):
    try:
        query = q.strip()

        response = (
            supabase
            .table("book_copies")
            .select(
                """
                id,
                accession_number,
                barcode,
                status,
                books (
                    id,
                    title,
                    author,
                    isbn,
                    category
                )
                """
            )
            .order("accession_number")
            .execute()
        )

        copies = response.data or []

        if query:
            term = query.lower()

            filtered = []

            for copy in copies:
                book = copy.get("books") or {}

                values = [
                    copy.get("accession_number"),
                    copy.get("barcode"),
                    book.get("title"),
                    book.get("author"),
                    book.get("isbn"),
                    book.get("category"),
                ]

                if any(
                    term in str(value).lower()
                    for value in values
                    if value is not None
                ):
                    filtered.append(copy)

            copies = filtered

        return {
            "success": True,
            "books": copies
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

# =========================================================
# LOOKUP BOOK BY ACCESSION OR BARCODE
# =========================================================

@app.get("/books/lookup/{code}")
def lookup_book(code: str):
    try:
        clean_code = code.strip().upper()

        copy_response = (
            supabase
            .table("book_copies")
            .select(
                """
                id,
                accession_number,
                barcode,
                status,
                books (
                    id,
                    title,
                    author,
                    isbn,
                    category
                )
                """
            )
            .eq(
                "accession_number",
                clean_code
            )
            .limit(1)
            .execute()
        )

        if not copy_response.data:
            copy_response = (
                supabase
                .table("book_copies")
                .select(
                    """
                    id,
                    accession_number,
                    barcode,
                    status,
                    books (
                        id,
                        title,
                        author,
                        isbn,
                        category
                    )
                    """
                )
                .eq(
                    "barcode",
                    clean_code
                )
                .limit(1)
                .execute()
            )

        if not copy_response.data:
            return {
                "success": False,
                "message": "Book not found"
            }

        book_copy = copy_response.data[0]

        active_loan = None

        if book_copy["status"] == "issued":
            loan_response = (
                supabase
                .table("loans")
                .select(
                    """
                    id,
                    issue_date,
                    due_date,
                    status,
                    students (
                        student_id,
                        name,
                        course,
                        year,
                        division
                    ),
                    librarians (
                        employee_id,
                        name
                    )
                    """
                )
                .eq(
                    "book_copy_id",
                    book_copy["id"]
                )
                .eq(
                    "status",
                    "issued"
                )
                .order(
                    "issue_date",
                    desc=True
                )
                .limit(1)
                .execute()
            )

            if loan_response.data:
                active_loan = loan_response.data[0]

        return {
            "success": True,
            "book_copy": book_copy,
            "active_loan": active_loan
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }





# =========================================================
# SAVE STUDENT FCM TOKEN
# =========================================================

@app.post("/students/{student_id}/fcm-token")
def save_student_fcm_token(
    student_id: str,
    data: FcmTokenRequest
):
    try:
        clean_student_id = (
            student_id
            .strip()
            .upper()
        )

        student_response = (
            supabase
            .table("students")
            .select("id, student_id")
            .eq(
                "student_id",
                clean_student_id
            )
            .limit(1)
            .execute()
        )

        if not student_response.data:
            return {
                "success": False,
                "message": "Student not found"
            }

        student = student_response.data[0]

        (
            supabase
            .table("students")
            .update({
                "fcm_token": data.token
            })
            .eq(
                "id",
                student["id"]
            )
            .execute()
        )

        return {
            "success": True,
            "message":
                "Notification device registered"
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

# =========================================================
# LOOKUP STUDENT
# =========================================================

@app.get("/students/lookup/{student_id}")
def lookup_student(student_id: str):
    try:
        clean_student_id = student_id.strip().upper()

        student_response = (
            supabase
            .table("students")
            .select("*")
            .eq(
                "student_id",
                clean_student_id
            )
            .limit(1)
            .execute()
        )

        if not student_response.data:
            return {
                "success": False,
                "message": "Student not found"
            }

        student = student_response.data[0]

        loans_response = (
            supabase
            .table("loans")
            .select(
                """
                id,
                issue_date,
                due_date,
                status,
                book_copies (
                    accession_number,
                    books (
                        title,
                        author
                    )
                )
                """
            )
            .eq(
                "student_id",
                student["id"]
            )
            .eq(
                "status",
                "issued"
            )
            .order(
                "issue_date",
                desc=True
            )
            .execute()
        )

        active_loans = loans_response.data or []

        return {
            "success": True,
            "student": student,
            "active_loans_count": len(active_loans),
            "active_loans": active_loans
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

# =========================================================
# ISSUE BOOK
# =========================================================

@app.post("/issue-book")
def issue_book(data: IssueBookRequest):
    try:

        # -------------------------------------------------
        # Find student
        # -------------------------------------------------

        student_response = (
            supabase
            .table("students")
            .select("*")
            .eq("student_id", data.student_id)
            .limit(1)
            .execute()
        )

        if not student_response.data:
            return {
                "success": False,
                "message": "Student not found"
            }

        student = student_response.data[0]


        # -------------------------------------------------
        # Find librarian
        # -------------------------------------------------

        librarian_response = (
            supabase
            .table("librarians")
            .select("*")
            .eq("employee_id", data.librarian_id)
            .limit(1)
            .execute()
        )

        if not librarian_response.data:
            return {
                "success": False,
                "message": "Librarian not found"
            }

        librarian = librarian_response.data[0]


        # -------------------------------------------------
        # Find physical book copy
        # -------------------------------------------------

        book_response = (
            supabase
            .table("book_copies")
            .select("*")
            .eq(
                "accession_number",
                data.accession_number
            )
            .limit(1)
            .execute()
        )

        if not book_response.data:
            return {
                "success": False,
                "message": "Book copy not found"
            }

        book_copy = book_response.data[0]


        # -------------------------------------------------
        # Check book status
        # -------------------------------------------------

        if book_copy["status"] != "available":
            return {
                "success": False,
                "message":
                    f"Book is currently {book_copy['status']}"
            }


        # -------------------------------------------------
        # Create dates
        # -------------------------------------------------

        issue_date = datetime.now()
        due_date = issue_date + timedelta(days=7)


        # -------------------------------------------------
        # Create loan
        # -------------------------------------------------

        loan_response = (
            supabase
            .table("loans")
            .insert({
                "student_id": student["id"],
                "book_copy_id": book_copy["id"],
                "librarian_id": librarian["id"],
                "issue_date": issue_date.isoformat(),
                "due_date": due_date.isoformat(),
                "status": "issued",
                "fine_amount": 0
            })
            .execute()
        )


        # -------------------------------------------------
        # Change book status
        # -------------------------------------------------

        (
            supabase
            .table("book_copies")
            .update({
                "status": "issued"
            })
            .eq(
                "id",
                book_copy["id"]
            )
            .execute()
        )


        # -------------------------------------------------
        # Create student notification
        # -------------------------------------------------

        (
            supabase
            .table("notifications")
            .insert({
                "student_id": student["id"],
                "title": "Book Issued",
                "message": (
                    f"Book {data.accession_number} "
                    f"has been issued successfully. "
                    f"Please return it within 7 days."
                ),
                "notification_type": "book_issued",
                "is_read": False
            })
            .execute()
        )


        send_push_notification(
            student.get("fcm_token"),
            "Book Issued",
            (
                f"{data.accession_number} has been "
                f"issued to you. Due "
                f"{due_date.strftime('%d/%m/%Y')}."
            ),
            {
                "type": "book_issued",
                "accession_number":
                    data.accession_number,
                "due_date":
                    due_date.isoformat()
            }
        )


        return {
            "success": True,
            "message": "Book issued successfully",
            "accession_number":
                data.accession_number,
            "issue_date":
                issue_date.isoformat(),
            "due_date":
                due_date.isoformat(),
            "loan":
                loan_response.data
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }


# =========================================================
# RETURN BOOK
# =========================================================

@app.post("/return-book")
def return_book(data: ReturnBookRequest):
    try:

        # -------------------------------------------------
        # Find librarian
        # -------------------------------------------------

        librarian_response = (
            supabase
            .table("librarians")
            .select("*")
            .eq(
                "employee_id",
                data.librarian_id
            )
            .limit(1)
            .execute()
        )

        if not librarian_response.data:
            return {
                "success": False,
                "message": "Librarian not found"
            }


        # -------------------------------------------------
        # Find physical book
        # -------------------------------------------------

        book_response = (
            supabase
            .table("book_copies")
            .select("*")
            .eq(
                "accession_number",
                data.accession_number
            )
            .limit(1)
            .execute()
        )

        if not book_response.data:
            return {
                "success": False,
                "message": "Book copy not found"
            }

        book_copy = book_response.data[0]


        # -------------------------------------------------
        # Find active loan
        # -------------------------------------------------

        loan_response = (
            supabase
            .table("loans")
            .select("*")
            .eq(
                "book_copy_id",
                book_copy["id"]
            )
            .eq(
                "status",
                "issued"
            )
            .order(
                "issue_date",
                desc=True
            )
            .limit(1)
            .execute()
        )

        if not loan_response.data:
            return {
                "success": False,
                "message":
                    "No active loan found for this book"
            }

        active_loan = loan_response.data[0]


        # -------------------------------------------------
        # Calculate return date
        # -------------------------------------------------

        return_date = datetime.now()

        due_date = parse_supabase_datetime(
            active_loan["due_date"]
        )

        if due_date.tzinfo is not None:
            return_date = (
                return_date
                .astimezone(due_date.tzinfo)
            )


        # -------------------------------------------------
        # Calculate late days
        # -------------------------------------------------

        late_days = 0

        if return_date.date() > due_date.date():
            late_days = (
                return_date.date()
                - due_date.date()
            ).days


        # Temporary test fine
        fine_per_day = 5
        fine_amount = (
            late_days * fine_per_day
        )


        # -------------------------------------------------
        # Update loan
        # -------------------------------------------------

        (
            supabase
            .table("loans")
            .update({
                "return_date":
                    return_date.isoformat(),
                "status":
                    "returned",
                "fine_amount":
                    fine_amount
            })
            .eq(
                "id",
                active_loan["id"]
            )
            .execute()
        )


        # -------------------------------------------------
        # Make book available
        # -------------------------------------------------

        (
            supabase
            .table("book_copies")
            .update({
                "status": "available"
            })
            .eq(
                "id",
                book_copy["id"]
            )
            .execute()
        )


        # -------------------------------------------------
        # Create return notification
        # -------------------------------------------------

        (
            supabase
            .table("notifications")
            .insert({
                "student_id":
                    active_loan["student_id"],
                "title":
                    "Book Returned",
                "message": (
                    f"Book {data.accession_number} "
                    f"has been returned successfully."
                ),
                "notification_type":
                    "book_returned",
                "is_read":
                    False
            })
            .execute()
        )


        returned_student_response = (
            supabase
            .table("students")
            .select(
                "id, student_id, fcm_token"
            )
            .eq(
                "id",
                active_loan["student_id"]
            )
            .limit(1)
            .execute()
        )

        if returned_student_response.data:
            returned_student = (
                returned_student_response.data[0]
            )

            push_body = (
                f"{data.accession_number} was "
                f"returned successfully."
            )

            if fine_amount > 0:
                push_body += (
                    f" Fine: ₹{fine_amount}."
                )

            send_push_notification(
                returned_student.get(
                    "fcm_token"
                ),
                "Book Returned",
                push_body,
                {
                    "type": "book_returned",
                    "accession_number":
                        data.accession_number,
                    "fine_amount":
                        fine_amount
                }
            )


        return {
            "success": True,
            "message":
                "Book returned successfully",
            "accession_number":
                data.accession_number,
            "late_days":
                late_days,
            "fine_amount":
                fine_amount
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }




# =========================================================
# GET STUDENT CURRENT LOANS
# =========================================================

@app.get("/students/{student_id}/current-loans")
def get_student_current_loans(student_id: str):
    try:
        clean_student_id = student_id.strip().upper()

        student_response = (
            supabase
            .table("students")
            .select("*")
            .eq(
                "student_id",
                clean_student_id
            )
            .limit(1)
            .execute()
        )

        if not student_response.data:
            return {
                "success": False,
                "message": "Student not found"
            }

        student = student_response.data[0]

        loans_response = (
            supabase
            .table("loans")
            .select(
                """
                id,
                issue_date,
                due_date,
                status,
                fine_amount,
                book_copies (
                    accession_number,
                    barcode,
                    books (
                        title,
                        author,
                        category
                    )
                )
                """
            )
            .eq(
                "student_id",
                student["id"]
            )
            .eq(
                "status",
                "issued"
            )
            .order(
                "issue_date",
                desc=True
            )
            .execute()
        )

        loans = loans_response.data or []

        now = datetime.now()
        fine_per_day = 5

        enriched_loans = []
        total_current_fine = 0

        for loan in loans:
            due_date = parse_supabase_datetime(
                loan.get("due_date")
            )

            current_time = now

            if (
                due_date is not None
                and due_date.tzinfo is not None
            ):
                current_time = now.astimezone(
                    due_date.tzinfo
                )

            late_days = 0

            if (
                due_date is not None
                and current_time.date() > due_date.date()
            ):
                late_days = (
                    current_time.date()
                    - due_date.date()
                ).days

            current_fine = late_days * fine_per_day
            total_current_fine += current_fine

            enriched_loan = dict(loan)
            enriched_loan["late_days"] = late_days
            enriched_loan["current_fine"] = current_fine

            enriched_loans.append(
                enriched_loan
            )

        return {
            "success": True,
            "student": {
                "student_id": student["student_id"],
                "name": student["name"]
            },
            "borrowed_count": len(enriched_loans),
            "total_current_fine": total_current_fine,
            "loans": enriched_loans
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

# =========================================================
# GET STUDENT NOTIFICATIONS
# =========================================================

@app.get(
    "/students/{student_id}/notifications"
)
def get_student_notifications(
    student_id: str
):
    try:

        student_response = (
            supabase
            .table("students")
            .select("*")
            .eq(
                "student_id",
                student_id
            )
            .limit(1)
            .execute()
        )

        if not student_response.data:
            return {
                "success": False,
                "message": "Student not found"
            }

        student = student_response.data[0]


        notification_response = (
            supabase
            .table("notifications")
            .select("*")
            .eq(
                "student_id",
                student["id"]
            )
            .order(
                "created_at",
                desc=True
            )
            .execute()
        )


        return {
            "success": True,
            "student": {
                "student_id":
                    student["student_id"],
                "name":
                    student["name"]
            },
            "notifications":
                notification_response.data
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }


# =========================================================
# MARK NOTIFICATION AS READ
# =========================================================

@app.post("/notifications/{notification_id}/read")
def mark_notification_read(notification_id: str):
    try:
        # Update notification
        (
            supabase
            .table("notifications")
            .update({
                "is_read": True
            })
            .eq(
                "id",
                notification_id
            )
            .execute()
        )

        # Check whether it was actually updated
        check_response = (
            supabase
            .table("notifications")
            .select("id, is_read")
            .eq(
                "id",
                notification_id
            )
            .limit(1)
            .execute()
        )

        if not check_response.data:
            return {
                "success": False,
                "message": "Notification not found"
            }

        return {
            "success": True,
            "message": "Notification marked as read",
            "notification": check_response.data[0]
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }


@app.post("/add-book")
def add_book(data: AddBookRequest):
    try:

        # Check accession number
        existing_copy = (
            supabase
            .table("book_copies")
            .select("*")
            .eq("accession_number", data.accession_number)
            .execute()
        )

        if existing_copy.data:
            return {
                "success": False,
                "message": "Accession number already exists"
            }

        # Check if book already exists using ISBN
        existing_book = (
            supabase
            .table("books")
            .select("*")
            .eq("isbn", data.isbn)
            .execute()
        )

        if existing_book.data:
            book_id = existing_book.data[0]["id"]

        else:
            new_book = (
                supabase
                .table("books")
                .insert({
                    "title": data.title,
                    "author": data.author,
                    "isbn": data.isbn,
                    "publisher": data.publisher,
                    "edition": data.edition,
                    "category": data.category
                })
                .execute()
            )

            book_id = new_book.data[0]["id"]

        # Add physical copy
        new_copy = (
            supabase
            .table("book_copies")
            .insert({
                "book_id": book_id,
                "accession_number": data.accession_number,
                "barcode": data.barcode,
                "status": "available"
            })
            .execute()
        )

        return {
            "success": True,
            "message": "Book added successfully",
            "book_copy": new_copy.data
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

@app.get("/students")
def get_students():
    try:
        response = (
            supabase
            .table("students")
            .select("*")
            .order("name")
            .execute()
        )

        return {
            "success": True,
            "students": response.data
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

@app.post("/add-student")
def add_student(data: AddStudentRequest):
    try:
        existing_student = (
            supabase
            .table("students")
            .select("*")
            .eq("student_id", data.student_id)
            .execute()
        )

        if existing_student.data:
            return {
                "success": False,
                "message": "Student ID already exists"
            }

        existing_email = (
            supabase
            .table("students")
            .select("*")
            .eq("email", data.email)
            .execute()
        )

        if existing_email.data:
            return {
                "success": False,
                "message": "Email already exists"
            }

        new_student = (
            supabase
            .table("students")
            .insert({
                "student_id": data.student_id,
                "name": data.name,
                "email": data.email,
                "phone": data.phone,
                "course": data.course,
                "year": data.year,
                "division": data.division
            })
            .execute()
        )

        return {
            "success": True,
            "message": "Student added successfully",
            "student": new_student.data
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }





# =========================================================
# LIBRARIAN RECENT ACTIVITY
# =========================================================

@app.get("/librarians/{employee_id}/activity")
def get_librarian_activity(employee_id: str):
    try:
        librarian_response = (
            supabase.table("librarians")
            .select("id, employee_id, name")
            .eq("employee_id", employee_id.strip().upper())
            .limit(1).execute()
        )
        if not librarian_response.data:
            return {"success": False, "message": "Librarian not found"}

        librarian = librarian_response.data[0]
        response = (
            supabase.table("loans")
            .select("""
                id, issue_date, due_date, return_date, status, fine_amount,
                students (student_id, name),
                book_copies (accession_number, books (title, author))
            """)
            .eq("librarian_id", librarian["id"])
            .order("issue_date", desc=True)
            .limit(30).execute()
        )

        activities = []
        for loan in response.data or []:
            copy = loan.get("book_copies") or {}
            student = loan.get("students") or {}
            base = {
                "loan_id": loan.get("id"),
                "accession_number": copy.get("accession_number"),
                "book_title": (copy.get("books") or {}).get("title"),
                "student_id": student.get("student_id"),
                "student_name": student.get("name"),
            }
            if loan.get("return_date"):
                activities.append({**base, "type": "returned", "created_at": loan.get("return_date")})
            activities.append({**base, "type": "issued", "created_at": loan.get("issue_date")})

        def activity_time(item):
            try:
                return parse_supabase_datetime(item.get("created_at")) or datetime.min
            except Exception:
                return datetime.min

        activities.sort(key=activity_time, reverse=True)
        return {
            "success": True,
            "librarian": librarian,
            "activities": activities[:20]
        }
    except Exception as error:
        return {"success": False, "message": str(error)}


# =========================================================
# VALIDATE LIBRARIAN
# =========================================================

@app.get("/librarians/validate/{employee_id}")
def validate_librarian(employee_id: str):
    try:
        response = (
            supabase
            .table("librarians")
            .select(
                "id, employee_id, name, email, role"
            )
            .eq(
                "employee_id",
                employee_id.strip().upper()
            )
            .limit(1)
            .execute()
        )

        if not response.data:
            return {
                "success": False,
                "message": "Librarian not found"
            }

        return {
            "success": True,
            "message": "Librarian verified",
            "librarian": response.data[0]
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

@app.get("/librarians")
def get_librarians():
    try:
        response = (
            supabase
            .table("librarians")
            .select("*")
            .order("name")
            .execute()
        )

        return {
            "success": True,
            "librarians": response.data
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

@app.post("/add-librarian")
def add_librarian(data: AddLibrarianRequest):
    try:
        existing_employee = (
            supabase
            .table("librarians")
            .select("*")
            .eq("employee_id", data.employee_id)
            .execute()
        )

        if existing_employee.data:
            return {
                "success": False,
                "message": "Employee ID already exists"
            }

        existing_email = (
            supabase
            .table("librarians")
            .select("*")
            .eq("email", data.email)
            .execute()
        )

        if existing_email.data:
            return {
                "success": False,
                "message": "Email already exists"
            }

        new_librarian = (
            supabase
            .table("librarians")
            .insert({
                "employee_id": data.employee_id,
                "name": data.name,
                "email": data.email,
                "role": data.role
            })
            .execute()
        )

        return {
            "success": True,
            "message": "Librarian added successfully",
            "librarian": new_librarian.data
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

@app.get("/loans/active")
def get_active_loans():
    try:
        response = (
            supabase
            .table("loans")
            .select(
                """
                id,
                issue_date,
                due_date,
                status,
                fine_amount,
                students (
                    student_id,
                    name,
                    course,
                    year,
                    division
                ),
                book_copies (
                    accession_number,
                    barcode,
                    status,
                    books (
                        title,
                        author,
                        category
                    )
                ),
                librarians (
                    employee_id,
                    name
                )
                """
            )
            .eq("status", "issued")
            .order("issue_date", desc=True)
            .execute()
        )

        return {
            "success": True,
            "loans": response.data
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

@app.get("/loans/overdue")
def get_overdue_loans():
    try:
        current_time = datetime.now().isoformat()

        response = (
            supabase
            .table("loans")
            .select(
                """
                id,
                issue_date,
                due_date,
                status,
                fine_amount,
                students (
                    student_id,
                    name,
                    course,
                    year,
                    division
                ),
                book_copies (
                    accession_number,
                    barcode,
                    status,
                    books (
                        title,
                        author,
                        category
                    )
                ),
                librarians (
                    employee_id,
                    name
                )
                """
            )
            .eq("status", "issued")
            .lt("due_date", current_time)
            .order("due_date")
            .execute()
        )

        return {
            "success": True,
            "overdue_loans": response.data
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }
    
@app.get("/notifications")
def get_all_notifications():
    try:
        response = (
            supabase
            .table("notifications")
            .select(
                """
                id,
                title,
                message,
                notification_type,
                is_read,
                created_at,
                students (
                    student_id,
                    name
                )
                """
            )
            .order("created_at", desc=True)
            .execute()
        )

        return {
            "success": True,
            "notifications": response.data
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }
@app.get("/reports/summary")
def get_reports_summary():
    try:
        books_response = (
            supabase
            .table("book_copies")
            .select("id, status")
            .execute()
        )

        students_response = (
            supabase
            .table("students")
            .select("id")
            .execute()
        )

        librarians_response = (
            supabase
            .table("librarians")
            .select("id")
            .execute()
        )

        loans_response = (
            supabase
            .table("loans")
            .select("id, status, due_date")
            .execute()
        )

        book_copies = books_response.data or []
        students = students_response.data or []
        librarians = librarians_response.data or []
        loans = loans_response.data or []

        total_books = len(book_copies)

        available_books = len([
            book
            for book in book_copies
            if book["status"] == "available"
        ])

        issued_books = len([
            book
            for book in book_copies
            if book["status"] == "issued"
        ])

        reserved_books = len([
            book
            for book in book_copies
            if book["status"] == "reserved"
        ])

        returned_loans = len([
            loan
            for loan in loans
            if loan["status"] == "returned"
        ])

        active_loans = len([
            loan
            for loan in loans
            if loan["status"] == "issued"
        ])

        current_time = datetime.now()

        overdue_loans = 0

        for loan in loans:
            if (
                loan["status"] == "issued"
                and loan.get("due_date")
            ):
                due_date = parse_supabase_datetime(
                    loan["due_date"]
                )

                now = current_time

                if due_date.tzinfo is not None:
                    now = now.astimezone(
                        due_date.tzinfo
                    )

                if now > due_date:
                    overdue_loans += 1

        return {
            "success": True,
            "report": {
                "total_books": total_books,
                "available_books": available_books,
                "issued_books": issued_books,
                "reserved_books": reserved_books,
                "total_students": len(students),
                "total_librarians": len(librarians),
                "active_loans": active_loans,
                "returned_loans": returned_loans,
                "overdue_loans": overdue_loans
            }
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }

@app.get("/dashboard/summary")
def get_dashboard_summary():
    try:
        today = datetime.now().date()

        loans_response = (
            supabase
            .table("loans")
            .select(
                """
                id,
                issue_date,
                due_date,
                return_date,
                status,
                students (
                    student_id,
                    name
                ),
                book_copies (
                    accession_number,
                    books (
                        title,
                        author
                    )
                )
                """
            )
            .order("issue_date", desc=True)
            .execute()
        )

        loans = loans_response.data or []

        issued_today = 0
        returned_today = 0
        due_today = 0

        for loan in loans:
            if loan.get("issue_date"):
                issue_date = parse_supabase_datetime(
                    loan["issue_date"]
                )

                if issue_date and issue_date.date() == today:
                    issued_today += 1

            if loan.get("return_date"):
                return_date = parse_supabase_datetime(
                    loan["return_date"]
                )

                if return_date and return_date.date() == today:
                    returned_today += 1

            if (
                loan.get("due_date")
                and loan.get("status") == "issued"
            ):
                due_date = parse_supabase_datetime(
                    loan["due_date"]
                )

                if due_date and due_date.date() == today:
                    due_today += 1

        recent_loan = loans[0] if loans else None

        return {
            "success": True,
            "dashboard": {
                "issued_today": issued_today,
                "returned_today": returned_today,
                "due_today": due_today,
                "recent_loan": recent_loan
            }
        }

    except Exception as error:
        return {
            "success": False,
            "message": str(error)
        }
