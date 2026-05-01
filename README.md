# 📊 Movie Ratings Data Warehouse & Analysis

This project uses the MovieLens dataset to examine how movie characteristics influence audience engagement and rating patterns. The focus is on identifying which movie attributes, particularly genres and tags, are associated with popularity and strong audience reception.

The project follows a full data warehousing and analytics workflow, beginning with raw CSV ingestion and ending with exploratory visualizations and trend analysis.

## Project Overview

The dataset includes movie metadata, user ratings, and user-generated tags. These files were loaded into SQL Server staging tables and transformed into a structured data warehouse for analysis.

A star schema was implemented to support reporting and trend analysis, including:

- **Dimension Tables**
  - `dimMovie`
  - `dimUser`
  - `dimGenre`
  - `dimTag`
  - `dimDate`

- **Fact Table**
  - `factMovieRatings`

Data preparation included:
- Loading raw CSV files into staging tables
- Cleaning and standardizing tag values
- Splitting multi value genre fields
- Building bridge relationships between movies and genres
- Creating the fact table for analytical queries
- Running SQL-based aggregation and time-series analysis

## Research Questions

This project explores the following questions:

- Which movie genres are the most popular?
- Which genres receive the highest and lowest ratings?
- Which tags are most frequently associated with movies?
- What tags appear most often in highly rated films?
- How has audience engagement changed over time?
- Which time periods show the highest rating activity?

## Key Findings

The analysis revealed several notable patterns:

- **Drama** was the most consistently popular genre by rating volume.
- **Film-Noir** and **War** had the highest average ratings among genres with substantial movie counts.
- Tags such as **"sci-fi"** appeared most frequently, indicating strong audience discussion around those films.
- Positive sentiment tags were more commonly associated with highly rated movies.
- Rating activity increased significantly over time, peaking around **2016**, with another spike in **2020**.

## Visualizations

Analysis results were visualized in Python using Google Colab, including:

- Bar charts for genre and tag popularity
- Rating comparisons across genres
- Time-series plots for audience activity
- Scatter plots showing yearly rating behavior

## Technologies Used

- **SQL Server** – ETL, warehouse design, and querying  
- **Python** – Data handling and visualization  
- **Pandas** – Data processing  
- **Matplotlib** – Chart generation  
- **Google Colab** – Analysis and notebook execution

## Repository Structure

```bash
/sql        # Database creation scripts, ETL logic, and analysis queries
/data       # Source files and exported query results
/notebooks  # Colab notebooks for analysis and visualization
/outputs    # Generated plots and supporting files
```

## Purpose

This project demonstrates how data warehousing techniques can be used to transform raw entertainment data into structured analytical insights. It combines database design, SQL querying, and visualization to better understand movie popularity, audience behavior, and rating trends.
