---select the data we want to use

--Select Location	, date,	total_cases, new_cases, total_deaths, population
--From PortfolioProject..CovidDeaths$
--order by 1,2


--lets start some calculations

---shows the likelihood of dying if you had contracted covid in your country...change States to Nigeria
Select Location	, date,	total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
From PortfolioProject..CovidDeaths$
where location like '%states%'
order by 1,2

---Now lets look at the total cases versus population to show waht % of the population got covid
Select Location	, date,	total_cases, population, (total_cases/population)*100 as PopulationInfected
From PortfolioProject..CovidDeaths$
where location like '%Nigeria%'
order by 1,2

--Now, what country has the highest infection rate compared to the population?
Select Location	,population, max(total_cases) as HighestInfectedCount,  max((total_cases/population))*100 as MaxPopulationInfected
From PortfolioProject..CovidDeaths$
--where location like '%Nigeria%'
Group by location, population
order by MaxPopulationInfected desc

---What is the hiughest death count by population
Select Location, max(cast(total_deaths as int)) as TotalDeathCount
---we added the cast because the data type for total_deaths is nvarchar 255
From PortfolioProject..CovidDeaths$
where continent is not null
--we added the line above due to the fact that the data was arranged that way..
Group by location
order by TotalDeathCount desc

---lets look at continent
Select Location, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
where continent is null
Group by location
order by TotalDeathCount desc
--OR
Select continent, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
where continent is not null
Group by continent
order by TotalDeathCount desc


----GLOBAL NUMBERS
Select date, sum(new_cases) as CasesPerDay, sum(cast(new_deaths as int)) as DeathsPerDay, (sum(cast(new_deaths as int))/sum(new_cases))*100 as GlobalDeathPercent
From PortfolioProject..CovidDeaths$
--where location like '%states%'
where continent is not null
Group by date
order by 1,2


----Now lets look at covid vaccinations
Select *
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
	on dea.location=vac.location
	and dea.date = vac.date

---total population vs vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
	on dea.location=vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2

---doing the above anotehr way
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as int))
OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
	on dea.location=vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

---Now we wanr to call the new column name by=ut we cant use ut as t was just created.
---so we need a cte or temp table

---using CTE

With PopvsVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) ---populationvspopulation
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as int))
OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
	on dea.location=vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

Select *, (RollingPeopleVaccinated/population)*100
from PopvsVac


---now using a Temp table

DROP TABLE if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric
)


Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as int))
OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
	on dea.location=vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated




---now lets create a view to store for later visualisations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as int))
OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
	on dea.location=vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *
from PercentPopulationVaccinated

Create View ContinentFigures as
Select Location, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
where continent is null
Group by location
--order by TotalDeathCount desc