# 9jaGrade CBT Platform

A Next.js + Supabase CBT platform for 9jaGrade.

## Current build
- Student signup/login with Supabase Auth
- Student dashboard and CBT code access
- Published CBT information page
- Timed CBT interface
- Secure server-side/Postgres scoring RPC (correct answers are not sent to the student quiz page)
- Automatic result page
- Leaderboard
- Admin dashboard
- CBT builder with settings and question creation
- RLS policies for students/admins
- 9jaGrade light mint / deep green dark identity

## Setup
1. Copy `.env.local.example` to `.env.local`.
2. Add the Supabase project URL and publishable key from your Supabase project settings.
3. Run `npm install`.
4. Run `npm run dev`.

The database migrations have already been applied to the connected Supabase project used for this build.

## Make your account an admin
Create your normal account first. Then, in Supabase SQL Editor, run:

```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'YOUR-ADMIN-EMAIL');
```

Do not put a Supabase secret/service-role key in the browser or in a `NEXT_PUBLIC_` environment variable.
