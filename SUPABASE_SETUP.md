# Project CREATE — Supabase production setup

The public frontend is hosted on GitHub Pages. This setup adds Supabase Auth and a PostgreSQL database for student profiles, learning progress, quiz attempts, and workspace drafts.

## 1. Create the Supabase project
1. Open https://supabase.com/dashboard and sign in/create an account.
2. Select **New project** and choose an organization.
3. Project name: **Project CREATE**.
4. Create a strong database password and save it somewhere private. Do not send it in chat or commit it to GitHub.
5. Choose a region near the Philippines if available, then create the project and wait for provisioning to finish.

## 2. Create the database tables
1. In the Supabase project, open **SQL Editor**.
2. Choose **New query**.
3. Open this repository file: `supabase/schema.sql`.
4. Copy the whole file into SQL Editor and click **Run**.
5. Confirm that the tables `profiles`, `student_progress`, `quiz_attempts`, and `workspace_drafts` exist in Table Editor.

## 3. Get the browser-safe project settings
1. In Supabase, open **Project Settings → API** (the exact label may say **API Keys**).
2. Copy the **Project URL**.
3. Copy the **publishable key** (or legacy `anon` key). This key is designed for frontend use when Row Level Security is enabled.
4. Do NOT copy, share, or publish the `service_role` / secret key.

## 4. Connect the live website
Send me only:
- the Project URL (looks like `https://....supabase.co`)
- the publishable/anon key (long public key)

These two values are not database passwords. I can then wire the frontend to Supabase Auth and persist each student's data online. Do not send the database password or any service-role/secret key.

## 5. Auth settings
In **Authentication → URL Configuration**, set:
- Site URL: `https://akosipaurodrigo-cpu.github.io/Project-CREATE/`
- Add this Redirect URL: `https://akosipaurodrigo-cpu.github.io/Project-CREATE/*`

For the first test, leave email confirmation enabled if you have a working email inbox. If sign-up requires email confirmation, students must click the confirmation link before signing in. Do not disable security settings just to make testing easier.

## Current status
- GitHub Pages hosts the public frontend.
- The SQL schema in this repository is prepared for Supabase.
- The backend is NOT connected until the project is created and the Project URL + publishable/anon key are configured.
- Teacher/admin access is not self-service. Roles must be granted through a trusted admin process; students cannot promote themselves.
