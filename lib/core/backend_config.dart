/// Public connection details of the Movira server (Supabase, region Frankfurt).
///
/// These two values are meant to be inside the app: the project address and the
/// public "anon" key only let a signed-in user reach their own rows, because
/// every table is protected by row level security. Secrets (the AI key, the
/// service key) are NEVER put here; they stay on the server.
const String backendUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://punqriltcgbwcuwhmdxl.supabase.co',
);

const String backendAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB1bnFyaWx0Y2did2N1d2htZHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTU2OTE5MjEsImV4cCI6MjExMTI2NzkyMX0.sTt8wE3M5c33chyqjQ775XtJaUbKF1reOq0b4krrcA0',
);

/// Public "Web" OAuth client id from Google Cloud (not a secret). While it is
/// empty the "Continue with Google" button is hidden, so no dead button is shown.
const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

/// Set to true by `main` once the server client started; the app works without it.
bool backendReady = false;
