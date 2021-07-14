select * from PortfolioProjectCOVID..coviddeaths
where continent is not NULL
order by 3,4

--select * from PortfolioProjectCOVID..covidvaccinations
--order by 3,4

-- Select data we're going to be using

select location, date, total_cases, new_cases, total_deaths from PortfolioProjectCOVID..coviddeaths
order by 1,2

-- Looking at the mortality rate in Canada on 12/31/2020 and 07/01/2021

select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate from PortfolioProjectCOVID..coviddeaths
where location like 'Canada' AND (date like '2020-12-31' OR date like '2021-07-01')
order by 1,2 

-- Looking at the mortality rate across the world on 12/31/2020 and 07/01/2021
select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate from PortfolioProjectCOVID..coviddeaths
where (date like '2020-12-31' OR date like '2021-07-01')
order by 1,2 

-- Looking at total cases vs population in Canada
select location, date, total_cases, Population, (total_cases/Population)*100 as infected_rate from PortfolioProjectCOVID..coviddeaths
where location like 'Canada'
order by 1,2 

-- countires with highest infection rate
select location, MAX(total_cases) as TotalCaseCount, Population, MAX((total_cases/population)*100) as TotalInfectedRate from PortfolioProjectCOVID..coviddeaths
group by location, population
order by TotalInfectedRate desc

-- where is Canada?
select location, MAX(total_cases) as TotalCaseCount, Population, MAX((total_cases/population)*100) as TotalInfectedRate from PortfolioProjectCOVID..coviddeaths
where location like 'Canada'
group by location, population

-- Countries with highest death counts
select location, MAX(cast(total_deaths as int)) as TotalDeaths from PortfolioProjectCOVID..coviddeaths
where continent is not NULL
group by location
order by TotalDeaths desc

-- continents with highest death counts
select location, MAX(cast(total_deaths as int)) as TotalDeaths from PortfolioProjectCOVID..coviddeaths
where continent is NULL and location not like 'world'
group by location
order by TotalDeaths desc

-- Countries with highest death per population
select location, MAX(total_deaths) as TotalDeaths, Population, MAX((total_deaths/population)*100) as PopDeathRate from PortfolioProjectCOVID..coviddeaths
group by location, population
order by PopDeathRate  desc

-- Countries with highest death per population
select location, MAX(total_deaths) as TotalDeaths, Population, MAX((total_deaths/population)*100) as PopDeathRate from PortfolioProjectCOVID..coviddeaths
where location like 'Canada'
group by location, population


-- Showing the continents with the highest death count
select location, MAX(cast(total_deaths as int)) as TotalDeaths from PortfolioProjectCOVID..coviddeaths
where continent is NULL and location not like 'world'
group by location
order by TotalDeaths desc

-- Showing the continents with the highest death rate by population
select location, MAX(cast(total_deaths as int)) as TotalDeaths, MAX((total_deaths/population)*100) as DeathRate from PortfolioProjectCOVID..coviddeaths
where continent is NULL and location not like 'world'
group by location
order by DeathRate desc


-- global figures
select date, SUM(new_cases) as daily_cases, SUM(cast(new_deaths as int)) as daily_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DailyDeathRate 
from PortfolioProjectCOVID..coviddeaths
where continent is not NULL and location not like 'world'
group by date
order by 1,2

select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathRate 
from PortfolioProjectCOVID..coviddeaths
where continent is not NULL and location not like 'world'
order by 1,2


-- looking at total pop vs vaccinated
select dea.continent, dea.location, dea.date, dea.population, dea.new_deaths, dea.new_cases, vax.new_vaccinations
, SUM(cast(vax.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vax
, SUM(cast(dea.new_cases as int)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_cases
, SUM(cast(dea.new_deaths as int)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_deaths
from PortfolioProjectCOVID..coviddeaths as dea
join PortfolioProjectCOVID..covidvaccinations as vax
on dea.location = vax.location  and dea.date = vax.date
where dea.continent is not null and dea.location like 'canada'
order by 2,3

-- USE CTE
With PopVsVax (continent, location, date, population, new_vaccinations, rolling_vax)
as (
select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(cast(vax.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vax
from PortfolioProjectCOVID..coviddeaths as dea
join PortfolioProjectCOVID..covidvaccinations as vax
	on dea.location = vax.location  
	and dea.date = vax.date
where dea.location like 'Canada')
select *, (rolling_vax/Population)*100 as vaccinated_rate from PopVsVax 

--TEMP Table
DROP Table if exists #PercentPopVax
Create Table #PercentPopVax
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vax numeric
)
Insert into #PercentPopVax
select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(cast(vax.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vax
from PortfolioProjectCOVID..coviddeaths as dea
join PortfolioProjectCOVID..covidvaccinations as vax
	on dea.location = vax.location  
	and dea.date = vax.date
where dea.location like 'Canada'
select *, (rolling_vax/Population)*100 as vaccinated_rate from #PercentPopVax  

--Creating view
Create View CasesDeathsVax as
select dea.continent, dea.location, dea.date, dea.population, dea.new_deaths, dea.new_cases, vax.new_vaccinations
, SUM(cast(vax.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vax
, SUM(cast(dea.new_cases as int)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_cases
, SUM(cast(dea.new_deaths as int)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_deaths
from PortfolioProjectCOVID..coviddeaths as dea
join PortfolioProjectCOVID..covidvaccinations as vax
on dea.location = vax.location  and dea.date = vax.date
where dea.continent is not null
--order by 2,3