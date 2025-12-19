-- ============================================
-- Clean up stale favorites from database
-- ============================================
-- This removes favorites that point to events that no longer exist
-- (These cause "event not found" errors when trying to delete from favorites page)
--
-- INSTRUCTIONS:
-- 1. Go to your Render.com dashboard
-- 2. Click on your database service
-- 3. Click "Connect" or "Query" to open the database console
-- 4. Copy and paste the SQL commands below
-- ============================================

-- STEP 1: Check how many stale favorites exist (optional - just to see what will be deleted)
SELECT COUNT(*) as stale_favorites_count 
FROM favorite 
WHERE event_id NOT IN (SELECT id FROM eventmodel);

-- STEP 2: Delete the stale favorites
DELETE FROM favorite 
WHERE event_id NOT IN (SELECT id FROM eventmodel);

-- After running, you should see a message like "DELETE 5" (5 being the number deleted)
-- The stale favorites are now removed from the database!

