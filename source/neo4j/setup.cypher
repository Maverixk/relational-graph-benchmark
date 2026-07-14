// =========================================================================
// 1. CREATION OF UNICITY CONSTRAINTS AND INDEXES
// =========================================================================
// Note: constrints will automatically creates indexes on primary keys. 
// This is crucial to guarantee that the next matches are instantaneous.

CREATE CONSTRAINT unique_paper_id IF NOT EXISTS
FOR (p:Paper) REQUIRE p.id IS NODE KEY;

CREATE CONSTRAINT unique_author_id IF NOT EXISTS
FOR (a:Author) REQUIRE a.id IS NODE KEY;

CREATE CONSTRAINT unique_category_name IF NOT EXISTS
FOR (c:Category) REQUIRE c.name IS NODE KEY;

// =========================================================================
// 2. NODES IMPORT (In transactions of 10.000 rows)
// =========================================================================

// Papers import
:auto LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/Maverixk/relational-graph-benchmark/main/dataset/papers.csv' AS row
CALL {
    WITH row
    CREATE (:Paper {
        id: row.paper_id,
        title: row.title,
        year: toInteger(row.year)
    })
} IN TRANSACTIONS OF 10000 ROWS;

// Authors import
:auto LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/Maverixk/relational-graph-benchmark/main/dataset/authors.csv' AS row
CALL {
    WITH row
    CREATE (:Author {
        id: row.author_id,
        name: row.name
    })
} IN TRANSACTIONS OF 10000 ROWS;

// Categories import (MERGE is used to avoid duplicates)
:auto LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/Maverixk/relational-graph-benchmark/main/dataset/paper_categories.csv' AS row
CALL {
    WITH row
    MERGE (:Category {name: row.category})
} IN TRANSACTIONS OF 5000 ROWS;

// =========================================================================
// 3. RELATIONS IMPORT (Edges)
// =========================================================================

// WROTE relation (Author -> Paper)
:auto LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/Maverixk/relational-graph-benchmark/main/dataset/wrote.csv' AS row
CALL {
    WITH row
    MATCH (a:Author {id: row.author_id})
    MATCH (p:Paper {id: row.paper_id})
    CREATE (a)-[:WROTE]->(p)
} IN TRANSACTIONS OF 10000 ROWS;

// BELONGS_TO relation (Paper -> Category)
:auto LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/Maverixk/relational-graph-benchmark/main/dataset/paper_categories.csv' AS row
CALL {
    WITH row
    MATCH (p:Paper {id: row.paper_id})
    MATCH (c:Category {name: row.category})
    CREATE (p)-[:BELONGS_TO]->(c)
} IN TRANSACTIONS OF 10000 ROWS;
