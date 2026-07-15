import pandas as pd
from sqlalchemy import create_engine

# Configuration
DB_URL = 'postgresql://your_password:postgres@localhost:5432/relational_graph_benchmark'
engine = create_engine(DB_URL)

def load_data():
    files = {
        'authors': 'dataset/authors.csv',
        'papers': 'dataset/papers.csv',
        'paper_categories': 'dataset/paper_categories.csv',
        'wrote': 'dataset/wrote.csv'
    }

    print("--- Starting database population ---")

    # 1. Load Authors
    print("\nLoading authors...")
    df_authors = pd.read_csv(files['authors'], dtype=str).dropna(subset=['author_id'])
    orig_len = len(df_authors)
    df_authors = df_authors.drop_duplicates(subset=['author_id'])
    print(f" -> Kept {len(df_authors)} authors (dropped {orig_len - len(df_authors)} duplicates).")
    df_authors.to_sql('authors', engine, if_exists='append', index=False, method='multi')
    valid_authors = set(df_authors['author_id']) 

    # 2. Load Papers
    print("\nLoading papers...")
    df_papers = pd.read_csv(files['papers'], dtype={'paper_id': str, 'title': str, 'year': float}).dropna(subset=['paper_id'])
    orig_len = len(df_papers)
    df_papers = df_papers.drop_duplicates(subset=['paper_id'])
    print(f" -> Kept {len(df_papers)} papers (dropped {orig_len - len(df_papers)} duplicates).")
    df_papers.to_sql('papers', engine, if_exists='append', index=False, method='multi')
    valid_papers = set(df_papers['paper_id']) 

    # 3. Load Categories
    print("\nLoading categories...")
    df_cat = pd.read_csv(files['paper_categories'], dtype=str)
    categories = df_cat[['category']].drop_duplicates().dropna()
    categories.columns = ['name']
    print(f" -> Found {len(categories)} unique categories.")
    categories.to_sql('categories', engine, if_exists='append', index=False)
    valid_categories = set(categories['name'])

    # 4. Load Relations
    print("\nLoading relations (this might take a moment)...")
    
    # Process WROTE
    df_wrote = pd.read_csv(files['wrote'], dtype=str).dropna()
    orig_len = len(df_wrote)
    df_wrote = df_wrote[df_wrote['paper_id'].isin(valid_papers) & df_wrote['author_id'].isin(valid_authors)]
    orphans = orig_len - len(df_wrote)
    orig_len_before_dedup = len(df_wrote)
    df_wrote = df_wrote.drop_duplicates()
    dupes = orig_len_before_dedup - len(df_wrote)
    print(f" -> WROTE relation: dropped {orphans} orphans and {dupes} duplicates. Inserting {len(df_wrote)} valid records.")
    df_wrote.to_sql('wrote', engine, if_exists='append', index=False)
    
    # Process PAPER_CATEGORIES
    df_pc = pd.read_csv(files['paper_categories'], dtype=str).dropna()
    df_pc.columns = ['paper_id', 'category_name']
    orig_len = len(df_pc)
    df_pc = df_pc[df_pc['paper_id'].isin(valid_papers) & df_pc['category_name'].isin(valid_categories)]
    orphans = orig_len - len(df_pc)
    orig_len_before_dedup = len(df_pc)
    df_pc = df_pc.drop_duplicates()
    dupes = orig_len_before_dedup - len(df_pc)
    print(f" -> PAPER_CATEGORIES relation: dropped {orphans} orphans and {dupes} duplicates. Inserting {len(df_pc)} valid records.")
    df_pc.to_sql('paper_categories', engine, if_exists='append', index=False)
    
    print("\n--- Data import completed successfully! ---")

if __name__ == "__main__":
    load_data()