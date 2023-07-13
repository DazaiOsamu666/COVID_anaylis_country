--DATA SOURCE: https://ourworldindata.org/covid-deaths

SELECT Location,date,total_cases,new_cases,total_deaths,population
FROM CovidDeaths
Order by 1,2

--Total cases vs Total deaths
--chances of dying from covid in India by 5 Jul 2023
SELECT Location,date,total_cases,total_deaths,(CAST(total_deaths AS numeric)/CAST(total_cases AS numeric))*100 as DeathPercentage
FROM CovidDeaths
Where location = 'India' AND continent is not NULL
Order by 1,2 

-- total cases vs population
SELECT Location,date,total_cases,population,(CAST(total_cases AS int)/population)*100 as InfectionPercentage
FROM CovidDeaths
Where location = 'India' AND continent is not NULL
Order by 1,2 


--Highest Infection rate to population
SELECT Location,population,MAX(CAST(total_cases AS int)) as HighestInfectionCount,MAX(CAST(total_cases AS int)/population)*100 as MaxInfectionPercentage
FROM CovidDeaths 
Where continent is not NULL
Group by population,location
Order by MaxInfectionPercentage desc

--Highest death rate to population
SELECT Location,MAX(CAST(total_deaths AS int)) as HighestDeathCount
FROM CovidDeaths 
Where continent is not NULL
Group by location
Order by HighestDeathCount desc


--death rate by geographical classification
SELECT location,MAX(CAST(total_deaths AS int)) as HighestDeathCount
FROM CovidDeaths 
Where continent is NULL
Group by location
Order by HighestDeathCount desc

--global deaths
SELECT date,SUM(new_cases) as 'Total Cases' ,SUM(cast(new_deaths as int)) as 'Total Deaths',
CASE
	WHEN SUM(new_cases) = 0
	THEN Null
	ELSE SUM(cast(new_deaths as int))/SUM(new_cases)*100 
END as GlobalDeathPercentage
FROM CovidDeaths
Where continent is not NULL
group  by date
Order by SUM(new_cases) desc



SELECT * 
FROM CovidDeaths CD
INNER JOIN CovidVacinations CV
	ON CD.location = CV.location
	AND CD.date = CV.date


--CTE VaccinatedPeople
WITH PopvsVac (Continent,Location,Date,Population,NewVacination,RollingVaccinatedPeople)
AS 
(
SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations as numeric)) OVER (PARTITION BY CD.location ORDER BY CD.location,CD.date) as RollingVaccinatedPeople
FROM CovidDeaths CD
INNER JOIN CovidVacinations CV
	ON CD.location = CV.location
	AND CD.date = CV.date
Where CD.continent is not NULL
)


SELECT * ,(RollingVaccinatedPeople/Population)*100 as Pop_percent_vacc
FROM PopvsVac

--Temp table
DROP TABLE if exists #PercentagePeopleVaccinated
Create Table #PercentagePeopleVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RolllingPeopleVaccinated numeric
)

INSERT INTO #PercentagePeopleVaccinated
SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations as numeric)) OVER (PARTITION BY CD.location ORDER BY CD.location,CD.date) as RollingVaccinatedPeople
FROM CovidDeaths CD
INNER JOIN CovidVacinations CV
	ON CD.location = CV.location
	AND CD.date = CV.date
Where CD.continent is not NULL

SELECT *,(RolllingPeopleVaccinated/Population)*100
FROM #PercentagePeopleVaccinated

--Create View
CREATE VIEW PercentagePeopleVaccinated as 
SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations as numeric)) OVER (PARTITION BY CD.location ORDER BY CD.location,CD.date) as RollingVaccinatedPeople
FROM CovidDeaths CD
INNER JOIN CovidVacinations CV
	ON CD.location = CV.location
	AND CD.date = CV.date
Where CD.continent is not NULL
