
SELECT *
FROM PortfolioProject..CovidDeaths$
where continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY 3,4

SELECT location, Date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
where continent is not null
ORDER BY 1,2	

--Looking at total cases vs Total Deaths


SELECT location, Date, total_cases, total_deaths,
    CASE
        WHEN TRY_CAST(total_cases AS float) = 0 THEN NULL  -- Handling division by zero
        ELSE TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float)*100
    END AS death_Percentage
FROM PortfolioProject..CovidDeaths$
where location like '%INDIA%'
and continent is not null
ORDER BY location, Date;

-- Looking at total cases VS Population 
--Shows what persentage of population got covid 

SELECT location, Date, population, total_cases, (total_cases/population)*100 as Percent_population_infected
FROM PortfolioProject..CovidDeaths$
--where location like '%India%'
where continent is not null
ORDER BY location, Date;

-- Looking at countrie with highest infection rate compared to population 

SELECT location, population, MAX(total_cases) AS  Highest_infection_count, MAX((total_cases/population))*100 as Percent_population_infected
FROM PortfolioProject..CovidDeaths$
--where location like '%India%'
where continent is not null
GROUP BY location, population
ORDER BY Percent_population_infected DESC 

-- Showing countris with highest death counts per population

SELECT location, MAX(cast(total_deaths as int)) AS Total_death_count
FROM PortfolioProject..CovidDeaths$
--where location like '%India%'
where continent is not null
GROUP BY location
ORDER BY Total_death_count DESC 
	
	-- Letss brake things down by continents

SELECT continent, MAX(cast(total_deaths as int)) AS Total_death_count
FROM PortfolioProject..CovidDeaths$
--where location like '%states%'
where continent is not null
GROUP BY continent
ORDER BY Total_death_count DESC 

--showing continents with the highest death count per population


SELECT continent, MAX(cast(total_deaths as int)) AS Total_death_count
FROM PortfolioProject..CovidDeaths$
--where location like '%states%'
where continent is not null
GROUP BY continent
ORDER BY Total_death_count DESC 

-- Global numbers '

SELECT 
    SUM(new_cases) AS total_new_cases,
    SUM(CAST(new_deaths AS int)) AS total_new_deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL  -- Handling division by zero
        ELSE SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100
    END AS death_Percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
--GROUP BY Date
--ORDER BY Date;

-- Looking at total population Vs Vaccination 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS total_vaccinations
	,(total_vaccinations/population)*100
FROM PortfolioProject..CovidDeaths$ dea 
JOIN PortfolioProject..CovidVaccinations$ vac
     ON dea.location = vac.location
     AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;


-- use CTE


WITH Popvsvac(Continent, location, date, Population, new_vaccinations, total_vaccinations, vaccination_percentage)
AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
      SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations,
      (CONVERT(FLOAT, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)) / dea.population) * 100 AS vaccination_percentage
    FROM PortfolioProject..CovidDeaths$ dea 
    JOIN PortfolioProject..CovidVaccinations$ vac
         ON dea.location = vac.location
         AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT Continent, location, date, Population, new_vaccinations, total_vaccinations, vaccination_percentage
FROM Popvsvac;

IF OBJECT_ID('tempdb..#PercentagePopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentagePopulationVaccinated;

CREATE TABLE #PercentagePopulationVaccinated (
    continent NVARCHAR(255),
    location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    new_vaccinations NUMERIC,
    total_vaccinations NUMERIC
)

INSERT INTO #PercentagePopulationVaccinated (continent, location, Date, Population, new_vaccinations, total_vaccinations)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
      SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM PortfolioProject..CovidDeaths$ dea 
JOIN PortfolioProject..CovidVaccinations$ vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *,
    (total_vaccinations / Population) * 100 AS vaccination_percentage
FROM #PercentagePopulationVaccinated;

--creating view to store data for later visulisation

Create view PercentagePopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
      SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM PortfolioProject..CovidDeaths$ dea 
JOIN PortfolioProject..CovidVaccinations$ vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

select*
from PercentagePopulationVaccinated