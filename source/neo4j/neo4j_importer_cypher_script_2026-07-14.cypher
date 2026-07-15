// NOTE: The following script syntax is valid for database version 5.0 and above.

:param {
  // Define the file path root and the individual file names required for loading.
  // https://neo4j.com/docs/operations-manual/current/configuration/file-locations/
  file_path_root: 'file:///', // Change this to the folder your script can access the files at.
  file_0: 'authors.csv',
  file_1: 'papers.csv',
  file_2: 'paper_categories.csv',
  file_3: 'wrote.csv'
};

// CONSTRAINT creation
// -------------------
//
// Create key and uniqueness constraints for node labels and relationship types. This ensures ID property uniqueness and prevents duplicate entries from being introduced.
//
CREATE CONSTRAINT `author_id_Author_key` IF NOT EXISTS
FOR (n: `Author`)
REQUIRE (n.`author_id`) IS NODE KEY;
CREATE CONSTRAINT `paper_id_Paper_key` IF NOT EXISTS
FOR (n: `Paper`)
REQUIRE (n.`paper_id`) IS NODE KEY;
CREATE CONSTRAINT `category_Category_key` IF NOT EXISTS
FOR (n: `Category`)
REQUIRE (n.`category`) IS NODE KEY;

:param {
  idsToSkip: [],
  bracketPairs: [["{","}"],["<",">"],["[","]"],["(",")"]]
};

// NODE load
// ---------
//
// Load nodes in batches, one node label at a time. Nodes will be created using a MERGE statement to ensure a node with the same label and ID property remains unique. Pre-existing nodes found by a MERGE statement will have their other properties set to the latest values encountered in a load file.
//
// NOTE: Any nodes with IDs in the 'idsToSkip' list parameter will not be loaded.
LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row
WHERE NOT row.`author_id` IN $idsToSkip AND NOT row.`author_id` IS NULL
CALL (row) {
  MERGE (n: `Author` { `author_id`: row.`author_id` })
  SET n.`author_id` = row.`author_id`
  SET n.`name` = row.`name`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_1) AS row
WITH row
WHERE NOT row.`paper_id` IN $idsToSkip AND NOT row.`paper_id` IS NULL
CALL (row) {
  MERGE (n: `Paper` { `paper_id`: row.`paper_id` })
  SET n.`paper_id` = row.`paper_id`
  SET n.`title` = row.`title`
  SET n.`year` = toInteger(trim(row.`year`))
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_2) AS row
WITH row
WHERE NOT row.`category` IN $idsToSkip AND NOT row.`category` IS NULL
CALL (row) {
  MERGE (n: `Category` { `category`: row.`category` })
  SET n.`category` = row.`category`
} IN TRANSACTIONS OF 10000 ROWS;


// RELATIONSHIP load
// -----------------
//
// Load relationships in batches, one relationship type at a time. Relationships are created using a MERGE statement, meaning only one relationship of a given type will ever be created between a pair of nodes.
LOAD CSV WITH HEADERS FROM ($file_path_root + $file_3) AS row
WITH row 
CALL (row) {
  MATCH (source: `Author` { `author_id`: row.`author_id` })
  MATCH (target: `Paper` { `paper_id`: row.`paper_id` })
  MERGE (source)-[r: `WROTE`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_2) AS row
WITH row 
CALL (row) {
  MATCH (source: `Paper` { `paper_id`: row.`paper_id` })
  MATCH (target: `Category` { `category`: row.`category` })
  MERGE (source)-[r: `BELONGS_TO`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;
