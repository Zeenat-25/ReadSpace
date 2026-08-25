import { useEffect, useMemo, useState } from "react";
import "./App.css";

function App() {
  // =====================================================
  // STATES
  // =====================================================

  const [books, setBooks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [students, setStudents] = useState([]);
  const [studentsLoading, setStudentsLoading] = useState(false);
  const [studentsError, setStudentsError] = useState("");

  const [librarians, setLibrarians] = useState([]);
  const [librariansLoading, setLibrariansLoading] = useState(false);
  const [librariansError, setLibrariansError] = useState("");

  const [activePage, setActivePage] = useState("dashboard");

  const [searchTerm, setSearchTerm] = useState("");
  const [studentSearch, setStudentSearch] = useState("");
  const [librarianSearch, setLibrarianSearch] = useState("");

  const [activeLoans, setActiveLoans] = useState([]);
const [loansLoading, setLoansLoading] = useState(false);
const [loansError, setLoansError] = useState("");
const [loanSearch, setLoanSearch] = useState("");

const [overdueLoans, setOverdueLoans] = useState([]);
const [overdueLoading, setOverdueLoading] = useState(false);
const [overdueError, setOverdueError] = useState("");
const [overdueSearch, setOverdueSearch] = useState("");

const [notifications, setNotifications] = useState([]);
const [notificationsLoading, setNotificationsLoading] = useState(false);
const [notificationsError, setNotificationsError] = useState("");
const [notificationSearch, setNotificationSearch] = useState("");

const [reportData, setReportData] = useState(null);
const [reportLoading, setReportLoading] = useState(false);
const [reportError, setReportError] = useState("");

const [dashboardSummary, setDashboardSummary] = useState(null);
const [dashboardLoading, setDashboardLoading] = useState(false);
const [dashboardError, setDashboardError] = useState("");

const [showAddLibrarian, setShowAddLibrarian] = useState(false);
const [addLibrarianMessage, setAddLibrarianMessage] = useState("");

const [newLibrarian, setNewLibrarian] = useState({
  employee_id: "",
  name: "",
  email: "",
  role: "librarian",
});

  const [showAddBook, setShowAddBook] = useState(false);
  const [addBookMessage, setAddBookMessage] = useState("");

  const [showAddStudent, setShowAddStudent] = useState(false);
  const [addStudentMessage, setAddStudentMessage] = useState("");

  const [newBook, setNewBook] = useState({
    title: "",
    author: "",
    isbn: "",
    publisher: "",
    edition: "",
    category: "",
    accession_number: "",
    barcode: "",
  });

  const [newStudent, setNewStudent] = useState({
    student_id: "",
    name: "",
    email: "",
    phone: "",
    course: "",
    year: "",
    division: "",
  });

  // =====================================================
  // LOAD BOOKS
  // =====================================================

  async function loadBooks() {
    try {
      setLoading(true);

      const response = await fetch(
        "http://127.0.0.1:8000/books/status"
      );

      if (!response.ok) {
        throw new Error("Could not load books");
      }

      const data = await response.json();

      if (!Array.isArray(data)) {
        throw new Error(
          data?.message || "Invalid books response"
        );
      }

      setBooks(data);
      setError("");
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  // =====================================================
  // INITIAL BOOK LOAD
  // =====================================================

  useEffect(() => {
    let ignore = false;

    async function fetchBooks() {
      try {
        const response = await fetch(
          "http://127.0.0.1:8000/books/status"
        );

        if (!response.ok) {
          throw new Error("Could not load books");
        }

        const data = await response.json();

        if (!ignore) {
          if (!Array.isArray(data)) {
            throw new Error(
              data?.message || "Invalid books response"
            );
          }

          setBooks(data);
          setError("");
          setLoading(false);

          const dashboardResponse = await fetch(
  "http://127.0.0.1:8000/dashboard/summary"
);

const dashboardData =
  await dashboardResponse.json();

if (
  !ignore &&
  dashboardData.success
) {
  setDashboardSummary(
    dashboardData.dashboard
  );
}
        }
      } catch (err) {
        if (!ignore) {
          setError(err.message);
          setLoading(false);
        }
      }
    }

    fetchBooks();

    return () => {
      ignore = true;
    };
  }, []);

  // =====================================================
  // LOAD STUDENTS
  // =====================================================

  async function loadStudents() {
    try {
      setStudentsLoading(true);

      const response = await fetch(
        "http://127.0.0.1:8000/students"
      );

      if (!response.ok) {
        throw new Error("Could not load students");
      }

      const data = await response.json();

      if (!data.success) {
        throw new Error(
          data.message || "Could not load students"
        );
      }

      setStudents(data.students || []);
      setStudentsError("");
    } catch (err) {
      setStudentsError(err.message);
    } finally {
      setStudentsLoading(false);
    }
  }

  // =====================================================
  // LOAD LIBRARIANS
  // =====================================================

  async function loadLibrarians() {
    try {
      setLibrariansLoading(true);

      const response = await fetch(
        "http://127.0.0.1:8000/librarians"
      );

      if (!response.ok) {
        throw new Error("Could not load librarians");
      }

      const data = await response.json();

      if (!data.success) {
        throw new Error(
          data.message || "Could not load librarians"
        );
      }

      setLibrarians(data.librarians || []);
      setLibrariansError("");
    } catch (err) {
      setLibrariansError(err.message);
    } finally {
      setLibrariansLoading(false);
    }
  }

  // =====================================================
  // COUNTS
  // =====================================================

  const totalCopies = books.length;

  const availableCount = useMemo(() => {
    return books.filter(
      (book) => book.status === "available"
    ).length;
  }, [books]);

  const issuedCount = useMemo(() => {
    return books.filter(
      (book) => book.status === "issued"
    ).length;
  }, [books]);

  const reservedCount = useMemo(() => {
    return books.filter(
      (book) => book.status === "reserved"
    ).length;
  }, [books]);

  // =====================================================
  // BOOK SEARCH
  // =====================================================

  const filteredBooks = useMemo(() => {
    const term = searchTerm.trim().toLowerCase();

    if (!term) {
      return books;
    }

    return books.filter((book) => {
      const title =
        book.books?.title?.toLowerCase() || "";

      const author =
        book.books?.author?.toLowerCase() || "";

      const category =
        book.books?.category?.toLowerCase() || "";

      const accession =
        book.accession_number?.toLowerCase() || "";

      const barcode =
        book.barcode?.toLowerCase() || "";

      const status =
        book.status?.toLowerCase() || "";

      return (
        title.includes(term) ||
        author.includes(term) ||
        category.includes(term) ||
        accession.includes(term) ||
        barcode.includes(term) ||
        status.includes(term)
      );
    });
  }, [books, searchTerm]);

  // =====================================================
  // STUDENT SEARCH
  // =====================================================

  const filteredStudents = useMemo(() => {
    const term = studentSearch.trim().toLowerCase();

    if (!term) {
      return students;
    }

    return students.filter((student) => {
      const name =
        student.name?.toLowerCase() || "";

      const studentId =
        student.student_id?.toLowerCase() || "";

      const email =
        student.email?.toLowerCase() || "";

      const course =
        student.course?.toLowerCase() || "";

      const year =
        student.year?.toLowerCase() || "";

      const division =
        student.division?.toLowerCase() || "";

      return (
        name.includes(term) ||
        studentId.includes(term) ||
        email.includes(term) ||
        course.includes(term) ||
        year.includes(term) ||
        division.includes(term)
      );
    });
  }, [students, studentSearch]);

  // =====================================================
  // LIBRARIAN SEARCH
  // =====================================================

  const filteredLibrarians = useMemo(() => {
    const term = librarianSearch.trim().toLowerCase();

    if (!term) {
      return librarians;
    }

    return librarians.filter((librarian) => {
      const employeeId =
        librarian.employee_id?.toLowerCase() || "";

      const name =
        librarian.name?.toLowerCase() || "";

      const email =
        librarian.email?.toLowerCase() || "";

      const role =
        librarian.role?.toLowerCase() || "";

      return (
        employeeId.includes(term) ||
        name.includes(term) ||
        email.includes(term) ||
        role.includes(term)
      );
    });
  }, [librarians, librarianSearch]);

  // =====================================================
  // ISSUED BOOK SEARCH
  // =====================================================

  const filteredLoans = useMemo(() => {
    const term = loanSearch.trim().toLowerCase();
  
    if (!term) {
      return activeLoans;
    }
  
    return activeLoans.filter((loan) => {
      const studentName =
        loan.students?.name?.toLowerCase() || "";
  
      const studentId =
        loan.students?.student_id?.toLowerCase() || "";
  
      const bookTitle =
        loan.book_copies?.books?.title?.toLowerCase() || "";
  
      const accession =
        loan.book_copies?.accession_number?.toLowerCase() || "";
  
      const librarian =
        loan.librarians?.name?.toLowerCase() || "";
  
      return (
        studentName.includes(term) ||
        studentId.includes(term) ||
        bookTitle.includes(term) ||
        accession.includes(term) ||
        librarian.includes(term)
      );
    });
  }, [activeLoans, loanSearch]);

  const filteredOverdueLoans = useMemo(() => {
  const term = overdueSearch.trim().toLowerCase();

  if (!term) {
    return overdueLoans;
  }

  return overdueLoans.filter((loan) => {
    const studentName =
      loan.students?.name?.toLowerCase() || "";

    const studentId =
      loan.students?.student_id?.toLowerCase() || "";

    const bookTitle =
      loan.book_copies?.books?.title?.toLowerCase() || "";

    const accession =
      loan.book_copies?.accession_number?.toLowerCase() || "";

    return (
      studentName.includes(term) ||
      studentId.includes(term) ||
      bookTitle.includes(term) ||
      accession.includes(term)
    );
  });
}, [overdueLoans, overdueSearch]);

const filteredNotifications = useMemo(() => {
  const term = notificationSearch
    .trim()
    .toLowerCase();

  if (!term) {
    return notifications;
  }

  return notifications.filter((notification) => {
    const title =
      notification.title?.toLowerCase() || "";

    const message =
      notification.message?.toLowerCase() || "";

    const type =
      notification.notification_type?.toLowerCase() || "";

    const studentName =
      notification.students?.name?.toLowerCase() || "";

    const studentId =
      notification.students?.student_id?.toLowerCase() || "";

    return (
      title.includes(term) ||
      message.includes(term) ||
      type.includes(term) ||
      studentName.includes(term) ||
      studentId.includes(term)
    );
  });
}, [notifications, notificationSearch]);


  // =====================================================
  // OPEN ADD BOOK
  // =====================================================

  function openAddBook() {
    setActivePage("books");
    setShowAddBook(true);
    setAddBookMessage("");
  }

  // =====================================================
  // ADD BOOK
  // =====================================================

  async function handleAddBook(event) {
    event.preventDefault();

    try {
      setAddBookMessage("Adding book...");

      const response = await fetch(
        "http://127.0.0.1:8000/add-book",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(newBook),
        }
      );

      const data = await response.json();

      if (!data.success) {
        setAddBookMessage(
          data.message || "Could not add book"
        );
        return;
      }

      setAddBookMessage("Book added successfully");

      setNewBook({
        title: "",
        author: "",
        isbn: "",
        publisher: "",
        edition: "",
        category: "",
        accession_number: "",
        barcode: "",
      });

      await loadBooks();

      setTimeout(() => {
        setShowAddBook(false);
        setAddBookMessage("");
      }, 900);
    } catch {
      setAddBookMessage("Could not add book");
    }
  }

  // =====================================================
  // ADD STUDENT
  // =====================================================

  async function handleAddStudent(event) {
    event.preventDefault();

    try {
      setAddStudentMessage("Adding student...");

      const response = await fetch(
        "http://127.0.0.1:8000/add-student",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(newStudent),
        }
      );

      const data = await response.json();

      if (!data.success) {
        setAddStudentMessage(
          data.message || "Could not add student"
        );
        return;
      }

      setAddStudentMessage("Student added successfully");

      setNewStudent({
        student_id: "",
        name: "",
        email: "",
        phone: "",
        course: "",
        year: "",
        division: "",
      });

      await loadStudents();

      setTimeout(() => {
        setShowAddStudent(false);
        setAddStudentMessage("");
      }, 900);
    } catch {
      setAddStudentMessage("Could not add student");
    }
  }
  async function handleAddLibrarian(event) {
  event.preventDefault();

  try {
    setAddLibrarianMessage("Adding librarian...");

    const response = await fetch(
      "http://127.0.0.1:8000/add-librarian",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(newLibrarian),
      }
    );

    const data = await response.json();

    if (!data.success) {
      setAddLibrarianMessage(
        data.message || "Could not add librarian"
      );
      return;
    }

    setAddLibrarianMessage(
      "Librarian added successfully"
    );

    setNewLibrarian({
      employee_id: "",
      name: "",
      email: "",
      role: "librarian",
    });

    await loadLibrarians();

    setTimeout(() => {
      setShowAddLibrarian(false);
      setAddLibrarianMessage("");
    }, 900);

  } catch {
    setAddLibrarianMessage(
      "Could not add librarian"
    );
  }
}

async function loadActiveLoans() {
  try {
    setLoansLoading(true);

    const response = await fetch(
      "http://127.0.0.1:8000/loans/active"
    );

    if (!response.ok) {
      throw new Error("Could not load active loans");
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(
        data.message || "Could not load active loans"
      );
    }

    setActiveLoans(data.loans || []);
    setLoansError("");
  } catch (err) {
    setLoansError(err.message);
  } finally {
    setLoansLoading(false);
  }
}
async function loadOverdueLoans() {
  try {
    setOverdueLoading(true);

    const response = await fetch(
      "http://127.0.0.1:8000/loans/overdue"
    );

    if (!response.ok) {
      throw new Error("Could not load overdue loans");
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(
        data.message || "Could not load overdue loans"
      );
    }

    setOverdueLoans(data.overdue_loans || []);
    setOverdueError("");
  } catch (err) {
    setOverdueError(err.message);
  } finally {
    setOverdueLoading(false);
  }
}

async function loadNotifications() {
  try {
    setNotificationsLoading(true);

    const response = await fetch(
      "http://127.0.0.1:8000/notifications"
    );

    if (!response.ok) {
      throw new Error("Could not load notifications");
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(
        data.message || "Could not load notifications"
      );
    }

    setNotifications(data.notifications || []);
    setNotificationsError("");
  } catch (err) {
    setNotificationsError(err.message);
  } finally {
    setNotificationsLoading(false);
  }
}

async function loadReport() {
  try {
    setReportLoading(true);

    const response = await fetch(
      "http://127.0.0.1:8000/reports/summary"
    );

    if (!response.ok) {
      throw new Error("Could not load report");
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(
        data.message || "Could not load report"
      );
    }

    setReportData(data.report);
    setReportError("");
  } catch (err) {
    setReportError(err.message);
  } finally {
    setReportLoading(false);
  }
}

async function loadDashboardSummary() {
  try {
    setDashboardLoading(true);

    const response = await fetch(
      "http://127.0.0.1:8000/dashboard/summary"
    );

    if (!response.ok) {
      throw new Error("Could not load dashboard summary");
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(
        data.message || "Could not load dashboard summary"
      );
    }

    setDashboardSummary(data.dashboard);
    setDashboardError("");
  } catch (err) {
    setDashboardError(err.message);
  } finally {
    setDashboardLoading(false);
  }
}

  // =====================================================
  // JSX
  // =====================================================

  return (
    <div className="app">
      {/* ================= SIDEBAR ================= */}

      <aside className="sidebar">
        <div className="brand">
          <div className="brand-icon">R</div>

          <div>
            <h1>ReadSpace</h1>
            <p>Library Dashboard</p>
          </div>
        </div>

        <nav className="navigation">
          <button
            className={`nav-item ${
              activePage === "dashboard" ? "active" : ""
            }`}
            onClick={() => {
  setActivePage("dashboard");
  setSearchTerm("");
  setStudentSearch("");
  setLibrarianSearch("");
  setShowAddBook(false);
  setShowAddStudent(false);

  loadDashboardSummary();
}}
          >
            Dashboard
          </button>

          <button
            className={`nav-item ${
              activePage === "books" ? "active" : ""
            }`}
            onClick={() => {
              setActivePage("books");
              setSearchTerm("");
              setShowAddBook(false);
              setShowAddStudent(false);
            }}
          >
            Books
          </button>

          <button
            className={`nav-item ${
              activePage === "students" ? "active" : ""
            }`}
            onClick={() => {
              setActivePage("students");
              setStudentSearch("");
              setShowAddBook(false);

              if (students.length === 0) {
                loadStudents();
              }
            }}
          >
            Students
          </button>

          <button
            className={`nav-item ${
              activePage === "librarians" ? "active" : ""
            }`}
            onClick={() => {
              setActivePage("librarians");
              setLibrarianSearch("");
              setShowAddBook(false);
              setShowAddStudent(false);

              if (librarians.length === 0) {
                loadLibrarians();
              }
            }}
          >
            Librarians
          </button>

          <button
  className={`nav-item ${
    activePage === "issued"
      ? "active"
      : ""
  }`}
  onClick={() => {
    setActivePage("issued");
    setLoanSearch("");

    if (activeLoans.length === 0) {
      loadActiveLoans();
    }
  }}
>
  Issued Books
</button>

          <button
  className={`nav-item ${
    activePage === "overdue"
      ? "active"
      : ""
  }`}
  onClick={() => {
    setActivePage("overdue");
    setOverdueSearch("");

    if (overdueLoans.length === 0) {
      loadOverdueLoans();
    }
  }}
>
  Overdue
</button>

          <button
  className={`nav-item ${
    activePage === "notifications"
      ? "active"
      : ""
  }`}
  onClick={() => {
    setActivePage("notifications");
    setNotificationSearch("");

    if (notifications.length === 0) {
      loadNotifications();
    }
  }}
>
  Notifications
</button>

          <button
  className={`nav-item ${
    activePage === "reports"
      ? "active"
      : ""
  }`}
  onClick={() => {
    setActivePage("reports");

    if (!reportData) {
      loadReport();
    }
  }}
>
  Reports
</button>
        </nav>

        <div className="sidebar-bottom">
          <button className="nav-item">
            Settings
          </button>

          <div className="admin-profile">
            <div className="avatar">A</div>

            <div>
              <strong>Library Admin</strong>
              <span>Administrator</span>
            </div>
          </div>
        </div>
      </aside>

      {/* ================= MAIN ================= */}

      <main className="main-content">
        {/* =================================================
            DASHBOARD PAGE
        ================================================= */}

        {activePage === "dashboard" && (
          <>
            <header className="topbar">
              <div>
                <p className="welcome">WELCOME BACK</p>
                <h2>Library Overview</h2>
              </div>

              <div className="top-actions">
                <button
  className="notification-button"
  onClick={() => {
    setActivePage("notifications");
    setNotificationSearch("");
    loadNotifications();
  }}
>
  Notifications
</button>

                <button
                  className="primary-button"
                  onClick={openAddBook}
                >
                  + Add Book
                </button>
              </div>
            </header>

            <section className="stats-grid">
              <div className="stat-card">
                <span>Total Copies</span>
                <strong>{loading ? "..." : totalCopies}</strong>
                <p>Across the library</p>
              </div>

              <div className="stat-card blue">
                <span>Available</span>
                <strong>{loading ? "..." : availableCount}</strong>
                <p>Ready to issue</p>
              </div>

              <div className="stat-card">
                <span>Issued</span>
                <strong>{loading ? "..." : issuedCount}</strong>
                <p>Currently borrowed</p>
              </div>

              <div className="stat-card">
                <span>Reserved</span>
                <strong>{loading ? "..." : reservedCount}</strong>
                <p>Currently reserved</p>
              </div>
            </section>

            <section className="dashboard-grid">
              <div className="panel">
                <div className="panel-header">
                  <div>
                    <p className="section-label">
                      LIBRARY ACTIVITY
                    </p>

                    <h3>Recently Issued</h3>
                  </div>

                  <button
  className="text-button"
  onClick={() => {
    setActivePage("issued");
    setLoanSearch("");
    loadActiveLoans();
  }}
>
  View all
</button>
                </div>

                {dashboardLoading && (
  <div className="book-row">
    Loading latest activity...
  </div>
)}

{dashboardError && (
  <div className="book-row">
    {dashboardError}
  </div>
)}

{!dashboardLoading &&
  !dashboardError &&
  dashboardSummary?.recent_loan && (
    <div className="book-row">
      <div className="book-icon">
        {dashboardSummary.recent_loan
          .book_copies?.books?.title?.charAt(0) || "B"}
      </div>

      <div className="book-info">
        <strong>
          {dashboardSummary.recent_loan
            .book_copies?.books?.title ||
            "Unknown Book"}
        </strong>

        <span>
          {dashboardSummary.recent_loan
            .book_copies?.accession_number ||
            "-"}
        </span>
      </div>

      <div className="student-info">
        <span>Issued to</span>

        <strong>
          {dashboardSummary.recent_loan
            .students?.name ||
            "Unknown Student"}
        </strong>
      </div>

      <span className="status issued">
        Issued
      </span>
    </div>
  )}

{!dashboardLoading &&
  !dashboardError &&
  !dashboardSummary?.recent_loan && (
    <div className="book-row">
      No recent loan activity.
    </div>
  )}
              </div>

              <div className="panel quick-panel">
                <p className="section-label">
                  QUICK OVERVIEW
                </p>

                <h3>Today's Library</h3>

                <div className="quick-row">
  <span>Issued today</span>

  <strong>
    {dashboardSummary?.issued_today ?? 0}
  </strong>
</div>

<div className="quick-row">
  <span>Returned today</span>

  <strong>
    {dashboardSummary?.returned_today ?? 0}
  </strong>
</div>

<div className="quick-row">
  <span>Due today</span>

  <strong>
    {dashboardSummary?.due_today ?? 0}
  </strong>
</div>

<div className="quick-row">
  <span>Reserved</span>

  <strong>
    {reservedCount}
  </strong>
</div>
              </div>
            </section>

            <section className="panel books-panel">
              <div className="panel-header">
                <div>
                  <p className="section-label">
                    COLLECTION
                  </p>

                  <h3>Books</h3>
                </div>

                <button
                  className="filter-button"
                  onClick={() => {
                    setActivePage("books");
                    setSearchTerm("");
                  }}
                >
                  View All
                </button>
              </div>

              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Book</th>
                      <th>Category</th>
                      <th>Accession</th>
                      <th>Status</th>
                    </tr>
                  </thead>

                  <tbody>
                    {loading && (
                      <tr>
                        <td colSpan="4">
                          Loading books...
                        </td>
                      </tr>
                    )}

                    {error && (
                      <tr>
                        <td colSpan="4">
                          {error}
                        </td>
                      </tr>
                    )}

                    {!loading &&
                      !error &&
                      books.map((book) => (
                        <tr key={book.accession_number}>
                          <td>
                            <strong>
                              {book.books?.title ||
                                "Unknown Book"}
                            </strong>

                            <span>
                              {book.books?.author ||
                                "Unknown Author"}
                            </span>
                          </td>

                          <td>
                            {book.books?.category || "-"}
                          </td>

                          <td>
                            {book.accession_number}
                          </td>

                          <td>
                            <span
                              className={`status ${book.status}`}
                            >
                              {book.status}
                            </span>
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            </section>
          </>
        )}

        {/* =================================================
            BOOKS PAGE
        ================================================= */}

        {activePage === "books" && (
          <>
            <header className="topbar">
              <div>
                <p className="welcome">COLLECTION</p>
                <h2>Books Management</h2>
              </div>

              <div className="top-actions">
                <button
                  className="primary-button"
                  onClick={() => {
                    setShowAddBook(!showAddBook);
                    setAddBookMessage("");
                  }}
                >
                  {showAddBook ? "Close Form" : "+ Add Book"}
                </button>
              </div>
            </header>

            {showAddBook && (
              <section className="panel book-form-panel">
                <div className="book-form-header">
                  <div>
                    <p className="section-label">NEW BOOK</p>
                    <h3>Add Book to Library</h3>

                    <p className="form-subtitle">
                      Add book details and register a physical copy in ReadSpace.
                    </p>
                  </div>

                  <button
                    type="button"
                    className="text-button"
                    onClick={() => {
                      setShowAddBook(false);
                      setAddBookMessage("");
                    }}
                  >
                    Close
                  </button>
                </div>

                <form
                  className="book-form"
                  onSubmit={handleAddBook}
                >
                  <div className="form-group-block">
                    <div className="form-group-title">
                      Book Details
                    </div>

                    <div className="book-form-grid">
                      <div className="form-field">
                        <label>Book Title</label>

                        <input
                          type="text"
                          placeholder="e.g. Computer Networks"
                          value={newBook.title}
                          onChange={(e) =>
                            setNewBook({
                              ...newBook,
                              title: e.target.value,
                            })
                          }
                          required
                        />
                      </div>

                      <div className="form-field">
                        <label>Author</label>

                        <input
                          type="text"
                          placeholder="Author name"
                          value={newBook.author}
                          onChange={(e) =>
                            setNewBook({
                              ...newBook,
                              author: e.target.value,
                            })
                          }
                          required
                        />
                      </div>
                    </div>
                  </div>

                  <div className="form-group-block">
                    <div className="form-group-title">
                      Publication Details
                    </div>

                    <div className="book-form-grid">
                      <div className="form-field">
                        <label>ISBN</label>

                        <input
                          type="text"
                          placeholder="ISBN number"
                          value={newBook.isbn}
                          onChange={(e) =>
                            setNewBook({
                              ...newBook,
                              isbn: e.target.value,
                            })
                          }
                          required
                        />
                      </div>

                      <div className="form-field">
                        <label>Publisher</label>

                        <input
                          type="text"
                          placeholder="Publisher name"
                          value={newBook.publisher}
                          onChange={(e) =>
                            setNewBook({
                              ...newBook,
                              publisher: e.target.value,
                            })
                          }
                        />
                      </div>

                      <div className="form-field">
                        <label>Edition</label>

                        <input
                          type="text"
                          placeholder="e.g. 2nd Edition"
                          value={newBook.edition}
                          onChange={(e) =>
                            setNewBook({
                              ...newBook,
                              edition: e.target.value,
                            })
                          }
                        />
                      </div>

                      <div className="form-field">
                        <label>Category</label>

                        <input
                          type="text"
                          placeholder="e.g. Networking"
                          value={newBook.category}
                          onChange={(e) =>
                            setNewBook({
                              ...newBook,
                              category: e.target.value,
                            })
                          }
                        />
                      </div>
                    </div>
                  </div>

                  <div className="form-group-block">
                    <div className="form-group-title">
                      Physical Copy Details
                    </div>

                    <div className="book-form-grid">
                      <div className="form-field">
                        <label>Accession Number</label>

                        <input
                          type="text"
                          placeholder="e.g. ACC008"
                          value={newBook.accession_number}
                          onChange={(e) =>
                            setNewBook({
                              ...newBook,
                              accession_number: e.target.value,
                            })
                          }
                          required
                        />
                      </div>

                      <div className="form-field">
                        <label>Barcode</label>

                        <input
                          type="text"
                          placeholder="e.g. CN002"
                          value={newBook.barcode}
                          onChange={(e) =>
                            setNewBook({
                              ...newBook,
                              barcode: e.target.value,
                            })
                          }
                        />
                      </div>
                    </div>
                  </div>

                  <div className="book-form-actions">
                    <div>
                      {addBookMessage && (
                        <span className="form-message">
                          {addBookMessage}
                        </span>
                      )}
                    </div>

                    <div className="book-form-buttons">
                      <button
                        type="button"
                        className="filter-button"
                        onClick={() => {
                          setShowAddBook(false);
                          setAddBookMessage("");
                        }}
                      >
                        Cancel
                      </button>

                      <button
                        type="submit"
                        className="primary-button"
                      >
                        Add Book
                      </button>
                    </div>
                  </div>
                </form>
              </section>
            )}

            <section className="panel books-panel">
              <div className="panel-header">
                <div>
                  <p className="section-label">
                    ALL BOOK COPIES
                  </p>

                  <h3>Library Collection</h3>
                </div>

                <div className="book-actions">
                  <input
                    type="text"
                    placeholder="Search title, author, accession..."
                    value={searchTerm}
                    onChange={(e) =>
                      setSearchTerm(e.target.value)
                    }
                  />
                </div>
              </div>

              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Book</th>
                      <th>Category</th>
                      <th>Accession</th>
                      <th>Barcode</th>
                      <th>Status</th>
                    </tr>
                  </thead>

                  <tbody>
                    {loading && (
                      <tr>
                        <td colSpan="5">
                          Loading books...
                        </td>
                      </tr>
                    )}

                    {error && (
                      <tr>
                        <td colSpan="5">
                          {error}
                        </td>
                      </tr>
                    )}

                    {!loading &&
                      !error &&
                      filteredBooks.map((book) => (
                        <tr key={book.accession_number}>
                          <td>
                            <strong>
                              {book.books?.title ||
                                "Unknown Book"}
                            </strong>

                            <span>
                              {book.books?.author ||
                                "Unknown Author"}
                            </span>
                          </td>

                          <td>
                            {book.books?.category || "-"}
                          </td>

                          <td>
                            {book.accession_number}
                          </td>

                          <td>
                            {book.barcode || "-"}
                          </td>

                          <td>
                            <span
                              className={`status ${book.status}`}
                            >
                              {book.status}
                            </span>
                          </td>
                        </tr>
                      ))}

                    {!loading &&
                      !error &&
                      filteredBooks.length === 0 && (
                        <tr>
                          <td colSpan="5">
                            No matching books found.
                          </td>
                        </tr>
                      )}
                  </tbody>
                </table>
              </div>
            </section>
          </>
        )}

        {/* =================================================
            STUDENTS PAGE
        ================================================= */}

        {activePage === "students" && (
          <>
            <header className="topbar">
              <div>
                <p className="welcome">
                  STUDENT DIRECTORY
                </p>

                <h2>Students</h2>
              </div>

              <div className="top-actions">
                <button
                  className="primary-button"
                  type="button"
                  onClick={() => {
                    setShowAddStudent(!showAddStudent);
                    setAddStudentMessage("");
                  }}
                >
                  {showAddStudent
                    ? "Close Form"
                    : "+ Add Student"}
                </button>
              </div>
            </header>

            {showAddStudent && (
              <section className="panel student-form-panel">
                <div className="student-form-header">
                  <div>
                    <p className="section-label">
                      NEW STUDENT
                    </p>

                    <h3>Register Student</h3>

                    <p className="form-subtitle">
                      Add a new student to the ReadSpace directory.
                    </p>
                  </div>

                  <button
                    type="button"
                    className="text-button"
                    onClick={() => {
                      setShowAddStudent(false);
                      setAddStudentMessage("");
                    }}
                  >
                    Close
                  </button>
                </div>

                <form
                  className="student-form"
                  onSubmit={handleAddStudent}
                >
                  <div className="form-group-block">
                    <div className="form-group-title">
                      Student Identity
                    </div>

                    <div className="student-form-grid">
                      <div className="form-field">
                        <label>Student ID</label>

                        <input
                          type="text"
                          placeholder="e.g. BCA005"
                          value={newStudent.student_id}
                          onChange={(e) =>
                            setNewStudent({
                              ...newStudent,
                              student_id: e.target.value,
                            })
                          }
                          required
                        />
                      </div>

                      <div className="form-field">
                        <label>Full Name</label>

                        <input
                          type="text"
                          placeholder="Enter full name"
                          value={newStudent.name}
                          onChange={(e) =>
                            setNewStudent({
                              ...newStudent,
                              name: e.target.value,
                            })
                          }
                          required
                        />
                      </div>
                    </div>
                  </div>

                  <div className="form-group-block">
                    <div className="form-group-title">
                      Contact Details
                    </div>

                    <div className="student-form-grid">
                      <div className="form-field">
                        <label>Email</label>

                        <input
                          type="email"
                          placeholder="student@email.com"
                          value={newStudent.email}
                          onChange={(e) =>
                            setNewStudent({
                              ...newStudent,
                              email: e.target.value,
                            })
                          }
                          required
                        />
                      </div>

                      <div className="form-field">
                        <label>Phone</label>

                        <input
                          type="text"
                          placeholder="Phone number"
                          value={newStudent.phone}
                          onChange={(e) =>
                            setNewStudent({
                              ...newStudent,
                              phone: e.target.value,
                            })
                          }
                          required
                        />
                      </div>
                    </div>
                  </div>

                  <div className="form-group-block">
                    <div className="form-group-title">
                      Academic Details
                    </div>

                    <div className="student-form-grid academic-grid">
                      <div className="form-field">
                        <label>Course</label>

                        <input
                          type="text"
                          placeholder="e.g. BCA"
                          value={newStudent.course}
                          onChange={(e) =>
                            setNewStudent({
                              ...newStudent,
                              course: e.target.value,
                            })
                          }
                          required
                        />
                      </div>

                      <div className="form-field">
                        <label>Year</label>

                        <select
                          value={newStudent.year}
                          onChange={(e) =>
                            setNewStudent({
                              ...newStudent,
                              year: e.target.value,
                            })
                          }
                          required
                        >
                          <option value="">
                            Select Year
                          </option>
                          <option value="FY">FY</option>
                          <option value="SY">SY</option>
                          <option value="TY">TY</option>
                        </select>
                      </div>

                      <div className="form-field">
                        <label>Division</label>

                        <input
                          type="text"
                          placeholder="e.g. A"
                          value={newStudent.division}
                          onChange={(e) =>
                            setNewStudent({
                              ...newStudent,
                              division: e.target.value,
                            })
                          }
                          required
                        />
                      </div>
                    </div>
                  </div>

                  <div className="student-form-actions">
                    <div>
                      {addStudentMessage && (
                        <span className="form-message">
                          {addStudentMessage}
                        </span>
                      )}
                    </div>

                    <div className="student-form-buttons">
                      <button
                        type="button"
                        className="filter-button"
                        onClick={() => {
                          setShowAddStudent(false);
                          setAddStudentMessage("");
                        }}
                      >
                        Cancel
                      </button>

                      <button
                        type="submit"
                        className="primary-button"
                      >
                        Add Student
                      </button>
                    </div>
                  </div>
                </form>
              </section>
            )}

            <section className="stats-grid">
              <div className="stat-card blue">
                <span>Total Students</span>

                <strong>
                  {studentsLoading
                    ? "..."
                    : students.length}
                </strong>

                <p>Registered students</p>
              </div>

              <div className="stat-card">
                <span>BCA Students</span>

                <strong>
                  {
                    students.filter(
                      (student) =>
                        student.course === "BCA"
                    ).length
                  }
                </strong>

                <p>Currently registered</p>
              </div>

              <div className="stat-card">
                <span>TY Students</span>

                <strong>
                  {
                    students.filter(
                      (student) =>
                        student.year === "TY"
                    ).length
                  }
                </strong>

                <p>Third year students</p>
              </div>

              <div className="stat-card">
                <span>Student Records</span>
                <strong>{students.length}</strong>
                <p>Available in ReadSpace</p>
              </div>
            </section>

            <section className="panel books-panel">
              <div className="panel-header">
                <div>
                  <p className="section-label">
                    STUDENTS
                  </p>

                  <h3>Student Directory</h3>
                </div>

                <div className="book-actions">
                  <input
                    type="text"
                    placeholder="Search student name, ID, course..."
                    value={studentSearch}
                    onChange={(e) =>
                      setStudentSearch(e.target.value)
                    }
                  />
                </div>
              </div>

              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Student</th>
                      <th>Student ID</th>
                      <th>Course</th>
                      <th>Year</th>
                      <th>Division</th>
                      <th>Phone</th>
                    </tr>
                  </thead>

                  <tbody>
                    {studentsLoading && (
                      <tr>
                        <td colSpan="6">
                          Loading students...
                        </td>
                      </tr>
                    )}

                    {studentsError && (
                      <tr>
                        <td colSpan="6">
                          {studentsError}
                        </td>
                      </tr>
                    )}

                    {!studentsLoading &&
                      !studentsError &&
                      filteredStudents.map((student) => (
                        <tr key={student.id}>
                          <td>
                            <strong>{student.name}</strong>

                            <span>
                              {student.email || "-"}
                            </span>
                          </td>

                          <td>{student.student_id}</td>
                          <td>{student.course || "-"}</td>
                          <td>{student.year || "-"}</td>
                          <td>{student.division || "-"}</td>
                          <td>{student.phone || "-"}</td>
                        </tr>
                      ))}

                    {!studentsLoading &&
                      !studentsError &&
                      filteredStudents.length === 0 && (
                        <tr>
                          <td colSpan="6">
                            No matching students found.
                          </td>
                        </tr>
                      )}
                  </tbody>
                </table>
              </div>
            </section>
          </>
        )}

        {/* =================================================
            LIBRARIANS PAGE
        ================================================= */}

        {activePage === "librarians" && (
          <>
            <header className="topbar">
              <div>
                <p className="welcome">
                  STAFF DIRECTORY
                </p>

                <h2>Librarians</h2>
              </div>

              <div className="top-actions">
                <button
  className="primary-button"
  type="button"
  onClick={() => {
    setShowAddLibrarian(!showAddLibrarian);
    setAddLibrarianMessage("");
  }}
>
  {showAddLibrarian
    ? "Close Form"
    : "+ Add Librarian"}
</button>
              </div>
            </header>
            {showAddLibrarian && (
  <section className="panel librarian-form-panel">

    <div className="librarian-form-header">
      <div>
        <p className="section-label">
          NEW LIBRARIAN
        </p>

        <h3>Register Librarian</h3>

        <p className="form-subtitle">
          Create a staff account for the ReadSpace librarian app.
        </p>
      </div>

      <button
        type="button"
        className="text-button"
        onClick={() => {
          setShowAddLibrarian(false);
          setAddLibrarianMessage("");
        }}
      >
        Close
      </button>
    </div>

    <form
      className="librarian-form"
      onSubmit={handleAddLibrarian}
    >

      <div className="form-group-block">

        <div className="form-group-title">
          Staff Identity
        </div>

        <div className="librarian-form-grid">

          <div className="form-field">
            <label>Employee ID</label>

            <input
              type="text"
              placeholder="e.g. LIB003"
              value={newLibrarian.employee_id}
              onChange={(e) =>
                setNewLibrarian({
                  ...newLibrarian,
                  employee_id: e.target.value,
                })
              }
              required
            />
          </div>

          <div className="form-field">
            <label>Full Name</label>

            <input
              type="text"
              placeholder="Enter librarian name"
              value={newLibrarian.name}
              onChange={(e) =>
                setNewLibrarian({
                  ...newLibrarian,
                  name: e.target.value,
                })
              }
              required
            />
          </div>

        </div>
      </div>


      <div className="form-group-block">

        <div className="form-group-title">
          Account Details
        </div>

        <div className="librarian-form-grid">

          <div className="form-field">
            <label>Email</label>

            <input
              type="email"
              placeholder="staff@readspace.com"
              value={newLibrarian.email}
              onChange={(e) =>
                setNewLibrarian({
                  ...newLibrarian,
                  email: e.target.value,
                })
              }
              required
            />
          </div>

          <div className="form-field">
            <label>Role</label>

            <select
              value={newLibrarian.role}
              onChange={(e) =>
                setNewLibrarian({
                  ...newLibrarian,
                  role: e.target.value,
                })
              }
              required
            >
              <option value="librarian">
                Librarian
              </option>

              <option value="assistant">
                Assistant
              </option>

              <option value="worker">
                Library Worker
              </option>
            </select>
          </div>

        </div>
      </div>


      <div className="librarian-form-actions">

        <div>
          {addLibrarianMessage && (
            <span className="form-message">
              {addLibrarianMessage}
            </span>
          )}
        </div>

        <div className="librarian-form-buttons">

          <button
            type="button"
            className="filter-button"
            onClick={() => {
              setShowAddLibrarian(false);
              setAddLibrarianMessage("");
            }}
          >
            Cancel
          </button>

          <button
            type="submit"
            className="primary-button"
          >
            Add Librarian
          </button>

        </div>

      </div>

    </form>

  </section>
)}

            <section className="stats-grid">
              <div className="stat-card blue">
                <span>Total Librarians</span>

                <strong>
                  {librariansLoading
                    ? "..."
                    : librarians.length}
                </strong>

                <p>Registered staff</p>
              </div>

              <div className="stat-card">
                <span>Active Records</span>
                <strong>{librarians.length}</strong>
                <p>Available in ReadSpace</p>
              </div>

              <div className="stat-card">
                <span>Librarian Role</span>

                <strong>
                  {
                    librarians.filter(
                      (librarian) =>
                        librarian.role === "librarian"
                    ).length
                  }
                </strong>

                <p>Librarian accounts</p>
              </div>

              <div className="stat-card">
                <span>Staff Access</span>
                <strong>{librarians.length}</strong>
                <p>Can use Staff App</p>
              </div>
            </section>

            <section className="panel books-panel">
              <div className="panel-header">
                <div>
                  <p className="section-label">
                    STAFF
                  </p>

                  <h3>Librarian Directory</h3>
                </div>

                <div className="book-actions">
                  <input
                    type="text"
                    placeholder="Search name, employee ID, role..."
                    value={librarianSearch}
                    onChange={(e) =>
                      setLibrarianSearch(e.target.value)
                    }
                  />
                </div>
              </div>

              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Librarian</th>
                      <th>Employee ID</th>
                      <th>Email</th>
                      <th>Role</th>
                    </tr>
                  </thead>

                  <tbody>
                    {librariansLoading && (
                      <tr>
                        <td colSpan="4">
                          Loading librarians...
                        </td>
                      </tr>
                    )}

                    {librariansError && (
                      <tr>
                        <td colSpan="4">
                          {librariansError}
                        </td>
                      </tr>
                    )}

                    {!librariansLoading &&
                      !librariansError &&
                      filteredLibrarians.map((librarian) => (
                        <tr key={librarian.id}>
                          <td>
                            <strong>{librarian.name}</strong>
                            <span>Staff account</span>
                          </td>

                          <td>{librarian.employee_id}</td>

                          <td>
                            {librarian.email || "-"}
                          </td>

                          <td>
                            <span className="status available">
                              {librarian.role}
                            </span>
                          </td>
                        </tr>
                      ))}

                    {!librariansLoading &&
                      !librariansError &&
                      filteredLibrarians.length === 0 && (
                        <tr>
                          <td colSpan="4">
                            No matching librarians found.
                          </td>
                        </tr>
                      )}
</tbody>
                </table>
              </div>
            </section>
          </>
        )}
        {/* =================================================
    ISSUED BOOKS PAGE
================================================= */}

{activePage === "issued" && (
  <>
    <header className="topbar">
      <div>
        <p className="welcome">
          ACTIVE LOANS
        </p>

        <h2>Issued Books</h2>
      </div>
    </header>

    <section className="stats-grid">
      <div className="stat-card blue">
        <span>Active Loans</span>

        <strong>
          {loansLoading
            ? "..."
            : activeLoans.length}
        </strong>

        <p>Currently issued books</p>
      </div>

      <div className="stat-card">
        <span>Students Borrowing</span>

        <strong>
          {
            new Set(
              activeLoans.map(
                (loan) =>
                  loan.students?.student_id
              )
            ).size
          }
        </strong>

        <p>Students with active loans</p>
      </div>

      <div className="stat-card">
        <span>Issued Copies</span>

        <strong>
          {activeLoans.length}
        </strong>

        <p>Physical copies on loan</p>
      </div>

      <div className="stat-card">
        <span>Loan Status</span>

        <strong>
          {
            activeLoans.filter(
              (loan) =>
                loan.status === "issued"
            ).length
          }
        </strong>

        <p>Marked as issued</p>
      </div>
    </section>

    <section className="panel books-panel">
      <div className="panel-header">
        <div>
          <p className="section-label">
            ACTIVE LOANS
          </p>

          <h3>Currently Issued Books</h3>
        </div>

        <div className="book-actions">
          <input
            type="text"
            placeholder="Search student, book, accession..."
            value={loanSearch}
            onChange={(e) =>
              setLoanSearch(e.target.value)
            }
          />
        </div>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Book</th>
              <th>Student</th>
              <th>Accession</th>
              <th>Issued By</th>
              <th>Issue Date</th>
              <th>Due Date</th>
              <th>Status</th>
            </tr>
          </thead>

          <tbody>
            {loansLoading && (
              <tr>
                <td colSpan="7">
                  Loading issued books...
                </td>
              </tr>
            )}

            {loansError && (
              <tr>
                <td colSpan="7">
                  {loansError}
                </td>
              </tr>
            )}

            {!loansLoading &&
              !loansError &&
              filteredLoans.map((loan) => (
                <tr key={loan.id}>
                  <td>
                    <strong>
                      {loan.book_copies?.books?.title ||
                        "Unknown Book"}
                    </strong>

                    <span>
                      {loan.book_copies?.books?.author ||
                        "-"}
                    </span>
                  </td>

                  <td>
                    <strong>
                      {loan.students?.name ||
                        "Unknown Student"}
                    </strong>

                    <span>
                      {loan.students?.student_id ||
                        "-"}
                    </span>
                  </td>

                  <td>
                    {loan.book_copies
                      ?.accession_number || "-"}
                  </td>

                  <td>
                    {loan.librarians?.name || "-"}
                  </td>

                  <td>
                    {loan.issue_date
                      ? new Date(
                          loan.issue_date
                        ).toLocaleDateString()
                      : "-"}
                  </td>

                  <td>
                    {loan.due_date
                      ? new Date(
                          loan.due_date
                        ).toLocaleDateString()
                      : "-"}
                  </td>

                  <td>
                    <span className="status issued">
                      {loan.status}
                    </span>
                  </td>
                </tr>
              ))}

            {!loansLoading &&
              !loansError &&
              filteredLoans.length === 0 && (
                <tr>
                  <td colSpan="7">
                    No active loans found.
                  </td>
                </tr>
              )}
          </tbody>
        </table>
      </div>
    </section>
  </>
)}
{/* =================================================
    OVERDUE PAGE
================================================= */}

{activePage === "overdue" && (
  <>
    <header className="topbar">
      <div>
        <p className="welcome">
          OVERDUE LOANS
        </p>

        <h2>Overdue Books</h2>
      </div>
    </header>

    <section className="stats-grid">
      <div className="stat-card blue">
        <span>Overdue Books</span>

        <strong>
          {overdueLoading
            ? "..."
            : overdueLoans.length}
        </strong>

        <p>Past their due date</p>
      </div>

      <div className="stat-card">
        <span>Students Affected</span>

        <strong>
          {
            new Set(
              overdueLoans.map(
                (loan) =>
                  loan.students?.student_id
              )
            ).size
          }
        </strong>

        <p>Students with overdue books</p>
      </div>

      <div className="stat-card">
        <span>Fine Rule</span>

        <strong>₹5</strong>

        <p>Per late day</p>
      </div>

      <div className="stat-card">
        <span>Status</span>

        <strong>
          {overdueLoans.length}
        </strong>

        <p>Requires attention</p>
      </div>
    </section>

    <section className="panel books-panel">
      <div className="panel-header">
        <div>
          <p className="section-label">
            OVERDUE
          </p>

          <h3>Overdue Loans</h3>
        </div>

        <div className="book-actions">
          <input
            type="text"
            placeholder="Search student, book, accession..."
            value={overdueSearch}
            onChange={(e) =>
              setOverdueSearch(e.target.value)
            }
          />
        </div>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Book</th>
              <th>Student</th>
              <th>Accession</th>
              <th>Due Date</th>
              <th>Late Days</th>
              <th>Estimated Fine</th>
            </tr>
          </thead>

          <tbody>
            {overdueLoading && (
              <tr>
                <td colSpan="6">
                  Loading overdue loans...
                </td>
              </tr>
            )}

            {overdueError && (
              <tr>
                <td colSpan="6">
                  {overdueError}
                </td>
              </tr>
            )}

            {!overdueLoading &&
              !overdueError &&
              filteredOverdueLoans.map(
                (loan) => {
                  const dueDate =
                    new Date(loan.due_date);

                  const today =
                    new Date();

                  const difference =
                    today - dueDate;

                  const lateDays =
                    Math.max(
                      0,
                      Math.floor(
                        difference /
                          (1000 * 60 * 60 * 24)
                      )
                    );

                  const estimatedFine =
                    lateDays * 5;

                  return (
                    <tr key={loan.id}>
                      <td>
                        <strong>
                          {loan.book_copies?.books?.title ||
                            "Unknown Book"}
                        </strong>

                        <span>
                          {loan.book_copies?.books?.author ||
                            "-"}
                        </span>
                      </td>

                      <td>
                        <strong>
                          {loan.students?.name ||
                            "Unknown Student"}
                        </strong>

                        <span>
                          {loan.students?.student_id ||
                            "-"}
                        </span>
                      </td>

                      <td>
                        {loan.book_copies
                          ?.accession_number || "-"}
                      </td>

                      <td>
                        {loan.due_date
                          ? new Date(
                              loan.due_date
                            ).toLocaleDateString()
                          : "-"}
                      </td>

                      <td>
                        {lateDays}
                      </td>

                      <td>
                        ₹{estimatedFine}
                      </td>
                    </tr>
                  );
                }
              )}

            {!overdueLoading &&
              !overdueError &&
              filteredOverdueLoans.length ===
                0 && (
                <tr>
                  <td colSpan="6">
                    No overdue loans found.
                  </td>
                </tr>
              )}
          </tbody>
        </table>
      </div>
    </section>
  </>
)}

{/* =================================================
    NOTIFICATIONS PAGE
================================================= */}

{activePage === "notifications" && (
  <>
    <header className="topbar">
      <div>
        <p className="welcome">
          LIBRARY ALERTS
        </p>

        <h2>Notifications</h2>
      </div>
    </header>

    <section className="stats-grid">
      <div className="stat-card blue">
        <span>Total Notifications</span>

        <strong>
          {notificationsLoading
            ? "..."
            : notifications.length}
        </strong>

        <p>All library notifications</p>
      </div>

      <div className="stat-card">
        <span>Unread</span>

        <strong>
          {
            notifications.filter(
              (notification) =>
                !notification.is_read
            ).length
          }
        </strong>

        <p>Not yet read</p>
      </div>

      <div className="stat-card">
        <span>Book Issued</span>

        <strong>
          {
            notifications.filter(
              (notification) =>
                notification.notification_type ===
                "book_issued"
            ).length
          }
        </strong>

        <p>Issue notifications</p>
      </div>

      <div className="stat-card">
        <span>Book Returned</span>

        <strong>
          {
            notifications.filter(
              (notification) =>
                notification.notification_type ===
                "book_returned"
            ).length
          }
        </strong>

        <p>Return notifications</p>
      </div>
    </section>

    <section className="panel books-panel">
      <div className="panel-header">
        <div>
          <p className="section-label">
            NOTIFICATIONS
          </p>

          <h3>Notification History</h3>
        </div>

        <div className="book-actions">
          <input
            type="text"
            placeholder="Search notification or student..."
            value={notificationSearch}
            onChange={(e) =>
              setNotificationSearch(
                e.target.value
              )
            }
          />
        </div>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Notification</th>
              <th>Student</th>
              <th>Type</th>
              <th>Date</th>
              <th>Read</th>
            </tr>
          </thead>

          <tbody>
            {notificationsLoading && (
              <tr>
                <td colSpan="5">
                  Loading notifications...
                </td>
              </tr>
            )}

            {notificationsError && (
              <tr>
                <td colSpan="5">
                  {notificationsError}
                </td>
              </tr>
            )}

            {!notificationsLoading &&
              !notificationsError &&
              filteredNotifications.map(
                (notification) => (
                  <tr key={notification.id}>
                    <td>
                      <strong>
                        {notification.title}
                      </strong>

                      <span>
                        {notification.message}
                      </span>
                    </td>

                    <td>
                      <strong>
                        {notification.students?.name ||
                          "Unknown Student"}
                      </strong>

                      <span>
                        {notification.students?.student_id ||
                          "-"}
                      </span>
                    </td>

                    <td>
                      {notification.notification_type ||
                        "-"}
                    </td>

                    <td>
                      {notification.created_at
                        ? new Date(
                            notification.created_at
                          ).toLocaleDateString()
                        : "-"}
                    </td>

                    <td>
                      <span
                        className={`status ${
                          notification.is_read
                            ? "available"
                            : "issued"
                        }`}
                      >
                        {notification.is_read
                          ? "Read"
                          : "Unread"}
                      </span>
                    </td>
                  </tr>
                )
              )}

            {!notificationsLoading &&
              !notificationsError &&
              filteredNotifications.length ===
                0 && (
                <tr>
                  <td colSpan="5">
                    No notifications found.
                  </td>
                </tr>
              )}
          </tbody>
        </table>
      </div>
    </section>
  </>
)}

{/* =================================================
    REPORTS PAGE
================================================= */}

{activePage === "reports" && (
  <>
    <header className="topbar">
      <div>
        <p className="welcome">
          LIBRARY ANALYTICS
        </p>

        <h2>Reports</h2>
      </div>

      <div className="top-actions">
        <button
          className="filter-button"
          onClick={loadReport}
        >
          Refresh Report
        </button>
      </div>
    </header>

    {reportLoading && (
      <section className="panel">
        Loading report...
      </section>
    )}

    {reportError && (
      <section className="panel">
        {reportError}
      </section>
    )}

    {!reportLoading &&
      !reportError &&
      reportData && (
        <>
          <section className="stats-grid">
            <div className="stat-card blue">
              <span>Total Books</span>

              <strong>
                {reportData.total_books}
              </strong>

              <p>Physical copies</p>
            </div>

            <div className="stat-card">
              <span>Total Students</span>

              <strong>
                {reportData.total_students}
              </strong>

              <p>Registered students</p>
            </div>

            <div className="stat-card">
              <span>Total Librarians</span>

              <strong>
                {reportData.total_librarians}
              </strong>

              <p>Registered staff</p>
            </div>

            <div className="stat-card">
              <span>Overdue Loans</span>

              <strong>
                {reportData.overdue_loans}
              </strong>

              <p>Require attention</p>
            </div>
          </section>

          <section className="dashboard-grid">
            <div className="panel">
              <div className="panel-header">
                <div>
                  <p className="section-label">
                    BOOK STATUS
                  </p>

                  <h3>Collection Summary</h3>
                </div>
              </div>

              <div className="quick-row">
                <span>Available Books</span>

                <strong>
                  {reportData.available_books}
                </strong>
              </div>

              <div className="quick-row">
                <span>Issued Books</span>

                <strong>
                  {reportData.issued_books}
                </strong>
              </div>

              <div className="quick-row">
                <span>Reserved Books</span>

                <strong>
                  {reportData.reserved_books}
                </strong>
              </div>

              <div className="quick-row">
                <span>Total Copies</span>

                <strong>
                  {reportData.total_books}
                </strong>
              </div>
            </div>

            <div className="panel">
              <div className="panel-header">
                <div>
                  <p className="section-label">
                    LOAN ACTIVITY
                  </p>

                  <h3>Loan Summary</h3>
                </div>
              </div>

              <div className="quick-row">
                <span>Active Loans</span>

                <strong>
                  {reportData.active_loans}
                </strong>
              </div>

              <div className="quick-row">
                <span>Returned Loans</span>

                <strong>
                  {reportData.returned_loans}
                </strong>
              </div>

              <div className="quick-row">
                <span>Overdue Loans</span>

                <strong>
                  {reportData.overdue_loans}
                </strong>
              </div>

              <div className="quick-row">
                <span>Total Loan Records</span>

                <strong>
                  {reportData.active_loans +
                    reportData.returned_loans}
                </strong>
              </div>
            </div>
          </section>
        </>
      )}
  </>
)}
      </main>
    </div>
  );
}

export default App;
