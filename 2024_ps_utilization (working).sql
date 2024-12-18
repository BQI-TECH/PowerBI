CREATE OR ALTER PROCEDURE [dbo].[CreateStaffUtilizationView]
AS
BEGIN
    -- Check if the view already exists, and drop it if necessary
    IF OBJECT_ID('vw_staff_utilization', 'V') IS NOT NULL
    BEGIN
        DROP VIEW vw_staff_utilization;
    END

    -- Create the vw_staff_utilization view
    EXEC('
    CREATE VIEW vw_staff_utilization AS
    SELECT 
        HTE.[user/name] AS Person,
        DATEPART(YEAR, HTE.[spent_date]) AS Year,
        CASE 
            WHEN DATEPART(WEEK, HTE.[spent_date]) BETWEEN 1 AND 26 THEN ''1H''
            ELSE ''2H''
        END AS [Year-Half],
        DATEPART(WEEK, HTE.[spent_date]) AS [Week Number],
        CASE 
            WHEN DATEPART(WEEK, HTE.[spent_date]) <= 26 THEN DATEPART(WEEK, HTE.[spent_date])
            ELSE DATEPART(WEEK, HTE.[spent_date]) - 26
        END AS [Half-Year Week Number],
        
        -- Reset Available Billable Hours after each half-year and year-end
        CASE 
            WHEN DATEPART(WEEK, HTE.spent_date) <= 26 THEN DATEPART(WEEK, HTE.spent_date) * 40
            WHEN DATEPART(WEEK, HTE.spent_date) > 26 AND DATEPART(WEEK, HTE.spent_date) <= 52 THEN (DATEPART(WEEK, HTE.spent_date) - 26) * 40
            ELSE 0
        END AS [Available Billable Hours],
        
        SUM(HTE.rounded_hours) AS [Actual Billable Hours],
        SUM(SUM(HTE.rounded_hours)) OVER (
            PARTITION BY HTE.[user/name],
                         DATEPART(YEAR, HTE.[spent_date]),
                         CASE 
                            WHEN DATEPART(WEEK, HTE.[spent_date]) BETWEEN 1 AND 26 THEN ''1H''
                            ELSE ''2H''
                         END
            ORDER BY CASE 
                        WHEN DATEPART(WEEK, HTE.[spent_date]) <= 26 THEN DATEPART(WEEK, HTE.[spent_date])
                        ELSE DATEPART(WEEK, HTE.[spent_date]) - 26
                     END
        ) AS [Cumulative Billable Hours],
        
        CASE 
            WHEN (DATEPART(WEEK, HTE.spent_date) * 40) = 0 THEN 0
            ELSE ROUND(
                (SUM(SUM(HTE.rounded_hours)) OVER (
                    PARTITION BY HTE.[user/name],
                                 DATEPART(YEAR, HTE.[spent_date]),
                                 CASE 
                                    WHEN DATEPART(WEEK, HTE.[spent_date]) BETWEEN 1 AND 26 THEN ''1H''
                                    ELSE ''2H''
                                 END
                ) * 100.0) 
                / (DATEPART(WEEK, HTE.spent_date) * 40), 2)
        END AS [Weekly Utilization Pct],
        
        HU.[roles/1] AS [Role 1],
        HU.[roles/2] AS [Role 2],
        HU.[roles/3] AS [Role 3],
        HU.[roles/4] AS [Role 4],
        HU.[roles/5] AS [Role 5],
        HU.[roles/6] AS [Role 6],
        HU.[roles/7] AS [Role 7],
        HU.[roles/8] AS [Role 8],
        HU.[roles/9] AS [Role 9],
        HU.[roles/10] AS [Role 10],
        HU.[roles/11] AS [Role 11],
        HU.[roles/12] AS [Role 12],

        -- Boolean checks for roles
        CASE 
            WHEN ''PS'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                          HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                          HU.[roles/11], HU.[roles/12]) 
             THEN 1 
            ELSE 0 
        END AS [Is PS],

        CASE 
            WHEN ''PS'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                          HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                          HU.[roles/11], HU.[roles/12]) 
             AND ''Leadership'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                                   HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                                   HU.[roles/11], HU.[roles/12]) 
             THEN 1 
            ELSE 0 
        END AS [Is PS Leadership],

        CASE 
            WHEN ''PS'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                          HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                          HU.[roles/11], HU.[roles/12]) 
             AND ''Leadership'' NOT IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                                       HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                                       HU.[roles/11], HU.[roles/12]) 
             THEN 1 
            ELSE 0 
        END AS [Is PS Regular],

        CASE 
            WHEN ''PS'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                          HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                          HU.[roles/11], HU.[roles/12]) 
             AND ''Project Management'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                                          HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                                          HU.[roles/11], HU.[roles/12]) 
             THEN 1 
            ELSE 0 
        END AS [Is PM],

        CASE 
            WHEN ''PS'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                          HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                          HU.[roles/11], HU.[roles/12]) 
             AND ''Technical Team'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                                          HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                                          HU.[roles/11], HU.[roles/12]) 
             THEN 1 
            ELSE 0 
        END AS [Is Technical],

        CASE 
            WHEN ''PS'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                          HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                          HU.[roles/11], HU.[roles/12]) 
             AND ''IC Team'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                                  HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                                  HU.[roles/11], HU.[roles/12]) 
             THEN 1 
            ELSE 0 
        END AS [Is Implementation],

        -- Concatenated roles column
        CASE
    WHEN ''PS'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                  HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                  HU.[roles/11], HU.[roles/12]) THEN ''PS''
    ELSE ''''
END +
CASE
    WHEN ''Leadership'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                            HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                            HU.[roles/11], HU.[roles/12]) THEN '', Leadership''
    ELSE ''''
END +
CASE
    WHEN ''Project Management'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                                      HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                                      HU.[roles/11], HU.[roles/12]) THEN '', Project Management''
    ELSE ''''
END +
CASE
    WHEN ''Technical Team'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                                HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                                HU.[roles/11], HU.[roles/12]) THEN '', Technical Team''
    ELSE ''''
END +
CASE
    WHEN ''IC Team'' IN (HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], 
                         HU.[roles/6], HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], 
                         HU.[roles/11], HU.[roles/12]) THEN '', IC Team''
    ELSE ''''
END AS [Concatenated Roles]

    FROM Harvest_Time_Entries HTE
    JOIN Harvest_Users HU ON HTE.[user/id] = HU.[id]
    GROUP BY 
        HTE.[user/name], 
        DATEPART(YEAR, HTE.spent_date), 
        DATEPART(WEEK, HTE.spent_date),
        HU.[roles/1], HU.[roles/2], HU.[roles/3], HU.[roles/4], HU.[roles/5], HU.[roles/6], 
        HU.[roles/7], HU.[roles/8], HU.[roles/9], HU.[roles/10], HU.[roles/11], HU.[roles/12]
    ');
END
