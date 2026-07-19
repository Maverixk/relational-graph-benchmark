-- -----------------------------------------------------------------------
-- QUERY 2: Deep Traversal 
-- Computes the 15 most frequent second-degree co-authors for a specific 
-- target author ('Sergey Levine'). It computes direct co-authors first, 
-- and then the second-degree ones, excluding first-degree connections.
-- -----------------------------------------------------------------------
WITH Target AS (
    SELECT author_id FROM authors WHERE name = 'Sergey Levine'
),
DirectCoauthors AS (
    -- Pre-compute direct co-authors to use in the NOT IN filter
    SELECT DISTINCT w2.author_id
    FROM Target t
    JOIN wrote w1 ON t.author_id = w1.author_id
    JOIN wrote w2 ON w1.paper_id = w2.paper_id
    WHERE w2.author_id != t.author_id
)
SELECT 
    coco_a.name AS "SecondDegreeConnection", 
    COUNT(w2_coco.paper_id) AS "NumberOfCollaborations"
FROM Target t
-- (target)-[:WROTE]->(p1)
JOIN wrote w1_t ON t.author_id = w1_t.author_id
-- <-[:WROTE]-(coauthor)
JOIN wrote w1_co ON w1_t.paper_id = w1_co.paper_id
-- -[:WROTE]->(p2)
JOIN wrote w2_co ON w1_co.author_id = w2_co.author_id
-- <-[:WROTE]-(co_coauthor)
JOIN wrote w2_coco ON w2_co.paper_id = w2_coco.paper_id
-- Match to get the final author's name
JOIN authors coco_a ON w2_coco.author_id = coco_a.author_id
WHERE 
    -- 1. Cypher's native relationship uniqueness (paths cannot reuse relationships):
    w1_co.author_id != t.author_id             -- coauthor != target
    AND w1_co.paper_id != w2_co.paper_id       -- p1 != p2
    AND w2_co.author_id != w2_coco.author_id   -- coauthor != co_coauthor
    -- 2. Cypher's explicit WHERE clauses:
    AND w2_coco.author_id != t.author_id       -- target <> co_coauthor
    AND w2_coco.author_id NOT IN (SELECT author_id FROM DirectCoauthors) -- NOT direct co-author
GROUP BY 
    coco_a.name
ORDER BY 
    "NumberOfCollaborations" DESC
LIMIT 15;