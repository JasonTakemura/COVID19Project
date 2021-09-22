--COVID-19 Data Exploration
--Skills Used: Joins, Temp Tables, CTEs, Views, Converting Data Types, Windows Functions


SELECT * FROM CovidDeaths
WHERE location LIKE '%states'
order by 3,4


SELECT * FROM CovidVaccinations
WHERE location LIKE '%states'
ORDER BY 3,4 


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2


--Total Cases VS Total Deaths, by country
--What is the chance of death after contracting COVID-19 in a certain country?

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as mortality_rate
FROM CovidDeaths
WHERE location LIKE '%states'
ORDER BY 1,2


--Total Cases VS Population, by country
--What percentage of people have COVID-19 in a certain country?

SELECT location, date, total_cases, population, (total_cases/population) * 100 as COVID_percent
FROM CovidDeaths
WHERE location LIKE '%states'
ORDER BY 1,2


--What countries have the highest percentage of their population affected by COVID-19?

SELECT location, MAX(total_cases) as total_cases, population, (MAX(total_cases/population))*100 as COVID_percent
FROM CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC


--What countries have suffered the most deaths due to COVID-19?

SELECT location, MAX(cast(Total_Deaths as int)) as total_deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC


--What continents have suffered the most deaths due to COVID-19?

SELECT location, MAX(cast(total_deaths as int)) as total_deaths
FROM CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union')
GROUP BY location
ORDER BY 2 DESC


--Global Numbers

SELECT SUM(new_cases) as total_deaths, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as mortality_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--How many people are fully vaccinated in comparison to population?

SELECT d.location, d.date, d.population, v.people_fully_vaccinated, (v.people_fully_vaccinated/d.population)* 100 as vaccinated_percentage
FROM CovidDeaths d
JOIN CovidVaccinations v
	on d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
AND d.location LIKE '%states'


--Finding percentage of population that has recieved the first dose of the vaccine
--Parameters for Temp Table and CTE usage

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(cast(v.new_vaccinations as int))
OVER (PARTITION BY d.location ORDER BY d.location, d.date) as vaccination_counter, 
(vaccination_counter/population)*100
FROM CovidDeaths d
JOIN CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3 


--Using Temp Table to use vaccination_counter

DROP TABLE IF EXISTS #vaccination_percentage
CREATE TABLE #vaccination_percentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
vaccination_counter numeric,
people_fully_vaccinated numeric,
)

INSERT INTO #vaccination_percentage

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(numeric, v.new_vaccinations))
OVER (PARTITION BY d.location ORDER BY d.location, d.date) as vaccination_counter, CONVERT(numeric, v.people_fully_vaccinated)
FROM CovidDeaths d
JOIN CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL

--Using the newly made temp table to find the number of people who have received at least one dose of the vaccine

SELECT continent, location, date, population, new_vaccinations, vaccination_counter, ((vaccination_counter - people_fully_vaccinated)/population)*100 as vaccinated_percentage
FROM #vaccination_percentage
WHERE location LIKE '%states'


--Using CTE method for using vaccination_counter

WITH vaccination_percentage_CTE (continent, location, date, population, new_vaccinations, vaccination_counter, people_fully_vaccinated)
as
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(cast(v.new_vaccinations as int))
OVER (PARTITION BY d.location ORDER BY d.location, d.date) as vaccination_counter, people_fully_vaccinated
FROM CovidDeaths d
JOIN CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
)

SELECT continent, location, date, population, new_vaccinations, vaccination_counter, ((vaccination_counter - people_fully_vaccinated)/population)*100 as vaccinated_percentage
FROM vaccination_percentage_CTE
WHERE location LIKE '%states'

--creating view for data storage

CREATE VIEW vaccinated_percentage as

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(numeric, v.new_vaccinations))
OVER (PARTITION BY d.location ORDER BY d.location, d.date) as vaccination_counter, v.people_fully_vaccinated
FROM CovidDeaths d
JOIN CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL

--Querying off of the previously created view

SELECT continent, location, date, population, new_vaccinations, vaccination_counter, ((vaccination_counter - people_fully_vaccinated)/population) * 100 as vaccinated_population_percentage
FROM vaccinated_percentage
WHERE location LIKE '%states'