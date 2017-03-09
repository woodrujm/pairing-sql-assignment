-- Get the number of users who have registered each day, ordered by DATE.
SELECT
  count(1) AS daily_registrations,
  DATE(tmstmp) AS the_date
FROM registrations
GROUP BY DATE(tmstmp)
ORDER BY the_date;

-- Which day of the week gets the most registrations?
-- It is Saturday(day 6), proof:
SELECT
  count(1) as registration_count,
  extract(dow FROM tmstmp)
FROM registrations
GROUP BY extract(dow FROM tmstmp)
ORDER BY registration_count desc;

-- You are sending an email to users who haven't logged in in the week before '2014-08-14' and have not opted out of receiving email. Write a query to select these users.
WITH losers AS(
      SELECT DISTINCT(logins.userid) AS id
      FROM logins
      WHERE DATE(tmstmp) BETWEEN '2014-08-07' AND '2014-08-14'
      )

SELECT DISTINCT(registrations.userid)
FROM registrations
LEFT JOIN optout ON registrations.userid = optout.userid
WHERE optout.userid IS NULL
AND registrations.userid NOT IN (
                  SELECT id
                  FROM losers
                  )
;

SELECT COUNT(1) FROM registrations;


-- For every user, get the number of users who registered on the same day AS them. Hint: This is a self join (join the registrations table with itself).
SELECT dump.userid, count(dump.userid)
FROM registrations AS reggie
JOIN registrations AS dump ON date(reggie.tmstmp) = date(dump.tmstmp) AND reggie.userid != dump.userid
GROUP BY dump.userid
ORDER BY dump.userid desc;

-- You are running an A/B test and would like to target users who have logged in on mobile more times than web. You should only target users in test group A. Write a query to get all the targeted users.
WITH group_a AS (
  SELECT userid
FROM test_group
WHERE grp = 'A')

SELECT logins.userid
FROM logins JOIN group_a ON logins.userid = group_a.userid
GROUP BY logins.userid
HAVING COUNT(CASE WHEN type = 'mobile' THEN 1 ELSE NULL END) > COUNT(CASE WHEN type = 'web' THEN 1 ELSE NULL END)

-- You would like to determine each user's most communicated with user. For each user, determine the user they exchange the most messages with (outgoing plus incoming).
CREATE INDEX "registrations_userid_ndx" ON registrations (userid);
CREATE INDEX "messages_sender_ndx" ON messages (sender);
CREATE INDEX "messages_recipient_ndx" ON messages (recipient);

WITH messages_sent AS (SELECT
  u.userid,
  m.recipient,
  count(1) as sent_to_sender
FROM registrations u
JOIN messages m ON m.sender=u.userid
GROUP BY u.userid, m.recipient
order by u.userid, sent_to_sender desc),

messages_recieved AS (SELECT
  u.userid,
  m.sender,
  count(1) as sent_to_recip
FROM registrations u
JOIN messages m ON m.recipient=u.userid
GROUP BY u.userid, m.sender
order by u.userid, sent_to_recip desc),

total_messages AS (SELECT
  registrations.userid,
  messages_sent.recipient,
  sum(sent_to_recip + sent_to_sender) as message_count
FROM registrations
JOIN messages_sent on messages_sent.userid=registrations.userid
JOIN messages_recieved on messages_recieved.userid=registrations.userid AND messages_recieved.sender=messages_sent.recipient
GROUP BY registrations.userid, messages_sent.recipient)

SELECT total_messages.userid, recipient, message_count FROM total_messages
JOIN (SELECT
    userid,
    max(message_count) as max_count
  FROM total_messages
  GROUP BY userid
) as max_per_user
ON max_per_user.userid = total_messages.userid AND total_messages.message_count=max_per_user.max_count;

select 1
-- You could also consider the length of the messages when determining the user's most communicated with friend. Sum up the length of all the messages communicated between every pair of users and determine which one is the maximum. This should only be a minor change from the previous query.
--
-- What percent of the time are the above two answers different?
