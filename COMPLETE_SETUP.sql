-- ========================================
-- COMPLETE PROFESSIONAL DATING APP DATABASE
-- ========================================
-- Run ALL of these commands in Supabase SQL Editor
-- Copy everything and paste into ONE query

-- ========================================
-- STEP 1: DROP EXISTING TABLES (Start Fresh)
-- ========================================
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS likes CASCADE;
DROP TABLE IF EXISTS blocks CASCADE;
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS profile_photos CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- ========================================
-- STEP 2: CREATE USER PROFILES TABLE
-- ========================================
CREATE TABLE user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  age INTEGER,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  bio TEXT,
  location TEXT,
  interests TEXT[],
  looking_for TEXT,
  profile_photo_url TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  last_seen TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- STEP 3: CREATE PROFILE PHOTOS TABLE
-- ========================================
CREATE TABLE profile_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT FALSE,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- STEP 4: CREATE LIKES TABLE (Swipe History)
-- ========================================
CREATE TABLE likes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liker_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  liked_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('liked', 'super_liked', 'rejected')) DEFAULT 'liked',
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(liker_id, liked_id)
);

-- ========================================
-- STEP 5: CREATE MATCHES TABLE (Mutual Likes)
-- ========================================
CREATE TABLE matches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  user2_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  matched_at TIMESTAMP DEFAULT NOW(),
  last_message_at TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE(user1_id, user2_id)
);

-- ========================================
-- STEP 6: CREATE MESSAGES TABLE
-- ========================================
CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- STEP 7: CREATE BLOCKS TABLE
-- ========================================
CREATE TABLE blocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id)
);

-- ========================================
-- STEP 8: CREATE REPORTS TABLE
-- ========================================
CREATE TABLE reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  reported_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  is_resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- STEP 9: CREATE INDEXES FOR PERFORMANCE
-- ========================================
CREATE INDEX idx_user_profiles_is_active ON user_profiles(is_active);
CREATE INDEX idx_user_profiles_created_at ON user_profiles(created_at);
CREATE INDEX idx_user_profiles_last_seen ON user_profiles(last_seen);
CREATE INDEX idx_likes_liker_id ON likes(liker_id);
CREATE INDEX idx_likes_liked_id ON likes(liked_id);
CREATE INDEX idx_likes_status ON likes(status);
CREATE INDEX idx_likes_created_at ON likes(created_at);
CREATE INDEX idx_matches_user1_id ON matches(user1_id);
CREATE INDEX idx_matches_user2_id ON matches(user2_id);
CREATE INDEX idx_matches_last_message ON matches(last_message_at);
CREATE INDEX idx_messages_match_id ON messages(match_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_messages_is_read ON messages(is_read);
CREATE INDEX idx_blocks_blocker_id ON blocks(blocker_id);
CREATE INDEX idx_blocks_blocked_id ON blocks(blocked_id);
CREATE INDEX idx_profile_photos_user_id ON profile_photos(user_id);
CREATE INDEX idx_profile_photos_is_primary ON profile_photos(is_primary);

-- ========================================
-- STEP 10: ENABLE ROW LEVEL SECURITY (RLS)
-- ========================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- ========================================
-- STEP 11: RLS POLICIES - USER PROFILES
-- ========================================
CREATE POLICY "Anyone can view active profiles"
ON user_profiles FOR SELECT
USING (is_active = true);

CREATE POLICY "Users can view own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
ON user_profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- ========================================
-- STEP 12: RLS POLICIES - PROFILE PHOTOS
-- ========================================
CREATE POLICY "Anyone can view profile photos"
ON profile_photos FOR SELECT
USING (TRUE);

CREATE POLICY "Users can manage own photos"
ON profile_photos FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own photos"
ON profile_photos FOR DELETE
USING (auth.uid() = user_id);

-- ========================================
-- STEP 13: RLS POLICIES - LIKES
-- ========================================
CREATE POLICY "Users can create likes"
ON likes FOR INSERT
WITH CHECK (auth.uid() = liker_id);

CREATE POLICY "Users can view own likes"
ON likes FOR SELECT
USING (auth.uid() = liker_id OR auth.uid() = liked_id);

CREATE POLICY "Users can delete own likes"
ON likes FOR DELETE
USING (auth.uid() = liker_id);

-- ========================================
-- STEP 14: RLS POLICIES - MATCHES
-- ========================================
CREATE POLICY "Users can view own matches"
ON matches FOR SELECT
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "System can create matches"
ON matches FOR INSERT
WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can update own matches"
ON matches FOR UPDATE
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- ========================================
-- STEP 15: RLS POLICIES - MESSAGES
-- ========================================
CREATE POLICY "Users can view messages in their matches"
ON messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM matches
    WHERE matches.id = messages.match_id
    AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
  )
);

CREATE POLICY "Users can send messages"
ON messages FOR INSERT
WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update own messages"
ON messages FOR UPDATE
USING (auth.uid() = sender_id);

-- ========================================
-- STEP 16: RLS POLICIES - BLOCKS
-- ========================================
CREATE POLICY "Users can manage own blocks"
ON blocks FOR INSERT
WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can view own blocks"
ON blocks FOR SELECT
USING (auth.uid() = blocker_id OR auth.uid() = blocked_id);

CREATE POLICY "Users can delete own blocks"
ON blocks FOR DELETE
USING (auth.uid() = blocker_id);

-- ========================================
-- STEP 17: RLS POLICIES - REPORTS
-- ========================================
CREATE POLICY "Users can create reports"
ON reports FOR INSERT
WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Only admins can view reports"
ON reports FOR SELECT
USING (FALSE);

-- ========================================
-- STEP 18: CREATE VIEWS FOR COMMON QUERIES
-- ========================================
CREATE OR REPLACE VIEW user_stats AS
SELECT 
  up.id,
  up.full_name,
  COUNT(DISTINCT CASE WHEN l.status IN ('liked', 'super_liked') THEN l.id END) as likes_received,
  COUNT(DISTINCT CASE WHEN l.liker_id = up.id THEN l.id END) as likes_given,
  COUNT(DISTINCT m.id) as total_matches,
  (SELECT COUNT(*) FROM messages WHERE sender_id = up.id) as total_messages_sent
FROM user_profiles up
LEFT JOIN likes l ON up.id = l.liked_id
LEFT JOIN matches m ON (up.id = m.user1_id OR up.id = m.user2_id)
GROUP BY up.id, up.full_name;

-- ========================================
-- STEP 19: CREATE FUNCTIONS FOR BUSINESS LOGIC
-- ========================================
CREATE OR REPLACE FUNCTION create_match_if_mutual()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if the other user also liked this user
  IF EXISTS (
    SELECT 1 FROM likes
    WHERE liker_id = NEW.liked_id
    AND liked_id = NEW.liker_id
    AND status IN ('liked', 'super_liked')
  ) THEN
    -- Create match
    INSERT INTO matches (user1_id, user2_id)
    VALUES (NEW.liker_id, NEW.liked_id)
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create match on like
CREATE TRIGGER trigger_create_match_on_like
AFTER INSERT ON likes
FOR EACH ROW
EXECUTE FUNCTION create_match_if_mutual();

-- ========================================
-- STEP 20: SETUP REALTIME
-- ========================================
-- Note: Go to Supabase Dashboard → Replication
-- Enable Realtime for these tables:
-- ✓ user_profiles
-- ✓ likes
-- ✓ matches
-- ✓ messages
-- ✓ blocks

-- ========================================
-- STEP 21: VERIFY SETUP
-- ========================================
-- Run these to verify everything is set up correctly:
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check indexes
SELECT indexname FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY indexname;

-- Check RLS policies
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ========================================
-- ALL DONE! Now follow these steps:
-- ========================================
-- 1. Run this entire SQL file in Supabase SQL Editor
-- 2. Go to Supabase Dashboard → Replication
-- 3. Enable Realtime for: user_profiles, likes, matches, messages, blocks
-- 4. Replace app code with new implementation
-- 5. Test with 2+ accounts
