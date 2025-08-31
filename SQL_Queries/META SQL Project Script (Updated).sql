USE ig_clone;

-- 1. Are there any tables with duplicate or missing null values? If so,how would you handle them?

-- Check for duplicate User IDs (should return 0 rows)
SELECT id, COUNT(*)
FROM users
GROUP BY id
HAVING COUNT(*) > 1;

-- Check for duplicate Usernames (should return 0 rows)
SELECT username, COUNT(*)
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

-- Check for duplicate Photo IDs (should return 0 rows)
SELECT id, COUNT(*)
FROM photos
GROUP BY id
HAVING COUNT(*) > 1;

-- Check for duplicate Comment IDs (should return 0 rows)
SELECT id, COUNT(*)
FROM comments
GROUP BY id
HAVING COUNT(*) > 1;

-- Check for duplicate Tag IDs (should return 0 rows)
SELECT id, COUNT(*)
FROM tags
GROUP BY id
HAVING COUNT(*) > 1;

-- Check for duplicate Tag Names (should return 0 rows)
SELECT tag_name, COUNT(*)
FROM tags
GROUP BY tag_name
HAVING COUNT(*) > 1;

-- Check for duplicate Likes (user_id, photo_id) - Schema PK should prevent this (should return 0 rows)
SELECT user_id, photo_id, COUNT(*)
FROM likes
GROUP BY user_id, photo_id
HAVING COUNT(*) > 1;

-- Check for duplicate Follows (follower_id, followee_id) - Schema PK should prevent this (should return 0 rows)
SELECT follower_id, followee_id, COUNT(*)
FROM follows
GROUP BY follower_id, followee_id
HAVING COUNT(*) > 1;

-- Check for duplicate Photo Tags (photo_id, tag_id) - Schema PK should prevent this (should return 0 rows)
SELECT photo_id, tag_id, COUNT(*)
FROM photo_tags
GROUP BY photo_id, tag_id
HAVING COUNT(*) > 1;


-- ------------- NULL VALUE CHECKS (for NOT NULL columns) -------------

-- Check for NULLs in users table (should return 0)
SELECT COUNT(*) AS null_count FROM users WHERE id IS NULL OR username IS NULL;

-- Check for NULLs in photos table (should return 0)
SELECT COUNT(*) AS null_count FROM photos WHERE id IS NULL OR image_url IS NULL OR user_id IS NULL;

-- Check for NULLs in comments table (should return 0)
SELECT COUNT(*) AS null_count FROM comments WHERE id IS NULL OR comment_text IS NULL OR user_id IS NULL OR photo_id IS NULL;

-- Check for NULLs in likes table (PK columns cannot be NULL - check is redundant but safe) (should return 0)
SELECT COUNT(*) AS null_count FROM likes WHERE user_id IS NULL OR photo_id IS NULL;

-- Check for NULLs in follows table (PK columns cannot be NULL - check is redundant but safe) (should return 0)
SELECT COUNT(*) AS null_count FROM follows WHERE follower_id IS NULL OR followee_id IS NULL;

-- Check for NULLs in tags table (should return 0)
SELECT COUNT(*) AS null_count FROM tags WHERE id IS NULL OR tag_name IS NULL;

-- Check for NULLs in photo_tags table (PK columns cannot be NULL - check is redundant but safe) (should return 0)
SELECT COUNT(*) AS null_count FROM photo_tags WHERE photo_id IS NULL OR tag_id IS NULL;


-- 2. What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

WITH UserActivityCounts AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT p.id) AS num_photos_posted,
        COUNT(DISTINCT c.id) AS num_comments_made,
        COUNT(DISTINCT l.photo_id) AS num_likes_made
    FROM
        users u
    LEFT JOIN
        photos p ON u.id = p.user_id
    LEFT JOIN
        comments c ON u.id = c.user_id
    LEFT JOIN
        likes l ON u.id = l.user_id
    GROUP BY
        u.id
)

SELECT
    'Photo Posting' AS activity_type,
    MIN(num_photos_posted) AS min_count,
    MAX(num_photos_posted) AS max_count,
    AVG(num_photos_posted) AS avg_count,
    SUM(CASE WHEN num_photos_posted = 0 THEN 1 ELSE 0 END) AS zero_activity_users,
    COUNT(*) AS total_users -- Total users 
FROM UserActivityCounts

UNION ALL 

SELECT
    'Commenting' AS activity_type,
    MIN(num_comments_made) AS min_count,
    MAX(num_comments_made) AS max_count,
    AVG(num_comments_made) AS avg_count,
    SUM(CASE WHEN num_comments_made = 0 THEN 1 ELSE 0 END) AS zero_activity_users,
    COUNT(*) AS total_users
FROM UserActivityCounts

UNION ALL

SELECT
    'Liking' AS activity_type,
    MIN(num_likes_made) AS min_count,
    MAX(num_likes_made) AS max_count,
    AVG(num_likes_made) AS avg_count,
    SUM(CASE WHEN num_likes_made = 0 THEN 1 ELSE 0 END) AS zero_activity_users,
    COUNT(*) AS total_users
FROM UserActivityCounts;

-- 3. Calculate the average number of tags per post (photo_tags and photos tables).

WITH TagsPerPhoto AS (
    SELECT
        p.id AS photo_id,
        -- COUNT(pt.tag_id) correctly counts 0 for photos with no tags due to LEFT JOIN.
        COUNT(pt.tag_id) AS num_tags
    FROM
        photos p
    LEFT JOIN
        photo_tags pt ON p.id = pt.photo_id 
    GROUP BY
        p.id 
)
-- Calculate the average 
SELECT
    ROUND(AVG(num_tags), 2) AS average_tags_per_post
FROM
    TagsPerPhoto;
    
    
    -- 4. Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

WITH UserPostEngagement AS (
    -- Calculate total likes and comments for EACH photo using subqueries
    SELECT
        p.user_id,  -- The ID of the user who posted the photo
        p.id AS photo_id, -- Need photo_id to join later
        (SELECT COUNT(*) FROM likes WHERE photo_id = p.id) AS likes_received,
        (SELECT COUNT(*) FROM comments WHERE photo_id = p.id) AS comments_received
    FROM photos p 
),
UserTotalEngagement AS (
    SELECT
        u.id AS user_id,
        u.username,
        COALESCE(SUM(upe.likes_received), 0) AS total_likes_received,
        COALESCE(SUM(upe.comments_received), 0) AS total_comments_received,
        (COALESCE(SUM(upe.likes_received), 0) + COALESCE(SUM(upe.comments_received), 0)) AS total_engagement_score
    FROM users u
    LEFT JOIN UserPostEngagement upe ON u.id = upe.user_id -- Join users to their engagement stats
    GROUP BY u.id, u.username
)
-- Final selection and ranking
SELECT
    user_id,
    username,
    total_likes_received,
    total_comments_received,
    total_engagement_score,
    RANK() OVER (ORDER BY total_engagement_score DESC) AS engagement_rank
FROM UserTotalEngagement
ORDER BY engagement_rank ASC, user_id ASC
LIMIT 5;


-- 5. Which users have the highest number of followers and followings?


SELECT
    u.id AS user_id,
    u.username,
    -- Subquery to count followers for user u
    (SELECT COUNT(*) FROM follows WHERE followee_id = u.id) AS followers_count,
    -- Subquery to count how many user u is following
    (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count
FROM users u

ORDER BY
    followers_count DESC,
    following_count DESC,
    u.id ASC
    LIMIT 5;
    
    
    -- 6. Calculate the average engagement rate (likes, comments) per post for each user.
    

WITH PhotoEngagementScore AS (
    -- Calculate total likes and comments for EACH photo
    SELECT
        p.id AS photo_id,
        p.user_id, 
        (SELECT COUNT(*) FROM likes WHERE photo_id = p.id) AS likes_on_photo,
        (SELECT COUNT(*) FROM comments WHERE photo_id = p.id) AS comments_on_photo
    FROM photos p
)
-- Calculate the average engagement score per post for each user
SELECT
    u.id AS user_id,
    u.username,
    -- Calculate the average of (likes + comments) for all photos posted by user u
    COALESCE(AVG(pes.likes_on_photo + pes.comments_on_photo), 0) AS avg_engagement_per_post
FROM
    users u
LEFT JOIN 
    PhotoEngagementScore pes ON u.id = pes.user_id
GROUP BY
    u.id, u.username 
ORDER BY
    avg_engagement_per_post DESC, -- Show users with highest average engagement first
    u.id ASC; 

    
-- 7. Get the list of users who have never liked any post (users and likes tables)


SELECT
    COUNT(*) AS users_without_likes_count
FROM
    users u
WHERE NOT EXISTS (
    SELECT 1
    FROM likes l
    WHERE l.user_id = u.id -- to check if any like exists for this user
);


-- 8. How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?

-- Q8.a. Strategy: List of Popular Tags

SELECT 
	tag_name, 
	COUNT(*) 
FROM photo_tags
JOIN tags ON tags.id = photo_tags.tag_id
GROUP BY tag_name
ORDER BY COUNT(*) DESC;

-- Q8.b. Strategy: Identifying Trending Tags by Recent Likes

-- Define the start date for our 'recent' period.
SET @recent_cutoff_date = '2017-04-01'; -- Example cutoff date

SELECT
    t.tag_name,
    COUNT(l.user_id) AS recent_likes_count -- Count likes received recently on photos with this tag
FROM
    tags t
JOIN
    photo_tags pt ON t.id = pt.tag_id 
JOIN
    likes l ON pt.photo_id = l.photo_id 
WHERE
    l.created_at >= @recent_cutoff_date -- Filter likes to only include recent ones
GROUP BY
    t.tag_name 
ORDER BY
    recent_likes_count DESC 
LIMIT 10; 


-- 9. Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies?
 
SELECT * FROM photos p
JOIN users u ON p.user_id = u.id; --  does not have a column specifying the content type (e.g., 'photo', 'video', 'reel'). Every entry is essentially treated as a generic "photo" based on the table name and image_url.


-- 10. Calculate the total number of likes, comments, and photo tags for each user.


WITH PhotoStats AS (
    -- Calculate likes, comments, and tags for EACH photo
    SELECT
        p.id AS photo_id,
        p.user_id, 
        (SELECT COUNT(*) FROM likes WHERE photo_id = p.id) AS likes_count,
        (SELECT COUNT(*) FROM comments WHERE photo_id = p.id) AS comments_count,
        (SELECT COUNT(*) FROM photo_tags WHERE photo_id = p.id) AS tags_count
    FROM photos p
)
SELECT
    u.id AS user_id,
    u.username,
    COALESCE(SUM(ps.likes_count), 0) AS total_likes_received,
    COALESCE(SUM(ps.comments_count), 0) AS total_comments_received,
    COALESCE(SUM(ps.tags_count), 0) AS total_tags_used_on_posts
FROM
    users u
LEFT JOIN -- To Include users even if they have no photos/stats
    PhotoStats ps ON u.id = ps.user_id
GROUP BY
    u.id, u.username 
ORDER BY
	total_likes_received DESC,
    u.id ASC; 
    
    
-- 11. Rank users based on their total engagement (likes, comments, shares) over a month


-- NOTE: "Shares" data is not available in the schema.
-- NOTE: Using April 2025 as the analysis month, based on observed data concentration.

-- Define the start and end dates for April 2025
SET @start_date = '2025-04-01 00:00:00';
SET @end_date = '2025-04-30 23:59:59'; 

WITH MonthlyLikes AS (
    -- Count likes MADE BY each user in the specified month
    SELECT
        user_id,
        COUNT(*) AS likes_count
    FROM likes
    WHERE created_at BETWEEN @start_date AND @end_date
    GROUP BY user_id
),
MonthlyComments AS (
    -- Count comments MADE BY each user in the specified month
    SELECT
        user_id,
        COUNT(*) AS comments_count
    FROM comments
    WHERE created_at BETWEEN @start_date AND @end_date
    GROUP BY user_id
)
-- Combine user data with monthly activity and rank
SELECT
    u.id AS user_id,
    u.username,
    COALESCE(ml.likes_count, 0) AS likes_made_in_month,
    COALESCE(mc.comments_count, 0) AS comments_made_in_month,
    (COALESCE(ml.likes_count, 0) + COALESCE(mc.comments_count, 0)) AS total_monthly_engagement,
    DENSE_RANK() OVER (ORDER BY (COALESCE(ml.likes_count, 0) + COALESCE(mc.comments_count, 0)) DESC) AS monthly_engagement_rank
FROM
    users u
LEFT JOIN MonthlyLikes ml ON u.id = ml.user_id
LEFT JOIN MonthlyComments mc ON u.id = mc.user_id
ORDER BY
    monthly_engagement_rank ASC,
    u.id ASC
LIMIT 20;


-- 12. Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.


WITH LikesPerPhoto AS (
    -- Step 1: Calculate likes for each photo
    SELECT
        photo_id,
        COUNT(*) AS likes_count
    FROM likes
    GROUP BY photo_id
),
AvgLikesPerTag AS (
    -- Step 2 (Required CTE): Calculate average likes for each tag
    SELECT
        t.id AS tag_id,
        t.tag_name,
        -- Calculate the average likes of photos associated with this tag
        -- Use LEFT JOIN and COALESCE to include photos with 0 likes
        AVG(COALESCE(lpp.likes_count, 0)) AS avg_likes_for_tag
    FROM
        tags t
    JOIN
        photo_tags pt ON t.id = pt.tag_id -- Link tags to photo_tags
    LEFT JOIN -- Crucial: Include photos that might have 0 likes
        LikesPerPhoto lpp ON pt.photo_id = lpp.photo_id -- Link to the likes count per photo
    GROUP BY
        t.id, t.tag_name -- Group by tag to average across its photos
)
-- Step 3: Select from the CTE and rank
SELECT
    tag_name,
    avg_likes_for_tag
FROM
    AvgLikesPerTag
ORDER BY
    avg_likes_for_tag DESC
    LIMIT 5;
    
    
-- 13. Retrieve the users who have started following someone after being followed by that person


SELECT DISTINCT
    f2.follower_id AS user_id, -- This is User A, who followed back later
    u.username
FROM
    follows f1 -- Represents the initial follow (e.g., B follows A)
INNER JOIN -- Use INNER JOIN as we need both follow events to exist
    follows f2 ON f1.follower_id = f2.followee_id -- f1's follower (B) is f2's followee (B)
               AND f1.followee_id = f2.follower_id -- f1's followee (A) is f2's follower (A)
INNER JOIN
    users u ON f2.follower_id = u.id -- Get username for User A
WHERE
    f2.created_at > f1.created_at -- The crucial time condition: f2's timestamp must be later
ORDER BY
    user_id; -- Order for consistency
    
    
-- Subjective Questions !


-- 1. Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?


-- SQ1 Supporting Query: Comprehensive User Value Metrics

WITH UserActivitySummary AS (
    SELECT
        u.id AS user_id,
        u.username,
        COUNT(DISTINCT p.id) AS num_posts_made,
        COUNT(DISTINCT c.id) AS num_comments_made,
        COUNT(DISTINCT l.photo_id) AS num_likes_made,
        (SELECT COUNT(*) FROM likes INNER JOIN photos ON likes.photo_id = photos.id WHERE photos.user_id = u.id) AS total_likes_received,
        (SELECT COUNT(*) FROM comments INNER JOIN photos ON comments.photo_id = photos.id WHERE photos.user_id = u.id) AS total_comments_received,
        (SELECT COUNT(*) FROM follows WHERE followee_id = u.id) AS followers_count
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN comments c ON u.id = c.user_id
    LEFT JOIN likes l ON u.id = l.user_id
    GROUP BY u.id, u.username
)
SELECT
    user_id,
    username,
    num_posts_made,
    num_comments_made,
    num_likes_made,
    total_likes_received,
    total_comments_received,
    followers_count
FROM UserActivitySummary
ORDER BY
    total_likes_received DESC, followers_count DESC
LIMIT 10; -- Focus on top potential users


-- 2. For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?

-- SQ2 Supporting Query: Identify "Zero Activity" Inactive Users

SELECT
    u.id AS user_id,
    u.username
FROM
    users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN comments c ON u.id = c.user_id
LEFT JOIN likes l ON u.id = l.user_id
GROUP BY u.id, u.username
HAVING
    COUNT(DISTINCT p.id) = 0 AND -- No photos posted
    COUNT(DISTINCT c.id) = 0 AND -- No comments made
    COUNT(DISTINCT l.photo_id) = 0 -- No likes given
ORDER BY u.id;


-- 3. Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?

-- SQ3 Supporting Query: Top Hashtags by Average Engagement (Likes + Comments)

WITH PhotoEngagement AS (
    SELECT
        p.id AS photo_id,
        (SELECT COUNT(*) FROM likes WHERE photo_id = p.id) AS likes_count,
        (SELECT COUNT(*) FROM comments WHERE photo_id = p.id) AS comments_count
    FROM photos p
),
TagPerformance AS (
    SELECT
        t.tag_name,
        AVG(COALESCE(pe.likes_count, 0) + COALESCE(pe.comments_count, 0)) AS avg_total_engagement_for_tag
    FROM tags t
    JOIN photo_tags pt ON t.id = pt.tag_id
    LEFT JOIN PhotoEngagement pe ON pt.photo_id = pe.photo_id
    GROUP BY t.tag_name
)
SELECT
    tag_name,
    avg_total_engagement_for_tag
FROM TagPerformance
ORDER BY avg_total_engagement_for_tag DESC
LIMIT 10; -- Identify top performing themes

-- 4. Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?

-- SQ4 Supporting Query: Posting Activity by Day of Week and Hour

SELECT
    DAYNAME(created_dat) AS day_of_week,
    HOUR(created_dat) AS hour_of_day,
    COUNT(id) AS num_posts
FROM photos
GROUP BY day_of_week, hour_of_day
ORDER BY num_posts DESC;

-- 5. Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns?

-- SQ5 Supporting Query: Potential Influencer Candidates Scorecard

WITH UserEngagementAndReach AS (
    SELECT
        u.id AS user_id,
        u.username,
        (SELECT COUNT(*) FROM photos WHERE user_id = u.id) AS num_photos_posted,
        (SELECT COUNT(*) FROM follows WHERE followee_id = u.id) AS followers_count,
        (SELECT COUNT(*) FROM likes INNER JOIN photos ON likes.photo_id = photos.id WHERE photos.user_id = u.id) AS total_likes_received,
        (SELECT COUNT(*) FROM comments INNER JOIN photos ON comments.photo_id = photos.id WHERE photos.user_id = u.id) AS total_comments_received
    FROM users u
)
SELECT
    user_id,
    username,
    num_photos_posted,
    followers_count,
    total_likes_received,
    total_comments_received,
    -- Simple composite score: (Followers * weight) + (LikesReceived * weight) + (CommentsReceived * weight)
    -- Adjust weights based on business priority (e.g., followers might be more important for reach)
    (followers_count * 0.5 + total_likes_received * 0.3 + total_comments_received * 0.2) AS influencer_score
FROM UserEngagementAndReach
ORDER BY influencer_score DESC
LIMIT 10; -- Top influencer candidates


-- 6. Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?

-- SQ6 Supporting Query: Basic User Segmentation Example

SELECT
    u.id AS user_id,
    u.username,
    CASE
        WHEN (SELECT COUNT(*) FROM photos WHERE user_id = u.id) > 5 AND
             (SELECT COUNT(*) FROM likes WHERE user_id = u.id) > 10 THEN 'Active Creator & Engager'
        WHEN (SELECT COUNT(*) FROM photos WHERE user_id = u.id) = 0 AND
             (SELECT COUNT(*) FROM likes WHERE user_id = u.id) > 10 THEN 'Active Consumer (Liker)'
        WHEN (SELECT COUNT(*) FROM photos WHERE user_id = u.id) > 0 AND
             (SELECT COUNT(*) FROM likes WHERE user_id = u.id) = 0 AND
             (SELECT COUNT(*) FROM comments WHERE user_id = u.id) = 0 THEN 'Content Broadcaster (Low Engagement)'
        ELSE 'Passive/Low Activity'
    END AS user_segment
FROM users u
ORDER BY user_id;


-- 7. If data on ad campaigns (impressions, clicks, conversions) is available, how would you measure their effectiveness and optimize future campaigns?


-- -- -------------------------------------------------------------------------------- --
-- Subjective Question 7: Ad Campaign Effectiveness                                 --
-- NOTE: The following query is CONCEPTUAL ONLY and cannot be run on the           --
--       current schema as the required ad-related tables do not exist.            --
--       It is provided to illustrate the logic of calculating a key ad metric. 

-- SELECT
--     ac.campaign_name,
--     (CAST(COUNT(DISTINCT ad_clicks.click_id) AS DECIMAL) / COUNT(DISTINCT ad_impressions.impression_id)) * 100 AS CTR_percentage
-- FROM
--     ad_campaigns ac
-- JOIN
--     ads a ON ac.campaign_id = a.campaign_id
-- LEFT JOIN
--     ad_impressions ON a.ad_id = ad_impressions.ad_id
-- LEFT JOIN
--     ad_clicks ON ad_impressions.impression_id = ad_clicks.impression_id -- or ad_clicks.ad_id = a.ad_id
-- GROUP BY
--     ac.campaign_name
-- ORDER BY CTR_percentage DESC;

-- This query is illustrative.
-- The necessary 'ad_campaigns', 'ads', 'ad_impressions', and 'ad_clicks' tables are NOT present in the provided schema.


-- 8. How can you use user activity data to identify potential brand ambassadors or advocates who could help promote Instagram's initiatives or events?

-- SQ8 Supporting Query: Candidates for Brand Ambassadors/Advocates

WITH UserInfluenceMetrics AS (
    SELECT
        u.id AS user_id,
        u.username,
        (SELECT COUNT(*) FROM follows WHERE followee_id = u.id) AS followers_count,
        (SELECT COUNT(*) FROM likes INNER JOIN photos ON likes.photo_id = photos.id WHERE photos.user_id = u.id) AS total_likes_received,
        (SELECT COUNT(*) FROM comments INNER JOIN photos ON comments.photo_id = photos.id WHERE photos.user_id = u.id) AS total_comments_received,
        (SELECT COUNT(*) FROM photos WHERE user_id = u.id) AS num_posts_made
    FROM users u
),
RankedUsers AS (
    SELECT
        user_id,
        username,
        followers_count,
        total_likes_received,
        total_comments_received,
        num_posts_made,
        -- Combined score for advocacy potential: prioritizes engagement and reach
        (followers_count * 0.4 + total_likes_received * 0.3 + total_comments_received * 0.2 + num_posts_made * 0.1) AS advocacy_score,
        RANK() OVER (ORDER BY followers_count DESC, total_likes_received DESC) AS reach_engagement_rank
    FROM UserInfluenceMetrics
    WHERE num_posts_made > 0 -- Only consider users who actually post content
)
SELECT
    user_id,
    username,
    followers_count,
    total_likes_received,
    total_comments_received,
    num_posts_made,
    advocacy_score,
    reach_engagement_rank
FROM RankedUsers
WHERE advocacy_score > 0 -- Exclude users with zero overall interaction on their content
ORDER BY advocacy_score DESC
LIMIT 10;

-- 9. How would you approach this problem, if the objective and subjective questions weren't given?

-- SQ9 Supporting Query: Example of Initial Data Exploration

-- 1. List all available tables to see the overall structure.
SHOW TABLES;

-- 2. Inspect the columns of a key table to understand its attributes.
DESCRIBE users;

-- 3. Get a high-level summary of the data volume and time range.
SELECT
    COUNT(*) AS total_users,
    MIN(created_at) AS first_signup,
    MAX(created_at) AS last_signup
FROM users;

-- 10. Assuming there's a "User_Interactions" table tracking user engagements, how can you update the "Engagement_Type" column to change all instances of "Like" to "Heart" to align with Instagram's terminology?

-- SQ10 Supporting Query: Hypothetical Data Update

UPDATE User_Interactions -- Assumes this table exists in the context of the question
SET Engagement_Type = 'Heart'
WHERE Engagement_Type = 'Like';



