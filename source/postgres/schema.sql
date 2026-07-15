
-- ## 1. TABLES CREATION (Nodes) ##

-- Table for authors.csv
CREATE TABLE authors (
    author_id TEXT PRIMARY KEY,
    name TEXT NOT NULL
);

-- Table for papers.csv
CREATE TABLE papers (
    paper_id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    year INT
);

-- Table for categories (extracted from paper_categories.csv)
CREATE TABLE categories (
    name TEXT PRIMARY KEY
);


-- ## 2. BRIDGE TABLES CREATION (Edges/Relations) ##


-- Table for wrote.csv (Relation Author -> Paper)
CREATE TABLE wrote (
    author_id TEXT REFERENCES authors(author_id) ON DELETE CASCADE,
    paper_id TEXT REFERENCES papers(paper_id) ON DELETE CASCADE,
    PRIMARY KEY (author_id, paper_id)
);

-- Table for paper_categories.csv (Relation Paper -> Category)
CREATE TABLE paper_categories (
    paper_id TEXT REFERENCES papers(paper_id) ON DELETE CASCADE,
    category_name TEXT REFERENCES categories(name) ON DELETE CASCADE,
    PRIMARY KEY (paper_id, category_name)
);