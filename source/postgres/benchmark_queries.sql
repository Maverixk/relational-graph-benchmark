-- =======================================================================
-- SCENARIO 1: AGGREGATION
-- =======================================================================
SELECT 
    a.name AS "Author", 
    COUNT(DISTINCT p.paper_id) AS "NumberOfPublications"
FROM authors a
JOIN wrote w ON a.author_id = w.author_id
JOIN papers p ON w.paper_id = p.paper_id
JOIN paper_categories pc ON p.paper_id = pc.paper_id
WHERE p.year >= 2014 AND p.year <= 2023
GROUP BY a.author_id, a.name
ORDER BY "NumberOfPublications" DESC
LIMIT 15;


-- =======================================================================
-- SCENARIO 2: DEEP TRAVERSAL
-- =======================================================================
WITH Target AS (
    SELECT author_id FROM authors WHERE name = 'Sergey Levine'
),
DirectCoauthors AS (
    SELECT DISTINCT w2.author_id
    FROM Target t
    JOIN wrote w1 ON t.author_id = w1.author_id
    JOIN wrote w2 ON w1.paper_id = w2.paper_id
    WHERE w2.author_id != t.author_id
),
SecondDegreeCollaborations AS (
    SELECT dc.author_id AS first_degree_id, w2.paper_id, w2.author_id AS second_degree_id
    FROM DirectCoauthors dc
    JOIN wrote w1 ON dc.author_id = w1.author_id
    JOIN wrote w2 ON w1.paper_id = w2.paper_id
    WHERE w2.author_id != dc.author_id
)
SELECT 
    a.name AS "SecondDegreeConnection", 
    COUNT(DISTINCT sdc.paper_id) AS "NumberOfCollaborations"
FROM SecondDegreeCollaborations sdc
JOIN authors a ON sdc.second_degree_id = a.author_id
WHERE sdc.second_degree_id NOT IN (SELECT author_id FROM Target) 
  AND sdc.second_degree_id NOT IN (SELECT author_id FROM DirectCoauthors)
GROUP BY sdc.second_degree_id, a.name
ORDER BY "NumberOfCollaborations" DESC
LIMIT 15;


-- =======================================================================
-- SCENARIO 3: SHORTEST PATH
-- =======================================================================
WITH RECURSIVE bfs_path(current_author, path_length, visited) AS (
    SELECT
        author_id,
        0 AS path_length,
        ARRAY[author_id] AS visited
    FROM authors
    WHERE name = 'Sergey Levine'

    UNION ALL

    SELECT
        w2.author_id,
        bfs.path_length + 1,
        bfs.visited || w2.author_id
    FROM bfs_path bfs
    JOIN wrote w1 ON bfs.current_author = w1.author_id
    JOIN wrote w2 ON w1.paper_id = w2.paper_id
    WHERE bfs.path_length < 5 
      AND w2.author_id != ALL(bfs.visited) 
)
SELECT path_length AS "SeparationDegrees"
FROM bfs_path bfs
JOIN authors a ON bfs.current_author = a.author_id
WHERE a.name = 'Xi Chen'
ORDER BY path_length ASC
LIMIT 1;