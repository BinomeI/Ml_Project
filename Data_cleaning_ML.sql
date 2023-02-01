
USE Data_warehouse_project


-- creation of ML table 
IF OBJECT_ID('ML_DE_CATEGORY') is null
create table ML_DE_CATEGORY
(
	CLIENT_ID INT PRIMARY KEY, 
	Travel money default 0, 
	Meals money default 0,
	Lodging money default 0,
	Groceries money default 0,
	Entertainment money default 0,
	Clothing money default 0,
	Electronics money default 0,
	Home_Supplies money default 0, -- Origin : Home Supplies
	Communication money default 0,
	Misc money default 0,

	Scandanavian money default 0,
	Japan money default 0, 
	Eastern_Europe money default 0, -- Origin: Eastern Europea
	Africa money default 0,
	South_America money default 0, -- Origin: South American
	Mid_East money default 0, -- Origin: Mid East / Sout
	Western_Europe money default 0, -- Origin: Western Europea
	China money default 0,

); 
GO




-- Get charge amount of a all clients by each category DONE +

DECLARE @member_no INT
DECLARE @firstname VARCHAR(15) 
DECLARE @category_desc VARCHAR(31)
DECLARE @sum_amt money 
-- Simple dynamic SQL statement
DECLARE @SQL nvarchar(1000)


DECLARE categories_cursor CURSOR FOR

select fa_ch.member_no, de_me.firstname, de_ca.category_desc, sum(charge_amt) sum_amt
from FA_CHARGE fa_ch, DE_MEMBER de_me, DE_CATEGORY de_ca
where fa_ch.member_no = de_me.member_id and fa_ch.category_no = de_ca.category_id
GROUP BY  fa_ch.member_no, de_me.firstname, de_ca.category_desc
ORDER BY fa_ch.member_no;  

OPEN categories_cursor

FETCH NEXT FROM categories_cursor into @member_no, @firstname, @category_desc, @sum_amt
WHILE @@FETCH_STATUS = 0 
BEGIN 
	IF @category_desc='Home Supplies'
		IF NOT EXISTS(SELECT * FROM ML_DE_CATEGORY WHERE CLIENT_ID=@member_no)
			INSERT INTO ML_DE_CATEGORY (Home_Supplies) VALUES (@sum_amt); 

		ELSE 
			UPDATE ML_DE_CATEGORY SET Home_Supplies = @sum_amt where CLIENT_ID=@member_no; 
	ELSE 
		IF NOT EXISTS(SELECT * FROM ML_DE_CATEGORY WHERE CLIENT_ID=@member_no)
			BEGIN
			set @SQL = 'INSERT INTO ML_DE_CATEGORY (CLIENT_ID, '+ @category_desc+') VALUES ('+ CAST(@member_no AS varchar) + ', ' + CAST(@sum_amt AS VARCHAR)+')'; 
			--print @SQL
			exec(@SQL);
			END; 
		ELSE 
		BEGIN
			set @SQL = 'UPDATE ML_DE_CATEGORY SET '+@category_desc+' = '+CAST(@sum_amt AS VARCHAR)+' where CLIENT_ID= '+ CAST(@member_no AS varchar); 
			exec(@SQL)
		END

		FETCH NEXT FROM categories_cursor into @member_no, @firstname, @category_desc, @sum_amt
END
CLOSE categories_cursor
DEALLOCATE categories_cursor
----------------------------------------------



-----------------------------------

-- Get charge amount of a client by each region DONE

DECLARE @member_no_reg INT 
DECLARE @region_no INT
DECLARE @region_name VARCHAR(15)
DECLARE @sum_amt_reg money 
-- Simple dynamic SQL statement
DECLARE @SQL_reg nvarchar(1000)

DECLARE regions_cursor CURSOR FOR

select ch.member_no, me.region_no, me.region_name, sum(ch.charge_amt) sum_amt_reg
from FA_CHARGE ch INNER JOIN DE_MEMBER me ON me.member_id=ch.member_no
GROUP BY ch.member_no, me.region_no, me.region_name
ORDER BY ch.member_no;

OPEN regions_cursor

FETCH NEXT FROM regions_cursor into @member_no_reg, @region_no, @region_name, @sum_amt_reg
WHILE @@FETCH_STATUS = 0 
BEGIN 
	IF @region_name='Eastern Europea'
		EXECUTE addChargeByRegionName 'Eastern_Europe', @sum_amt_reg, @member_no_reg
		
	ELSE IF @region_name='South American'
		EXECUTE addChargeByRegionName 'South_America', @sum_amt_reg, @member_no_reg

	ELSE IF @region_name='Mid East / Sout'
		EXECUTE addChargeByRegionName 'Mid_East', @sum_amt_reg, @member_no_reg

	ELSE IF @region_name='Western Europea'
		EXECUTE addChargeByRegionName 'Western_Europe', @sum_amt_reg, @member_no_reg

	ELSE 
		EXECUTE addChargeByRegionName @region_name, @sum_amt_reg, @member_no_reg
	
	FETCH NEXT FROM regions_cursor into @member_no_reg, @region_no, @region_name, @sum_amt_reg
END
CLOSE regions_cursor
DEALLOCATE regions_cursor
