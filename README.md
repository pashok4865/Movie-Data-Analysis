📊 Movie Ratings Data Warehouse & Analysis

This project builds a complete data warehouse solution using the MovieLens dataset to analyze how movie characteristics influence audience behavior and rating patterns. The goal is to identify which movie attributes (such as genres and tags) are associated with higher popularity and better ratings.

The workflow follows a full data engineering and analytics pipeline:

Data Collection & Staging: Raw CSV files (movies, ratings, tags) are loaded into SQL Server staging tables.
Data Warehouse Design: A star schema is implemented with dimension tables (dimMovie, dimUser, dimGenre, dimTag, dimDate) and a central fact table (factMovieRatings).
Data Transformation: Data is cleaned, normalized, and structured using SQL (including handling multi-valued genres and tag standardization).
Analysis: SQL queries are used to explore trends such as:
Most popular genres and tags
Highest and lowest rated genres
Tags associated with highly rated movies
Time-based trends in ratings and user engagement
Visualization: Results are visualized using Python (Google Colab) through bar charts, line charts, and scatter plots.

🔍 Key Insights
Certain genres (e.g., Drama, Film-Noir) consistently receive higher average ratings.
Popular tags (e.g., “sci-fi”) highlight audience interest and engagement trends.
Viewer activity and rating volume vary significantly over time, with noticeable peaks in recent years.
🛠️ Technologies Used
SQL Server (data warehousing, ETL, querying)
Python (Pandas, Matplotlib for visualization)
Google Colab (analysis environment)

📁 Repository Structure
/sql – Database creation, ETL scripts, and analysis queries
/data – Source CSV files (or references to dataset)
/notebooks – Colab notebooks for visualization
/outputs – Generated CSVs and plots
