

--- Let's create  a copy of the dataset

INSERT INTO  claims_study 
SELECT * FROM [dbo].[claims_reports]

-- checking for duplicated. We will use the Claim # to check for duplactes because it is likely to be unique indentifier for each claim
-- Some claims have beeng updated over time and we will be working only with the most recent disposition date

WITH duplicates as 
(SELECT
COUNT(*) OVER(partition by CLAIM ORDER BY DISPOSITION_DATE DESC) as uniq_check,
*
FROM [dbo].[claims_study] 
) 
DELETE FROM duplicates WHERE uniq_check >1


--- For CONSISTENCY  we need to upadate the table to standardize the different claim types 
UPDATE  [dbo].[claims_study]
SET  [CLAIM_TYPE] = UPPER(TRIM(REPLACE([CLAIM_TYPE], '(PI)' , ' ')))
FROM [dbo].[claims_study]


 ---  UPDATE to get the unique description for claim type
  
 UPDATE [dbo].[claims_study]
SET [CLAIM_TYPE] =
  CASE 
  WHEN [CLAIM_TYPE] = 'NON COVERED AGENCY/CITY ' THEN 'NON COVERED AGENCY '
  WHEN [CLAIM_TYPE] = 'WATER MAIN ' THEN 'WATERMAIN BREAK '
  WHEN [CLAIM_TYPE] = 'DEFECT TRAF/LIGHT/STOP SIGN ' THEN 'DEFECTIVE TRAFF/LIGHT/SIGN '
  WHEN [CLAIM_TYPE] = 'PARKS & RECREATION ' THEN 'RECREATION '
  WHEN [CLAIM_TYPE] = 'CIVIL RIGHTS CLAIMS ' THEN 'CIVIL RIGHTS '
  WHEN [CLAIM_TYPE] = 'DEFECTIVE SIDEWALK' THEN 'SIDEWALK'
  WHEN [CLAIM_TYPE] = 'DEFECTIVE ROADWAY' THEN 'ROADWAY'
  WHEN [CLAIM_TYPE] = 'CITY ONLY(NON COV AGY/BODY)' THEN 'CITY PROPERTY'
  WHEN [CLAIM_TYPE] = 'NON COVERED AGENCY AND CITY' THEN 'NON COVERED AGENCY'
  WHEN [CLAIM_TYPE] = 'EMPLOYEE UNIFORMED SERVICE' THEN 'UNIFORMED SERVICES EMPLOYEE'
  WHEN [CLAIM_TYPE]  IN ('PEACE OFFICER (POLICE ACT) ','PEACE OFFICER/POLICE ACTION ') THEN 'POLICE ACTION'
  WHEN [CLAIM_TYPE]  IN ('BUILDING AND PROPERTY ','BUILDINGS AND PROPERTY ') THEN 'CITY PROPERTY'
  ELSE [CLAIM_TYPE]  END  
 FROM [dbo].[claims_study]


 -- Total number of claims
SELECT 
COUNT(*) 
FROM [dbo].[claims_study]


 --- total claim in regard to claim type
  SELECT TOP 10
	  CLAIM_TYPE,
	  COUNT(*) AS number_of_claim
  FROM [dbo].[claims_study] 
  GROUP BY [CLAIM_TYPE]
  ORDER BY number_of_claim desc


---Claim status count
select 
	 [CLAIM_ACTION],
	 count([CLAIM]) status_count
 from [dbo].[claims_study]
 group by [CLAIM_ACTION]
 order by status_count desc


  -- Claim by borough 
SELECT TOP 10
	 [BOROUGH],
	 count([CLAIM]) as claim_per_borough
 FROM [dbo].[claims_study]
 where BOROUGH is not null
GROUP BY  [BOROUGH] 
ORDER BY claim_per_borough desc


 ---yearly distribution of claims 
 SELECT
	 datepart(year,[OCCURRENCE_DATE]),
	 count(*) as total
FROM[dbo].[claims_study]
 WHERE [OCCURRENCE_DATE] is not null
 GROUP BY datepart(year,[OCCURRENCE_DATE])
ORDER BY total desc;
 
  --what the avereage claim duration by claim type
  SELECT
	[CLAIM_TYPE],
	 AVG(datediff(YEAR,[FILED_DATE], [DISPOSITION_DATE])) as year_duration
 from [dbo].[claims_study]
 where [DISPOSITION_DATE] is not null and [FILED_DATE] is not null
GROUP BY [CLAIM_TYPE]
ORDER BY year_duration DESC


---Year-over-Year Analysis of Monthly Claim Durations
with x as
 (SELECT
 FISCAL_YEAR_FY,
 AVG(datediff(month,FILED_DATE, DISPOSITION_DATE)) as PreviousMontlyDuration	
FROM[dbo].[claims_study]
WHERE DISPOSITION_DATE is not null and FILED_DATE is not null
GROUP BY FISCAL_YEAR_FY 
), y as 
(SELECT 
	*,
	 LAG( PreviousMontlyDuration,1,0) OVER(ORDER BY FISCAL_YEAR_FY  ) as CurentMonthlyDuration
	 from x
) 
SELECT *,
PreviousMontlyDuration-CurentMonthlyDuration  as DifferenceChange
FROM Y


-- Claim disposition summary
SELECT 
    COUNT(*) AS Total_Claims,
    COUNT(Disposition_Amount) AS Non_Null_Disposition_Count,
    AVG(Disposition_Amount) AS Average_Disposition_Amount,
    MIN(Disposition_Amount) AS Min_Disposition_Amount,
    MAX(Disposition_Amount) AS Max_Disposition_Amount  
FROM [dbo].[claims_study];
---let's investigate those claims with the min and max disposition amount.
SELECT * 
FROM  [dbo].[claims_study]
WHERE
DISPOSITION_AMOUNT = (select min([DISPOSITION_AMOUNT]) from [dbo].[claims_study]) 
or 
DISPOSITION_AMOUNT  = (select max([DISPOSITION_AMOUNT]) from [dbo].[claims_study]);

---Top and bottom Claims by disposition amount
 WITH claimCost as 
 (SELECT 
[CLAIM], 
[DISPOSITION_AMOUNT],
 ROW_NUMBER() OVER (ORDER BY[DISPOSITION_AMOUNT] DESC) AS TopAnalysis,
 ROW_NUMBER() OVER(ORDER BY [DISPOSITION_AMOUNT] ASC) BottomAnalysis 
FROM [dbo].[claims_study]
WHERE [DISPOSITION_AMOUNT] 
IS NOT NULL
)
SELECT 
CLAIM,
[DISPOSITION_AMOUNT],

'TOP 10' AS top10
FROM claimCost
WHERE TopAnalysis <=10

UNION all

SELECT
[CLAIM],
[DISPOSITION_AMOUNT],
'BOTOM 10' 
FROM claimCost
WHERE BottomAnalysis <=10;

-- let rank the BOROUGH based on their disposition amount
SELECT 
	[BOROUGH],
	sum(DISPOSITION_AMOUNT) as total_sum,
	ROW_NUMBER() over( ORDER BY sum(DISPOSITION_AMOUNT) DESC) Ranking
FROM[dbo].[claims_study]
WHERE BOROUGH is not null AND DISPOSITION_AMOUNT IS NOT NULL
GROUP BY BOROUGH;













-



