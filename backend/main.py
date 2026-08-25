from datetime import datetime, timedelta

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from database import supabase


app = FastAPI(
    title="ReadSpace API",
    version="1.0.0"
)


# =========================================================
# CORS
# Allows React dashboard to communicate with FastAPI
# =========================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
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
