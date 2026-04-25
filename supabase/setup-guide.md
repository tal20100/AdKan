# AdKan Supabase Setup Guide

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a free account
2. Create a new project — name it `adkan`, pick a region close to Israel (Frankfurt `eu-central-1` is good)
3. Save the **anon public key** (you'll need it for `SupabaseSecrets.plist`)
4. Save the **Project URL** (looks like `https://xxxxx.supabase.co`)

## Step 2: Enable Apple Sign-In

1. Dashboard → Authentication → Providers → Apple
2. Enable it
3. You'll need your Apple Services ID + Secret Key from your Apple Developer account
4. This is the same Apple Sign-In you configure in Xcode — the Supabase side just validates the tokens

## Step 3: Run the Migration

1. Dashboard → SQL Editor → New Query
2. Copy-paste the entire contents of `migration_001_initial.sql` from this folder
3. Click **Run** — it creates all 4 tables, RLS policies, and 5 RPC functions
4. Verify: go to Table Editor, you should see `users`, `groups`, `group_members`, `daily_scores`

## Step 4: Create SupabaseSecrets.plist

Create `config/SupabaseSecrets.plist` in the Xcode project (DO NOT commit this file):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://YOUR-PROJECT-ID.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>YOUR-ANON-KEY-HERE</string>
</dict>
</plist>
```

## Step 5: Verify

After running the migration, test the RPC functions in the SQL Editor:

```sql
-- Should return empty array (no groups yet)
select my_groups();
```

## Database Schema Overview

| Table | Purpose |
|-------|---------|
| `users` | One row per user, created on first Apple Sign-In |
| `groups` | Competition groups (friends, roommates, partner, coworkers) |
| `group_members` | Junction table — who's in which group + favorite flag |
| `daily_scores` | One row per user per day — only stores `daily_total_minutes` |

All RLS policies ensure users can only see data from their own groups. The only data that crosses the network is the daily total minutes — no per-app breakdown, no device IDs, no location data.
