import "./App.css";
import logo from "./assets/readspace-logo.jpg";

function ArrowIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M5 12h14M13 6l6 6-6 6"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function DownloadIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M12 3v12m0 0 5-5m-5 5-5-5M5 20h14"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function BookIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M4 5.5A2.5 2.5 0 0 1 6.5 3H11v16H6.5A2.5 2.5 0 0 0 4 21.5v-16ZM20 5.5A2.5 2.5 0 0 0 17.5 3H13v16h4.5a2.5 2.5 0 0 1 2.5 2.5v-16Z"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function ScanIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M8 4H5a1 1 0 0 0-1 1v3M16 4h3a1 1 0 0 1 1 1v3M8 20H5a1 1 0 0 1-1-1v-3M16 20h3a1 1 0 0 0 1-1v-3M8 12h8"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  );
}

function BellIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M18 9a6 6 0 1 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9ZM10 21h4"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function App() {
  const dashboardUrl = "http://localhost:5173";

  return (
    <div className="site-shell">

      {/* ================= NAVBAR ================= */}

      <header className="navbar">
        <a href="#home" className="brand">
          <div className="brand-logo-wrap">
            <img
              src={logo}
              alt="ReadSpace"
              className="brand-logo"
            />
          </div>

          <div className="brand-copy">
            <span className="brand-name">
              ReadSpace
            </span>

            <span className="brand-subtitle">
              Smart Library System
            </span>
          </div>
        </a>

        <nav className="nav-links">
          <a href="#system">System</a>
          <a href="#experiences">Features</a>
          <a href="#download">Apps</a>
        </nav>

        <a
          href={dashboardUrl}
          target="_blank"
          rel="noreferrer"
          className="nav-button"
        >
          Open Dashboard

          <span>
            <ArrowIcon />
          </span>
        </a>
      </header>

      <main>

        {/* ================= HERO ================= */}

        <section
          className="hero section"
          id="home"
        >
          <div className="hero-copy">

            <div className="eyebrow">
              <span className="eyebrow-dot" />
              SMART LIBRARY MANAGEMENT
            </div>

            <h1 className="hero-title">
              One library.
              <span>Three experiences.</span>
            </h1>

            <p className="hero-description">
              ReadSpace brings administrators,
              librarians and students into one
              connected library ecosystem — simple,
              organized and always in sync.
            </p>

            <div className="hero-actions">
              <a
                href={dashboardUrl}
                target="_blank"
                rel="noreferrer"
                className="button button-primary"
              >
                Open Library Dashboard

                <span className="button-icon">
                  <ArrowIcon />
                </span>
              </a>

              <a
                href="#download"
                className="button button-secondary"
              >
                Download Apps
              </a>
            </div>

            <div className="hero-meta">
              <div className="status-dot" />

              <span>
                Web Dashboard
              </span>

              <span className="meta-divider">
                •
              </span>

              <span>
                Android Apps
              </span>

              <span className="meta-divider">
                •
              </span>

              <span>
                Live Library Data
              </span>
            </div>
          </div>

          {/* HERO PRODUCT PREVIEW */}

          <div className="hero-visual">
            <div className="visual-glow" />

            <div className="portal-preview">

              <div className="preview-topbar">
                <div className="preview-brand">
                  <img
                    src={logo}
                    alt=""
                  />

                  <div>
                    <strong>
                      ReadSpace
                    </strong>

                    <span>
                      Library Overview
                    </span>
                  </div>
                </div>

                <div className="preview-profile">
                  RS
                </div>
              </div>

              <div className="preview-welcome">
                <div>
                  <span className="preview-label">
                    GOOD MORNING
                  </span>

                  <h3>
                    Your library,
                    at a glance.
                  </h3>
                </div>

                <span className="preview-date">
                  Aug 28
                </span>
              </div>

              <div className="preview-stats">
                <div className="mini-stat">
                  <span>
                    BOOKS
                  </span>

                  <strong>
                    248
                  </strong>

                  <small>
                    Total copies
                  </small>
                </div>

                <div className="mini-stat">
                  <span>
                    ISSUED
                  </span>

                  <strong>
                    32
                  </strong>

                  <small>
                    Active loans
                  </small>
                </div>

                <div className="mini-stat">
                  <span>
                    AVAILABLE
                  </span>

                  <strong>
                    216
                  </strong>

                  <small>
                    Ready to borrow
                  </small>
                </div>
              </div>

              <div className="preview-activity">
                <div className="activity-heading">
                  <div>
                    <span>
                      RECENT ACTIVITY
                    </span>

                    <strong>
                      Library movement
                    </strong>
                  </div>

                  <span className="live-pill">
                    LIVE
                  </span>
                </div>

                <div className="activity-item">
                  <div className="activity-icon">
                    ✓
                  </div>

                  <div>
                    <strong>
                      Book issued
                    </strong>

                    <span>
                      ACC005 → BCA002
                    </span>
                  </div>

                  <small>
                    Now
                  </small>
                </div>

                <div className="activity-item">
                  <div className="activity-icon">
                    ↙
                  </div>

                  <div>
                    <strong>
                      Book returned
                    </strong>

                    <span>
                      ACC003
                    </span>
                  </div>

                  <small>
                    5m
                  </small>
                </div>

                <div className="preview-nav">
                  <span className="preview-nav-active">
                    Overview
                  </span>

                  <span>
                    Books
                  </span>

                  <span>
                    Students
                  </span>

                  <span>
                    Activity
                  </span>
                </div>
              </div>

            </div>
          </div>
        </section>

        {/* ================= TICKER ================= */}

        <section className="ticker">
          <div className="ticker-track">
            <span>
              ORGANIZE
            </span>

            <i>•</i>

            <span>
              MANAGE
            </span>

            <i>•</i>

            <span>
              TRACK
            </span>

            <i>•</i>

            <span>
              NOTIFY
            </span>

            <i>•</i>

            <span>
              CONNECT
            </span>

            <i>•</i>

            <span>
              READSPACE
            </span>
          </div>
        </section>

        {/* ================= EXPERIENCES ================= */}

        <section
          className="experiences section"
          id="experiences"
        >
          <div className="section-heading">
            <span className="section-number">
              01
            </span>

            <div>
              <span className="section-kicker">
                ONE CONNECTED SYSTEM
              </span>

              <h2>
                Built for everyone
                <br />
                inside the library.
              </h2>
            </div>

            <p>
              Each ReadSpace experience is focused
              on exactly what that user needs —
              nothing more, nothing complicated.
            </p>
          </div>

          <div className="experience-grid">

            <article className="experience-card">
              <div className="card-topline">
                <span>
                  01
                </span>

                <span className="card-arrow">
                  ↗
                </span>
              </div>

              <div className="feature-icon">
                <BookIcon />
              </div>

              <h3>
                Library Dashboard
              </h3>

              <p>
                Manage the complete library from one
                clean web dashboard.
              </p>

              <ul>
                <li>
                  Add books & copies
                </li>

                <li>
                  Add students
                </li>

                <li>
                  Manage librarians
                </li>

                <li>
                  Monitor library activity
                </li>
              </ul>

              <a
                href={dashboardUrl}
                target="_blank"
                rel="noreferrer"
                className="text-link"
              >
                Open dashboard
                <ArrowIcon />
              </a>
            </article>

            <article className="experience-card">
              <div className="card-topline">
                <span>
                  02
                </span>

                <span className="card-arrow">
                  ↗
                </span>
              </div>

              <div className="feature-icon">
                <ScanIcon />
              </div>

              <h3>
                Staff App
              </h3>

              <p>
                Fast library circulation built for
                librarians on the move.
              </p>

              <ul>
                <li>
                  Issue & return books
                </li>

                <li>
                  Scan book codes
                </li>

                <li>
                  Check active loans
                </li>

                <li>
                  View staff activity
                </li>
              </ul>

              <a
                href="/downloads/readspace-staff.apk"
                download
                className="text-link"
              >
                Download app
                <DownloadIcon />
              </a>
            </article>

            <article className="experience-card">
              <div className="card-topline">
                <span>
                  03
                </span>

                <span className="card-arrow">
                  ↗
                </span>
              </div>

              <div className="feature-icon">
                <BellIcon />
              </div>

              <h3>
                Student App
              </h3>

              <p>
                Everything students need to stay
                updated with their library account.
              </p>

              <ul>
                <li>
                  Check book availability
                </li>

                <li>
                  View borrowed books
                </li>

                <li>
                  Track due dates & fines
                </li>

                <li>
                  Receive live notifications
                </li>
              </ul>

              <a
                href="/downloads/readspace-student.apk"
                download
                className="text-link"
              >
                Download app
                <DownloadIcon />
              </a>
            </article>

          </div>
        </section>

        {/* ================= HOW SYSTEM WORKS ================= */}

        <section
          className="system section"
          id="system"
        >
          <div className="system-copy">
            <span className="section-number">
              02
            </span>

            <span className="section-kicker">
              WHY READSPACE
            </span>

            <h2>
              Everything stays
              connected.
            </h2>

            <p>
              One action can update the entire
              library experience. When a librarian
              issues a book, ReadSpace updates the
              database, book status and student
              experience together.
            </p>

            <div className="system-check">
              <span>
                ✓
              </span>

              <p>
                No separate records to maintain.
              </p>
            </div>
          </div>

          <div className="flow-card">

            <div className="flow-heading">
              <span>
                REAL-TIME FLOW
              </span>

              <div className="flow-live">
                <i />
                Connected
              </div>
            </div>

            <div className="flow-step">
              <span className="flow-number">
                01
              </span>

              <div>
                <strong>
                  Admin
                </strong>

                <p>
                  Adds library records
                </p>
              </div>
            </div>

            <div className="flow-line" />

            <div className="flow-step">
              <span className="flow-number">
                02
              </span>

              <div>
                <strong>
                  Librarian
                </strong>

                <p>
                  Issues or returns book
                </p>
              </div>
            </div>

            <div className="flow-line" />

            <div className="flow-step">
              <span className="flow-number">
                03
              </span>

              <div>
                <strong>
                  ReadSpace
                </strong>

                <p>
                  Updates library data
                </p>
              </div>
            </div>

            <div className="flow-line" />

            <div className="flow-step flow-step-final">
              <span className="flow-number">
                04
              </span>

              <div>
                <strong>
                  Student
                </strong>

                <p>
                  Gets the update instantly
                </p>
              </div>

              <span className="notification-pulse">
                ●
              </span>
            </div>

          </div>
        </section>

        {/* ================= DOWNLOAD ================= */}

        <section
          className="download-section section"
          id="download"
        >
          <div className="download-shell">

            <span className="section-kicker">
              GET STARTED
            </span>

            <h2>
              Your library.
              <br />
              Everywhere it needs to be.
            </h2>

            <p>
              Open the management dashboard or
              download the ReadSpace Android apps
              directly from this portal.
            </p>

            <div className="download-actions">

              <a
                href={dashboardUrl}
                target="_blank"
                rel="noreferrer"
                className="download-card"
              >
                <div className="download-card-icon">
                  <BookIcon />
                </div>

                <div>
                  <span>
                    WEB
                  </span>

                  <strong>
                    Library Dashboard
                  </strong>

                  <small>
                    Open management portal
                  </small>
                </div>

                <div className="download-arrow">
                  <ArrowIcon />
                </div>
              </a>

              <a
                href="/downloads/readspace-staff.apk"
                download
                className="download-card"
              >
                <div className="download-card-icon">
                  <ScanIcon />
                </div>

                <div>
                  <span>
                    ANDROID
                  </span>

                  <strong>
                    ReadSpace Staff
                  </strong>

                  <small>
                    Download APK
                  </small>
                </div>

                <div className="download-arrow">
                  <DownloadIcon />
                </div>
              </a>

              <a
                href="/downloads/readspace-student.apk"
                download
                className="download-card"
              >
                <div className="download-card-icon">
                  <BellIcon />
                </div>

                <div>
                  <span>
                    ANDROID
                  </span>

                  <strong>
                    ReadSpace Student
                  </strong>

                  <small>
                    Download APK
                  </small>
                </div>

                <div className="download-arrow">
                  <DownloadIcon />
                </div>
              </a>

            </div>

            <div className="platform-note">
              <span className="status-dot" />

              ReadSpace Android • Version 1.0.0
            </div>

          </div>
        </section>

      </main>

      {/* ================= FOOTER ================= */}

      <footer className="footer">
  <div className="footer-top">
    <div className="footer-brand">
      <img
        src={logo}
        alt="ReadSpace"
      />

      <div>
        <strong>ReadSpace</strong>
        <span>Smart Library System</span>
      </div>
    </div>

    <p className="footer-tagline">
      One connected space for every book.
    </p>
  </div>

  <div className="footer-bottom">
    <span>
      © 2026 ReadSpace. All rights reserved.
    </span>

    <div className="developer-credit">
      <span>Developed by</span>

      <strong>Zeenat</strong>

      <span className="footer-dot">•</span>

      <a
        href="https://www.linkedin.com/in/zeenat-ansari-ab566b353"
        target="_blank"
        rel="noreferrer"
      >
        LinkedIn
      </a>

      <span className="footer-dot">•</span>

      <a
        href="https://github.com/Zeenat-25"
        target="_blank"
        rel="noreferrer"
      >
        GitHub
      </a>

      <span className="footer-dot">•</span>

      <a href="mailto:libraskingdom@gmail.com">
        Email
      </a>
    </div>
  </div>
</footer>

    </div>
  );
}

export default App;