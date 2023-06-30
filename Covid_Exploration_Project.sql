/****** Script for   ******/
SELECT location
      ,date
      ,total_cases
      ,new_cases
      ,total_deaths
      ,population
 FROM Project.dbo.CovidDeaths
 ORDER BY 1,2

 -- Total Cases vs Total Deaths
 SELECT location,date,total_cases,total_deaths, cast(total_deaths as float)/cast(total_cases as float)*100 as DeathPercentage
 FROM Project.dbo.CovidDeaths
 Where location = 'India'
 ORDER BY 1,2

 -- Total Cases vs Population
 SELECT location,date,population,total_cases,cast(total_cases as float)/population*100 as PercentPopulationIfected
 FROM Project.dbo.CovidDeaths
 Where location = 'India'
 ORDER BY 1,2

  -- Highest infection rate compared to Population
 SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(cast(total_cases as float))/population*100 as PercentPopulationIfected
 FROM Project.dbo.CovidDeaths
 Group by location, population
ORDER BY PercentPopulationIfected Desc

  -- Highest death count per Population
 SELECT location,  MAX(cast(total_deaths as int)) as TotalDeathCount
 FROM Project.dbo.CovidDeaths
 where continent is NOT NULL
 Group by location
ORDER BY TotalDeathCount Desc

--  -- Highest death count per Continent
 SELECT continent,  MAX(cast(total_deaths as int)) as TotalDeathCount
 FROM Project.dbo.CovidDeaths
 where continent is NOT NULL
 Group by continent
ORDER BY TotalDeathCount Desc
 
 -- Global Numbers

 SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
 SUM(new_deaths)/SUM(new_cases)*100  as DeathPercentage
 FROM Project.dbo.CovidDeaths
 Where continent is NOT NULL
 --Group by date
 ORDER BY 1,2

 -- Population vs Vaccinations
 SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
 , SUM(cast(cv.new_vaccinations as float)) OVER(PARTITION BY cd.location Order by cd.location, cd.date) as RollingPeopleVaccinated
FROM Project.dbo.CovidDeaths cd
 JOIN Project.dbo.CovidVaccinations cv
 ON cd.location =  cv.location
 AND cd.date = cv.date
  Where cd.continent is NOT NULL
 order by 2,3

 -- USING CTE
 WITH PopVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
  AS(
 SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
 , SUM(cast(cv.new_vaccinations as float)) OVER(PARTITION BY cd.location Order by cd.location, cd.date) as RollingPeopleVaccinated
FROM Project.dbo.CovidDeaths cd
 JOIN Project.dbo.CovidVaccinations cv
 ON cd.location =  cv.location
 AND cd.date = cv.date
  Where cd.continent is NOT NULL
 )
 Select *, (RollingPeopleVaccinated/Population)*100
 from PopVac


 -- TEMP TABLE
 Create Table #PercentPopulationVaccinated
 (
 Continent nvarchar(255),
 Location nvarchar(255),
 Date datetime,
 Population numeric,
 New_Vacciations numeric,
 RollingPeopleVaccinated numeric
 )

 Insert INTO #PercentPopulationVaccinated
  SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
 , SUM(cast(cv.new_vaccinations as float)) OVER(PARTITION BY cd.location Order by cd.location, cd.date) as RollingPeopleVaccinated
FROM Project.dbo.CovidDeaths cd
 JOIN Project.dbo.CovidVaccinations cv
 ON cd.location =  cv.location
 AND cd.date = cv.date
  Where cd.continent is NOT NULL
 )

  Select *, (RollingPeopleVaccinated/Population)*100
 from #PercentPopulationVaccinated


 --View
Create View PercentPopulationVaccinated as
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
 , SUM(cast(cv.new_vaccinations as float)) OVER(PARTITION BY cd.location Order by cd.location, cd.date) as RollingPeopleVaccinated
FROM Project.dbo.CovidDeaths cd
 JOIN Project.dbo.CovidVaccinations cv
 ON cd.location =  cv.location
 AND cd.date = cv.date
  Where cd.continent is NOT NULL
 
 Select * from PercentPopulationVaccinated 