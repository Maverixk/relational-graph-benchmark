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