

Select *
From PortfolioProject..coviddeaths$
Where continent is not null
order by 3,4


--Select *
--from [Portfolio Project]..covidvaccinations$
--order by 3,4

-- Select the data we're using

-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..coviddeaths$
Where continent is not null 
order by 1,2

-- Converting 

alter table portfolioproject..coviddeaths$ alter column population float;
alter table portfolioproject..coviddeaths$ alter column total_deaths float;
alter table portfolioproject..coviddeaths$ alter column new_cases float;
alter table portfolioproject..coviddeaths$ alter column new_deaths float;
alter table portfolioproject..covidvaccinations$ alter column new_vaccinations float;
-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..coviddeaths$
Where location like '%italy%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..coviddeaths$
Where location like '%italy%'
order by 1,2

-- Which country has the highest infection rate? 

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..coviddeaths$
Group by location,population
order by PercentPopulationInfected desc


-- Which country has the highest death count per population?

Select location, MAX(cast(total_deaths as int)) as totaldeathcount
From PortfolioProject..coviddeaths$
where continent is not null
Group by location
order by totaldeathcount desc

-- Let's separate between continents:

Select continent, MAX(cast(total_deaths as int)) as totaldeathcount
From PortfolioProject..coviddeaths$
where continent is not null
Group by continent
order by totaldeathcount desc

-- Global numbers: divided per date
Select date,sum(new_cases) as total_cases, sum (new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
From PortfolioProject..coviddeaths$
--Where location like '%italy%'
where continent is not null 
group by date
order by 1,2

-- total amount: GLOBAL CASES

Select sum(new_cases) as total_cases, sum (new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
From PortfolioProject..coviddeaths$
--Where location like '%italy%'
where continent is not null 
order by 1,2


-- let's join the two different tables:

Select *
from PortfolioProject..coviddeaths$ dea
join PortfolioProject..covidvaccinations$ vac
on dea.location=vac.location 
and dea.date=vac.date


-- looking at total populations and vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..coviddeaths$ dea
join PortfolioProject..covidvaccinations$ vac
on dea.location=vac.location 
and dea.date=vac.date
where dea.continent is not null
and dea.location like '%italy%'
order by 2,3

-- 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(new_vaccinations) over (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated
from PortfolioProject..coviddeaths$ dea
join PortfolioProject..covidvaccinations$ vac
on dea.location=vac.location 
and dea.date=vac.date
where dea.continent is not null
and dea.location like '%italy%'
order by 2,3

--
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..coviddeaths$ dea
Join PortfolioProject..covidvaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

--

-- use CTE (common table expression) (Prima ho creato la colonna RollingPeopleVaccinated, e non posso usarla imm
-- immediatamente! Quindi uso CTE, avrei potuto creare anche una temp table... 

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..coviddeaths$ dea
Join PortfolioProject..covidvaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
and dea.location like '%italy'
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as VaccinatedOverPopulation
From PopvsVac


-- Creating a temp table


Drop table if exists #PercentPopVacc
Create Table #PercentPopVacc
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopVacc

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..coviddeaths$ dea
Join PortfolioProject..covidvaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
and dea.location like '%italy'
Select *, (RollingPeopleVaccinated/Population)*100 as VaccinatedOverPopulation
From #PercentPopVacc


--- Creating representation to visualize data

Create view PercentPopVacc as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..coviddeaths$ dea
Join PortfolioProject..covidvaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3


Select *
from PercentPopVacc