select *
from PortfolioProject.dbo.NashvilleHousing

---standard sale date format
select SaleDate
from PortfolioProject.dbo.NashvilleHousing
--the above returns time stamp which we don't need so, lets convert.

select SaleDate, CONVERT (date,SaleDate) as Date
from PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
set SaleDate = CONVERT (date,SaleDate)
--we were trying to update and this above didn't work..so lets try something new

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

--now-
Update NashvilleHousing
set SaleDateConverted = CONVERT (date,SaleDate)
--it should be done by now, lets confirm

select SaleDateConverted
from PortfolioProject.dbo.NashvilleHousing
---cool!!!

---------------------------------------------------

--Populate Property Address data
---We noticed some of the fields for property address was not filled so we nee to populate..a quick look shows that parcel ID can help us

select *
from PortfolioProject.dbo.NashvilleHousing
order by ParcelID
---so we can see that lands with the same parcel ID have the same address, so we need to say something like
--if parcelID A has an address and same Parcel ID A does not have an address, the address for the first should go for thesecond

select a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
--so we can see the null part..now lets populate by introducing ISNULL

select a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
---The new column is the populated column..

----now lets update our original column

Update a ---we're using a because we have renameed in join query
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
---updated, now run the earlier code and see what comes out....nothing

-------------------------------------------------------------------
--breaking out Address into columns
select
substring (PropertyAddress, 1, charindex(',', PropertyAddress) -1) as Address
, SUBSTRING (PropertyAddress, charindex(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
from PortfolioProject.dbo.NashvilleHousing

---we can't sepaerate two values into more columns without creating the new columns, so we need to create columns

ALTER TABLE NashvilleHousing
Add PropertySplitAddress nvarchar(255);

--now-
Update NashvilleHousing
set PropertySplitAddress = substring (PropertyAddress, 1, charindex(',', PropertyAddress) -1)
--it should be done by now, lets confirm

ALTER TABLE NashvilleHousing
Add PropertySplitCity nvarchar(255);

--now-one at a time
Update NashvilleHousing
set PropertySplitCity = SUBSTRING (PropertyAddress, charindex(',', PropertyAddress) +1, LEN(PropertyAddress))
--it should be done by now, lets confirm

Select *
from PortfolioProject.dbo.NashvilleHousing

----Now lest do a more simpler  method for owner address using parsename
Select OwnerAddress
from PortfolioProject.dbo.NashvilleHousing

Select
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1)
from PortfolioProject.dbo.NashvilleHousing

---done!
--now, lets create the extra columns and update
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress nvarchar(255);

--now-
Update NashvilleHousing
set OwnerSplitAddress = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3)
--it should be done by now, lets confirm

--now-one at a time
ALTER TABLE NashvilleHousing
Add OwnerSplitCity nvarchar(255);

Update NashvilleHousing
set OwnerSplitCity = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2)



ALTER TABLE NashvilleHousing
Add OwnerSplitState nvarchar(255);

Update NashvilleHousing
set OwnerSplitState = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1)

Select *
from PortfolioProject.dbo.NashvilleHousing


-----------------------------------------------------
--changing Y and N to Yes and Ni in "Sold As Vacant field"
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
from PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2 Desc


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'YES'
	   When SoldAsVacant = 'N' THEN 'NO'
	   Else SoldAsVacant
	   END
from PortfolioProject.dbo.NashvilleHousing

---UPDATE NOW

Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'YES'
	   When SoldAsVacant = 'N' THEN 'NO'
	   Else SoldAsVacant
	   END
from PortfolioProject.dbo.NashvilleHousing

----update beautifully done

----Remove duplicate


With RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
from PortfolioProject.dbo.NashvilleHousing
---ORDER BY ParcelID
)

---Select *
---from RowNumCTE
---where row_num > 1
----order by PropertyAddress

---Now, the above shows us duplicates, about 104 rows of duplicates.
---we are now going to permananently delete duplicates, and so running this on this same DB later on might give you zero duplicates 
---You will see why now
Select *
from RowNumCTE
where row_num > 1


----Delete Unused Column

Select *
from PortfolioProject.dbo.NashvilleHousing

ALTER Table PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
--saledate too
ALTER Table PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate