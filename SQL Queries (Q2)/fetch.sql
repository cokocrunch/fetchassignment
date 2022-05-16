/*Assumptions:
Query 1: The current month is the dataset is March 2021 however it only had 1 day worth of data and had no brandCode for all entries in that day. Thus, I took Feb 2021 as the most recent month since it had more data. February only had 3 brands present while the others were null. This is something that needs to be addressed. I tried joining to the brands table but the barcodes did not match either. I assume only partnering brands would be in the database so it is common for receipt items to not be tied to a brandcode.

Query 1 is very similar to Query 6 which asks for brand popularity. I assume Query 1 is asking for unique brands within each receipt, while Query 6 asks for the count for each brand within each receipt. Query 1 looks at overall brand popularity preventing users who purchase a large portion from a specific brand to skew the data while Query 6 ignores that and wants to see all transactions for each brand. 

Query 2: For this case, I assume it is comparing how the top 5 brands for the most recent month compare to its performance for the previous month

Many of the queries has null values as the top brand due to many of the entries not having brandCode present. */

/*What are the top 5 brands by receipts scanned for most recent month?*/
with receipts as ( select id_oid as id,rewardsReceiptItemList as rr, DATEADD(SECOND, dateScanned_date/1000 ,'1970/1/1') as dateScanned, month(DATEADD(SECOND, dateScanned_date/1000 ,'1970/1/1')) as smonth, year(DATEADD(SECOND, dateScanned_date/1000 ,'1970/1/1')) as syear
  from [JJ].[dbo].[receipts]), --converting the date column to datetime and extracting year and month from the dates
currentmonth as (select * from receipts where syear=(select year(max(dateScanned)) from receipts) and smonth=(select month(max(dateScanned)) from receipts)), --filtering receipt to current month
recentmonth as (select * from receipts where syear=(select datepart(yyyy,dateadd(m,-1,max(dateScanned))) from receipts) and smonth=(select datepart(m,dateadd(m,-1,max(dateScanned))) from receipts)), -- filtering receipt to most recent month
previousmonth as (select * from receipts where syear=(select datepart(yyyy,dateadd(m,-2,max(dateScanned))) from receipts) and smonth=(select datepart(m,dateadd(m,-2,max(dateScanned))) from receipts)), -- filtering receipt to previous month
receiptitems as (select _id as id,COALESCE(NULLIF(brandCode,''), 'NA') as newBrandCode from [JJ].[dbo].[rreceiptitem] ), --extracting id and brandcode from receipt items and handling nulls
brandpop as (select id,newBrandCode, count(*) as popularity from receiptitems group by id, newBrandCode), -- count number of times each brand appears for each receipt id
-- since we are calculating for top 5 brands by receipts scanned, I assume it means to extract unique brands within each receipt id, and aggregate how its popularity by how often it appears among all receipts
rmonth as (select bp.newBrandCode, count(*) as ranking from recentmonth pm inner join brandpop bp on pm.id=bp.id group by newBrandCode), -- aggregate popularity for each brand for the most recent month
top5 as (select top 5 * from rmonth order by ranking desc), -- order the popularity and select the top 5
pmonth as (select bp.newBrandCode, count(*) as ranking from previousmonth pm inner join brandpop bp on pm.id=bp.id group by newBrandCode)
-- pmonth does the same as rmonth but for the previous month

select * from top5


/*How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?*/
select r.newBrandCode as brand, r.ranking as recent_rank, p.ranking as previous_rank from top5 r left join pmonth p on r.newBrandCode=p.newBrandCode -- For this case, I assume it is comparing how the top 5 brands for the most recent month compare to its performance for the previous month, thus I take the top 5 brands and do a left join on brand code to pmonth so I can see the performance for the brand for both months


/*average spend from receipts with 'rewardsReceiptStatus' of Accepted vs Rejected which is greater? */
select rewardsReceiptStatus, avg(totalSpent) as avg_spend from [JJ].[dbo].[receipts] where lower(rewardsReceiptStatus)='finished' or lower(rewardsReceiptStatus)='rejected' group by rewardsReceiptStatus -- after checking the values for 'rewardsReceiptStatus' there were no entries with Accepted values. I assume finished is equivalent to accepted. This query filters to Finished vs Rejected and the total Spent was averaged grouped by rewardsReceiptStatus


/*When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater? */
select rewardsReceiptStatus, round(sum(purchasedItemCount),2) as total_items from [JJ].[dbo].[receipts] where lower(rewardsReceiptStatus)='finished' or lower(rewardsReceiptStatus)='rejected' group by rewardsReceiptStatus -- this query is similar to the previous one except it takes the sum of number of items purchased rather than the average of total spending


/*Which brand has the most spend among users who were created within the past 6 months? */
with users as (select id, DATEADD(SECOND, createddate/1000 ,'1970/1/1') as createddate, month(DATEADD(SECOND, createddate/1000 ,'1970/1/1')) as smonth, year(DATEADD(SECOND, createddate/1000 ,'1970/1/1')) as syear from [JJ].[dbo].[users]), --converting the date column to datetime and extracting year and month from the dates
sixmonth as (select * from users where createddate >= (select DATEADD(m, -6, max(createddate)) from users)), --filtering entries for the past 6 months
receiptitems as (select _id as id,COALESCE(NULLIF(brandCode,''), 'NA') as newBrandCode, cast(finalPrice as float) as finalPrice from [JJ].[dbo].[rreceiptitem] ), --handling null values for brand and converting final price to float
brandpop as (select id,newBrandCode, count(*) as popularity from receiptitems group by id, newBrandCode) -- count number of times each brand appears for each receipt id


select TOP 2 newBrandCode,sum(finalPrice) as totalSpend from sixmonth s join [JJ].[dbo].[receipts] r on s.id=r.userId join receiptitems ri on ri.id=r.id_oid group by newBrandCode order by totalSpend DESC -- extract the brand with the top spending in the past 6 months


/*Which brand has the most transactions among users who were created within the past 6 months?*/
with users as (select id, DATEADD(SECOND, createddate/1000 ,'1970/1/1') as createddate, month(DATEADD(SECOND, createddate/1000 ,'1970/1/1')) as smonth, year(DATEADD(SECOND, createddate/1000 ,'1970/1/1')) as syear from [JJ].[dbo].[users]), --converting the date column to datetime and extracting year and month from the dates
sixmonth as (select * from users where createddate >= (select DATEADD(m, -6, max(createddate)) from users)), --filtering entries for the past 6 months
receiptitems as (select _id as id,COALESCE(NULLIF(brandCode,''), 'NA') as newBrandCode from [JJ].[dbo].[rreceiptitem] ), --handling null values within brand column
brandpop as (select id,newBrandCode, count(*) as popularity from receiptitems group by id, newBrandCode) -- count number of times each brand appears for each receipt id


select TOP 2 newBrandCode,sum(popularity) as totalTrans from sixmonth s join [JJ].[dbo].[receipts] r on s.id=r.userId join brandpop ri on ri.id=r.id_oid group by newBrandCode order by totalTrans DESC --calculate number of times brand occurs in each receipt and sum across all receipts over the past 6 months, then select top brand which has the highest number of occurence
