-- =======================================================================
-- RDBMS vs GDBMS Benchmark: PostgreSQL Queries
--
-- BENCHMARK WORKFLOW:
-- STEP 1: Run QUERY 1, 2, and 3 below. Record the Execution Times.
--         (This tests the baseline performance with sequential scans).
-- STEP 2: Open and execute the separate 'create_indexes.sql' script.
-- STEP 3: Re-run QUERY 1, 2, and 3. Record the new Execution Times.
--         (This tests the optimized relational performance).
-- =======================================================================


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


-- -----------------------------------------------------------------------
-- QUERY 3: Shortest Path 
-- Computes the shortest path (degrees of separation) between two specific 
-- authors ('Sergey Levine' and 'Xi Chen'). It uses a Recursive CTE 
-- (Breadth-First Search) bounded to a maximum depth of 5 hops.
-- -----------------------------------------------------------------------
WITH RECURSIVE bfs_path(current_author, path_length, visited) AS (
    -- Base case: the starting (Author) node
    SELECT
        author_id,
        0 AS path_length,
        ARRAY[author_id] AS visited
    FROM authors
    WHERE name = 'Sergey Levine'

    UNION ALL

    -- Recursive step: a hop Author -> Paper -> Author equals 1 degree of separation
    SELECT
        w2.author_id,
        bfs.path_length + 1,
        bfs.visited || w2.author_id
    FROM bfs_path bfs
    JOIN wrote w1 ON bfs.current_author = w1.author_id
    JOIN wrote w2 ON w1.paper_id = w2.paper_id
    -- We set a limit of 5 hops between authors (which exactly correspond to 10 Node-Edge hops in Neo4j)
    WHERE bfs.path_length < 5 
      -- Avoid cycles so we don't travel infinitely
      AND w2.author_id != ALL(bfs.visited) 
)
SELECT 
    bfs.visited AS "AuthorPathArray", 
    path_length AS "SeparationDegrees"
FROM bfs_path bfs
JOIN authors a ON bfs.current_author = a.author_id
WHERE a.name = 'Xi Chen'
ORDER BY path_length ASC
LIMIT 1;