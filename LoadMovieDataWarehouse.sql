
--Create a Movies database 
IF EXISTS (SELECT * FROM sys.databases WHERE NAME = 'MoviesDB')
   DROP DATABASE MoviesDB;
GO

CREATE DATABASE MoviesDB
GO

USE MoviesDB
GO

--Create MoviesStaging

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'MoviesStaging') AND type in (N'U'))
DROP TABLE MoviesStaging
GO

CREATE TABLE MoviesStaging (
	MOVIEID INT,
	movie_title varchar(200),
	genres varchar(200)
)

--Load the MoviesStaging Table from the csv file
bulk insert MoviesStaging
from 'C:\Data\Final Project\movies.csv'
with (format = 'csv',
	  firstrow = 2)


--Create MovieRatings Table 

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'MovieRatings') AND type in (N'U'))
DROP TABLE MovieRatings
GO

CREATE TABLE MovieRatings (
	USERID INT,
	MOVIEID INT,
	rating FLOAT,
	timestamp varchar(200)
)

--Load the MoviesStaging Table from the csv file
bulk insert MovieRatings
from 'C:\Data\Final Project\ratings.csv'
with (format = 'csv',
	  firstrow = 2)

select * from MovieRatings


--Create MovieTags Table 

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'MovieTags') AND type in (N'U'))
DROP TABLE MovieTags
GO

CREATE TABLE MovieTags (
	USERID INT,
	MOVIEID INT,
	tag varchar(500),
	timestamp BIGINT
)

--Load the MoviesTags Table from the csv file
bulk insert MovieTags
from 'C:\Data\Final Project\tags.csv'
with (format = 'csv',
	  firstrow = 2)


select * from MovieTags

--DIMENSION TABLES--

--dimMovie
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimMovie') AND type in (N'U'))
DROP TABLE dimMovie
GO

CREATE TABLE dimMovie (
    MovieID INT PRIMARY KEY,
    Title VARCHAR(200)
);

INSERT INTO dimMovie (MovieID, Title)
SELECT DISTINCT MOVIEID, movie_title
FROM MoviesStaging;

--dimUser
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimUser') AND type in (N'U'))
DROP TABLE dimUser
GO

CREATE TABLE dimUser (
    userID INT PRIMARY KEY 
);

INSERT INTO dimUser (UserID)
SELECT DISTINCT USERID FROM MovieRatings;

--dimGenre
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimGenre') AND type in (N'U'))
DROP TABLE dimGenre
GO

CREATE TABLE dimGenre (
    GenreID INT IDENTITY(1,1) PRIMARY KEY,
    GenreName VARCHAR(100)
);

INSERT INTO dimGenre (GenreName)
SELECT DISTINCT value
FROM MoviesStaging
CROSS APPLY STRING_SPLIT(genres, '|')
WHERE genres IS NOT NULL;

--dimTag
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimTag') AND type in (N'U'))
DROP TABLE dimTag
GO

CREATE TABLE dimTag (
    TagID INT IDENTITY(1,1) PRIMARY KEY,
    TagName VARCHAR(500)
);

INSERT INTO dimTag (TagName)
SELECT DISTINCT LTRIM(RTRIM(LOWER(tag)))
FROM MovieTags
WHERE tag IS NOT NULL;

--dimDate
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimDate') AND type in (N'U'))
DROP TABLE dimDate
GO

CREATE TABLE dimDate (
    DateKey INT PRIMARY KEY,       -- YYYYMMDD
    FullDate DATE,
    Year INT,
    Quarter INT,
    Month INT,
    MonthName VARCHAR(20),
    Day INT,
    DayOfWeek VARCHAR(20)
);

INSERT INTO dimDate
SELECT DISTINCT
    CONVERT(INT, FORMAT(DATEADD(SECOND, CAST(timestamp AS BIGINT), '1970-01-01'), 'yyyyMMdd')) AS DateKey,
    CAST(DATEADD(SECOND, CAST(timestamp AS BIGINT), '1970-01-01') AS DATE) AS FullDate,
    YEAR(DATEADD(SECOND, CAST(timestamp AS BIGINT), '1970-01-01')) AS Year,
    DATEPART(QUARTER, DATEADD(SECOND, CAST(timestamp AS BIGINT), '1970-01-01')) AS Quarter,
    MONTH(DATEADD(SECOND, CAST(timestamp AS BIGINT), '1970-01-01')) AS Month,
    DATENAME(MONTH, DATEADD(SECOND, CAST(timestamp AS BIGINT), '1970-01-01')) AS MonthName,
    DAY(DATEADD(SECOND, CAST(timestamp AS BIGINT), '1970-01-01')) AS Day,
    DATENAME(WEEKDAY, DATEADD(SECOND, CAST(timestamp AS BIGINT), '1970-01-01')) AS DayOfWeek
FROM MovieRatings;


--dimMovieidx 
CREATE UNIQUE INDEX idx_dimMovie_MovieID
ON dimMovie(MovieID);

--dimUseridx
CREATE UNIQUE INDEX idx_dimUser_UserID
ON dimUser(UserID);

--dimGenreidx
CREATE INDEX idx_dimGenre_GenreName
ON dimGenre(GenreName);

--dimTagidx
CREATE INDEX idx_dimTag_TagName
ON dimTag(TagName);

--MovieGenre Bridge Table
IF EXISTS (SELECT * FROM sys.objects 
           WHERE object_id = OBJECT_ID(N'MovieGenreBridge') 
           AND type in (N'U'))
DROP TABLE MovieGenreBridge
GO

CREATE TABLE MovieGenreBridge (
    MovieID INT NOT NULL,
    GenreID INT NOT NULL,

    PRIMARY KEY (MovieID, GenreID),

    FOREIGN KEY (MovieID) REFERENCES dimMovie(MovieID),
    FOREIGN KEY (GenreID) REFERENCES dimGenre(GenreID)
)
GO


--Populate MovieGenreBridge
INSERT INTO MovieGenreBridge (MovieID, GenreID)
SELECT DISTINCT
    m.MOVIEID,
    g.GenreID
FROM MoviesStaging m
CROSS APPLY STRING_SPLIT(m.genres, '|') s
JOIN dimGenre g
    ON s.value = g.GenreName
WHERE m.genres IS NOT NULL;




--Fact Table
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'factMovieRatings') AND type in (N'U'))
DROP TABLE factMovieRatings
GO

CREATE TABLE factMovieRatings (
    FactID INT IDENTITY(1,1) PRIMARY KEY,

    UserID INT NOT NULL,
    MovieID INT NOT NULL,

    Rating FLOAT NOT NULL,
    RatingTimestamp BIGINT,

    PrimaryGenreID INT NULL,
    TagID INT NULL,

    FOREIGN KEY (UserID) REFERENCES dimUser(UserID),
    FOREIGN KEY (MovieID) REFERENCES dimMovie(MovieID),
    FOREIGN KEY (PrimaryGenreID) REFERENCES dimGenre(GenreID),
    FOREIGN KEY (TagID) REFERENCES dimTag(TagID)
);

INSERT INTO factMovieRatings (
    UserID,
    MovieID,
    Rating,
    RatingTimestamp,
    PrimaryGenreID,
    TagID
)
SELECT 
    r.USERID,
    r.MOVIEID,
    CAST(r.rating AS FLOAT),
    r.timestamp,
    g.GenreID,
    t.TagID

FROM MovieRatings r

-- Primary Genre (precomputed logic, NOT string splitting here)
LEFT JOIN MovieGenreBridge b
    ON r.MOVIEID = b.MovieID

LEFT JOIN dimGenre g
    ON b.GenreID = g.GenreID

-- Tag mapping (cleaned once in dimension)
LEFT JOIN MovieTags mt
    ON r.USERID = mt.UserID
   AND r.MOVIEID = mt.MOVIEID

LEFT JOIN dimTag t
    ON LOWER(LTRIM(RTRIM(mt.tag))) = t.tagName

WHERE r.USERID IS NOT NULL
  AND r.MOVIEID IS NOT NULL
  AND r.rating IS NOT NULL;

--fact table indexes 
CREATE INDEX idx_fact_MovieID ON factMovieRatings(MovieID);
CREATE INDEX idx_fact_Genre_Rating ON factMovieRatings(PrimaryGenreID, Rating);

select * from factMovieRatings

ALTER TABLE factMovieRatings
ADD DateKey INT;

UPDATE f
SET DateKey = CONVERT(INT, FORMAT(
    DATEADD(SECOND, f.RatingTimestamp, '1970-01-01'),
    'yyyyMMdd'
))
FROM factMovieRatings f;

ALTER TABLE factMovieRatings
ADD CONSTRAINT FK_fact_Date
FOREIGN KEY (DateKey) REFERENCES dimDate(DateKey);



/* ANALYSIS QUERIES */

--top 5 most popular movie genres
select top (5)
    count(DISTINCT f.FactID) as num_ratings,
    g.GenreName
from factMovieRatings AS f
INNER JOIN dimGenre g on f.PrimaryGenreID = g.GenreID
group by g.GenreName 
order by num_ratings desc;

--top 5 most popular tags
select top (5)
    count(DISTINCT f.FactID) as tag_count,
    t.tagName
from factMovieRatings AS f
INNER JOIN dimTag t on f.tagID = t.tagID
group by t.tagName
order by tag_count desc;

--Genres producing the highest rated movies
SELECT 
    g.GenreName,
    AVG(f.Rating) AS AvgRating,
    COUNT(DISTINCT f.MovieID) AS NumMovies
FROM factMovieRatings f
JOIN dimGenre g 
    ON f.PrimaryGenreID = g.GenreID
GROUP BY g.GenreName
HAVING COUNT(DISTINCT f.MovieID) > 50
ORDER BY AvgRating DESC;


--genres producing the lowest rated movies 
SELECT 
    g.GenreName,
    AVG(f.Rating) AS AvgRating,
    COUNT(DISTINCT f.MovieID) AS NumMovies
FROM factMovieRatings f
JOIN dimGenre g 
    ON f.PrimaryGenreID = g.GenreID
GROUP BY g.GenreName
HAVING COUNT(DISTINCT f.MovieID) > 50
ORDER BY AvgRating ASC;

--what tags are associated with highly rated movies
SELECT TOP 10
    t.TagName,
    AVG(f.Rating) AS AvgRating,
    COUNT(DISTINCT f.FactID) AS UsageCount
FROM factMovieRatings f
JOIN dimTag t 
    ON f.TagID = t.TagID
GROUP BY t.TagName
HAVING COUNT(DISTINCT f.FactID) > 50
ORDER BY AvgRating DESC;

--genre popularity over time
SELECT 
    d.Year,
    g.GenreName,
    COUNT(*) AS NumRatings
FROM factMovieRatings f
JOIN dimDate d
    ON f.DateKey = d.DateKey
JOIN dimGenre g
    ON f.PrimaryGenreID = g.GenreID
GROUP BY d.Year, g.GenreName
ORDER BY d.Year, NumRatings DESC;

--monthly engagement trends
SELECT 
    d.Year,
    d.Month,
    COUNT(DISTINCT f.UserID) AS ActiveUsers,
    COUNT(*) AS TotalRatings
FROM factMovieRatings f
JOIN dimDate d
    ON f.DateKey = d.DateKey
GROUP BY d.Year, d.Month
ORDER BY d.Year, d.Month;


--peak movie rating periods
SELECT 
    d.Year,
    AVG(f.Rating) AS AvgRating,
    COUNT(*) AS NumRatings
FROM factMovieRatings f
JOIN dimDate d
    ON f.DateKey = d.DateKey
GROUP BY d.Year
ORDER BY AvgRating DESC;







