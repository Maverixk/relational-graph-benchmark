-- -----------------------------------------------------------------------
-- QUERY 1: Aggregation
-- Computes the 15 most prolific authors based on the number of 
-- publications within the 2014-2023 decade.
-- -----------------------------------------------------------------------
SELECT 
    a.name AS "Author", 
    COUNT(DISTINCT p.paper_id) AS "NumberOfPublications"
FROM authors a
JOIN wrote w ON a.author_id = w.author_id
JOIN papers p ON w.paper_id = p.paper_id
-- Join paper_categories to simulate the match (p)-[:BELONGS_TO]->(c)
JOIN paper_categories pc ON p.paper_id = pc.paper_id
WHERE p.year >= 2014 AND p.year <= 2023
GROUP BY a.name
ORDER BY "NumberOfPublications" DESC
LIMIT 15;