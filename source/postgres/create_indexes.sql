-- =======================================================================
-- INDEX CREATION 
-- (Execute this script AFTER your first benchmark phase without indexes)
-- =======================================================================

-- PostgreSQL automatically indexes Primary Keys (like author_id and paper_id),
-- but it does NOT index Foreign Keys or standard columns by default. 
-- We must create these manually to ensure a fair comparison with Neo4j.

-- 1. Index for WHERE filters on Author names (Crucial for Query 2 and 3)
CREATE INDEX idx_authors_name ON authors(name);

-- 2. Index for WHERE filters on Paper publication year (Crucial for Query 1)
CREATE INDEX idx_papers_year ON papers(year);

-- 3. Index for the target column of the Foreign Key in 'wrote' table.
-- (The composite Primary Key automatically indexes 'author_id' as the leading 
-- column, but we desperately need an index on 'paper_id' to speed up the 
-- Author -> Paper -> Author hops in Query 2 and 3).
CREATE INDEX idx_wrote_paper_id ON wrote(paper_id);

-- Note: The paper_categories(paper_id, category_name) PK already indexes 
-- paper_id as the leading column, so no additional index is strictly needed there.