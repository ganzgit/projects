/****** Script for Standard Date  ******/
SELECT * from Project.dbo.NashvilleHousing
------------------
SELECT NewSaleDate, CONVERT(Date,SaleDate) from Project.dbo.NashvilleHousing

UPDATE NashvilleHousing SET NewSaleDate = CONVERT(Date,SaleDate)

ALTER Table NashvilleHousing ADD NewSaleDate Date

/****** Script for Populate Address  ******/

SELECT PropertyAddress from Project.dbo.NashvilleHousing where PropertyAddress IS NULL

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from Project.dbo.NashvilleHousing a
JOIN Project.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from Project.dbo.NashvilleHousing a
JOIN Project.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

/****** Script for Breaking up the Address  ******/

SELECT PropertyAddress from Project.dbo.NashvilleHousing 

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',' ,PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',' ,PropertyAddress)+1, LEN(PropertyAddress)) as Address2
from Project.dbo.NashvilleHousing

ALTER Table NashvilleHousing ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',' ,PropertyAddress)-1)

ALTER Table NashvilleHousing ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',' ,PropertyAddress)+1, LEN(PropertyAddress))

/****** Script for Split up the Address  ******/

SELECT OwnerAddress from Project.dbo.NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3)
,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
,PARSENAME(REPLACE(OwnerAddress,',','.'),1)
from Project.dbo.NashvilleHousing

ALTER Table NashvilleHousing ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER Table NashvilleHousing ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER Table NashvilleHousing ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

/****** Script for Normalizing Vacant ******/

Select DISTINCT(SoldAsVacant), Count(SoldAsVacant)
from Project.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2


Select SoldAsVacant
 ,CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
  WHEN SoldAsVacant = 'N' THEN 'No'
  ELSE SoldAsVacant
  END
from Project.dbo.NashvilleHousing 

UPDATE NashvilleHousing SET
SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
  WHEN SoldAsVacant = 'N' THEN 'No'
  ELSE SoldAsVacant
  END

/****** Script for Removing Duplicates ******/

  WITH RowNumCTE AS(
  SELECT *, 
  ROW_NUMBER() OVER(
  PARTITION BY ParcelID,
               PropertyAddress,
               SalePrice,
	       SaleDate,
               LegalReference
  ORDER BY UniqueID) row_num
from Project.dbo.NashvilleHousing)

SELECT * from RowNumCTE Where row_num > 1 

/****** Script for Deleting unused columns ******/

ALTER TABLE Project.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
