---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--Title:		CTS: Software Development
--				Pre-Interview Coding Challenge
---------------------------------------------------------------------------------
--Autor:		Kamil Teczkowski
--Created on:	30/01/2020
--Version:		1.0
--Description:	Development script for interview task to calculate the highest 
--				trade gain from loaded data.
--Remarks:		Enabling xp_cmdShell
--				Creating test database 
--				Creating holding table
--				Check all columns
--				Create SP to select best deal
--				Variables:
--					@dayDiff	= 0, --if set to 0 it will run for all possible days otherwise it is a value of days between buy and sell
--					@bestTrade	= 1, --If set to one and dayDiff grater from 1 then it SP will rank all days within dayDiff
--					@allFiles	= 0, --0 load only 1 selected file and 1 run all files in folder. Files have to be in alphabetical order without special characters ChallengeSampleDataSet1, ChallengeSampleDataSet2, ChallengeSampleDataSet3 available in folder
--					@fullPath	= 'C:\Temp\ChallengeSampleDataSet2.txt', --UNC standard. The maximum length for a path is MAX_PATH, which is defined as 260 characters. Win 10 allows to override this setting
--					@minBuyDay  = 1, --select minimum starting opening trade date
--					@maxBuyDay  = 60 --select maximum starting opening trade date

---------------------------------------------------------------------------------

-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO 



--Check if test database exists - creating database
IF (NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'CS_TradeGain_SQL'))
BEGIN 
	CREATE DATABASE [CS_TradeGain_SQL];
END
ELSE
BEGIN
	PRINT 'Database [CS_TradeGain_SQL] already exists';
END;
GO


--Use test database 
USE [CS_TradeGain_SQL]
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON

GO

--Check if stock trade data table exists - creating table
IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[StockTrade]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[StockTrade]
	(
		[DayNo]			INT	IDENTITY(1, 1),
		[TradePrice]	DECIMAL(28, 2),
		[FileName]		NVARCHAR(260),
		[CreatedOn]		DATETIME DEFAULT GETDATE(),
		PRIMARY KEY ([DayNo])
	);
END
ELSE
BEGIN
	PRINT 'Table [dbo].[StockTrade] already exists';
END;
GO


--Check if table has all requiered columns - create columns 
IF COL_LENGTH('[dbo].[StockTrade]', N'DayNo') IS NULL
BEGIN
    ALTER TABLE [dbo].[StockTrade] ADD [DayNo] INT IDENTITY(1, 1), PRIMARY KEY([DayNo]);
END

IF COL_LENGTH('[dbo].[StockTrade]', N'TradePrice') IS NULL
BEGIN
    ALTER TABLE [dbo].[StockTrade] ADD [TradePrice] DECIMAL(28, 2);
END

IF COL_LENGTH('[dbo].[StockTrade]', N'FileName') IS NULL
BEGIN
    ALTER TABLE [dbo].[StockTrade] ADD [FileName] NVARCHAR(260);
END

IF COL_LENGTH('[dbo].[StockTrade]', N'CreatedOn') IS NULL
BEGIN
    ALTER TABLE [dbo].[StockTrade] ADD [CreatedOn] DATETIME DEFAULT GETDATE();
END

GO


--Create SP to load files and select best deals
IF OBJECT_ID('dbo.TradeCalculation') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[TradeCalculation] AS SELECT 1');

GO

ALTER PROCEDURE [dbo].[TradeCalculation]
(
	@dayDiff		INT = 1, --if set to 0 it will run for all possible days
	@bestTrade		BIT = 0,
	@allFiles		BIT = 0, --files have to be in alphabetical  order without special characters ChallengeSampleDataSet1, ChallengeSampleDataSet2, ChallengeSampleDataSet3
	@fullPath		VARCHAR(MAX) = NULL, --the maximum length for a path is MAX_PATH, which is defined as 260 characters. Win 10 allows to override this setting
	@minBuyDay INT = NULL,
	@maxBuyDay INT = NULL
)

AS 

SET NOCOUNT ON
SET XACT_ABORT ON; 

BEGIN TRY  
    BEGIN TRANSACTION;  

		--Message
		DECLARE @messageString VARCHAR(MAX)      
		
		--Min and Max Date validation
		IF @minBuyDay > @maxBuyDay
		BEGIN
			SET @messageString = 'Warning: The Minimum Buy Day ' +  CONVERT(VARCHAR(MAX), @minBuyDay) + ' cannot be greater than Maximum Buy Day '  +  CONVERT(VARCHAR(MAX), @maxBuyDay) +'. Please change the minBuyDate value.';
			RAISERROR(@messageString, 16, 0) WITH NOWAIT;
		END;	
		
		--Full file path is missing
		IF @fullPath IS NULL
		BEGIN
			SET @messageString = 'Please provide full file path and rerun stored procedure';
			RAISERROR(@messageString, 16, 0) WITH NOWAIT;
		END;

		--Resetting holding table
		SET @messageString = 'Truncate table [dbo].[StockTrade]';

		TRUNCATE TABLE [dbo].[StockTrade];

		--Initiate variables
		SET @messageString = 'Initiate variables';

		DECLARE @fileName	VARCHAR(255) = RIGHT(@fullPath, CHARINDEX('\', REVERSE(@fullPath)) - 1),
				@path		VARCHAR(255) = LEFT(@fullPath, LEN(@fullPath) - CHARINDEX('\', REVERSE(@fullPath)) + 1),
				@cmd		VARCHAR(1000),
				@sql_BULK	VARCHAR(MAX);


		--Create temp loading table #TradePrice
		SET @messageString = 'Create temp loading table #TradePrice';

		IF OBJECT_ID('tempdb..#TradePrice') IS NOT NULL DROP TABLE #TradePrice
		CREATE TABLE #TradePrice
		(
			[TradePrice]	DECIMAL(28, 2)
		);


		--Run batch insert
		SET @messageString = 'Run batch insert.';

		IF @allFiles = 1
		BEGIN
			
			SET @messageString = 'Multiple file run. Please check file path, name and format.';

			DECLARE @allFileNames TABLE
			(
				[WitchPath] VARCHAR(255),
				[WitchFile] VARCHAR(255)
			);

			SET @cmd = 'dir ' + @path + '*.txt /b'

			INSERT INTO  @allFileNames([WitchFile])

			EXEC Master..xp_cmdShell @cmd;
    
			UPDATE
				@allFileNames 
			SET 
				[WitchPath] = @path 
			
			DECLARE c1 CURSOR FOR SELECT [WitchPath], [WitchFile] FROM @allFileNames where [WitchFile] like '%.txt%';

			OPEN c1
			FETCH NEXT FROM c1 INTO @path, @fileName

			WHILE @@fetch_status <> -1
				BEGIN
					
					--this won't be executed - truncate statement clears previous loads
					IF EXISTS (SELECT [FileName] FROM [dbo].[StockTrade] WHERE [FileName] = @fileName)
					BEGIN
						SET @messageString = 'File ' + @fileName + ' was previously loaded. Please remove the file and run again.';
						RAISERROR(@messageString, 16, 0) WITH NOWAIT;
					END;
					
					SET @sql_BULK = '
						BULK INSERT 
							#TradePrice 
						FROM 
						''' + @path + @filename + ''' 
						WITH
						(
							ROWTERMINATOR = '',''
						);';

					PRINT @sql_BULK;
					EXEC (@sql_BULK);

					FETCH NEXT FROM C1 INTO @path, @filename

				END;
			CLOSE c1;
			DEALLOCATE c1;
		END
		ELSE
		BEGIN
			
			SET @messageString = 'Single file run. Please check file path, name and format.';

			SET @sql_BULK = '
				BULK INSERT 
					#TradePrice 
				FROM 
				''' + @path + @filename + ''' 
				WITH
				(
					ROWTERMINATOR = '',''
				);';

			PRINT @sql_BULK;
			EXEC (@sql_BULK);
		END;


		SET @messageString = 'Add day number column to ensure the load order';

		ALTER TABLE #TradePrice
		ADD [DayNo]	INT	IDENTITY(1, 1);

		
		SET @messageString = 'Insert bulk loaded data into StockTrade holding table';

		SET IDENTITY_INSERT [dbo].[StockTrade] ON;

		INSERT INTO [dbo].[StockTrade] 
		(
			[DayNo],
			[TradePrice],
			[FileName]
		)
		SELECT
			[DayNo],
			[TradePrice],
			@FileName
		FROM 
			#TradePrice
		WHERE 
			@fileName NOT IN (SELECT DISTINCT [FileName] FROM [dbo].[StockTrade])
		ORDER BY
			[DayNo] ASC;
			
		SET IDENTITY_INSERT [dbo].[StockTrade] OFF;


		SET @messageString = 'Create Results temp table';

		IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results		
		CREATE TABLE #Results
		(
			[BuyDayOfMonth]			INT,
			[BuyTradePriceOfDay]	DECIMAL(28, 2),
			[SellDayOfMonth]		INT,
			[SellTradePriceOfDay]   DECIMAL(28, 2),
			[DaysBetweenBuySell]	INT,
			[TradeGain]				DECIMAL(28, 2)
		);


		SET @messageString = 'Set min and max day variables if not provided';

		IF @minBuyDay IS NULL
		SELECT @minBuyDay = MIN([DayNo]) FROM [dbo].[StockTrade];

		IF @maxBuyDay IS NULL
		SELECT @maxBuyDay = MAX([DayNo]) FROM [dbo].[StockTrade];
		

		SET @messageString = 'Check if min day exists';

		IF NOT EXISTS (SELECT [DayNo] FROM [dbo].[StockTrade] WHERE [DayNo] = @minBuyDay)
		BEGIN
			DECLARE @valueMin INT = (SELECT MAX([DayNo]) - 1 FROM [dbo].[StockTrade]);

			SET @messageString = 'Min day ' + CONVERT(NVARCHAR(MAX), @minBuyDay) + ' does not exists. The lowest possible value is: ' + CONVERT(NVARCHAR(MAX), @valueMin);
			RAISERROR(@messageString, 16, 0) WITH NOWAIT;
		END;
				

		SET @messageString = 'Check if max day exists';

		IF NOT EXISTS (SELECT [DayNo] FROM [dbo].[StockTrade] WHERE [DayNo] = @maxBuyDay)
		BEGIN
			DECLARE @valueMax INT = (SELECT MAX([DayNo]) FROM [dbo].[StockTrade]);

			SET @messageString = 'Max day ' + CONVERT(NVARCHAR(MAX), @maxBuyDay) + ' does not exists. The lowest possible value is: ' + CONVERT(NVARCHAR(MAX), @valueMax);
			RAISERROR(@messageString, 16, 0) WITH NOWAIT;
		END;
		

		SET @messageString = 'Rank all trades available if @dayNo set to 0';
		
		IF @dayDiff = 0 
		SELECT @dayDiff = MAX([DayNo]) FROM [dbo].[StockTrade];


		IF @bestTrade = 0 AND @dayDiff <> 0
		BEGIN

			SET @messageString = 'Calculate the best deal only for day difference value';

			INSERT INTO #Results
			(
				[BuyDayOfMonth],
				[BuyTradePriceOfDay],
				[SellDayOfMonth],
				[SellTradePriceOfDay],  
				[DaysBetweenBuySell],
				[TradeGain]
			)
			SELECT TOP 1
				st1.[DayNo]							AS [BuyDayOfMonth], 
				st1.[TradePrice]					AS [BuyTradePriceOfDay],
				st2.[DayNo]							AS [SellDayOfMonth], 
				st2.[TradePrice]					AS [SellTradePriceOfDay],
				@dayDiff							AS [DaysBetweenSellBuy],
				st2.[TradePrice] - st1.[TradePrice] AS [TradeGain]
			FROM 
				[dbo].[StockTrade] st1
			INNER JOIN
				[dbo].[StockTrade] st2
				ON st1.[DayNo] + @dayDiff = st2.[DayNo] 
				AND st2.[DayNo] BETWEEN @minBuyDay AND @maxBuyDay + @dayDiff
			ORDER BY
				[TradeGain] DESC;
			
			SELECT
				CONVERT(NVARCHAR(MAX), [BuyDayOfMonth]) + '(' + CONVERT(NVARCHAR(MAX), [BuyTradePriceOfDay]) + '),' + CONVERT(NVARCHAR(MAX), [SellDayOfMonth]) + '(' + CONVERT(NVARCHAR(MAX), [SellTradePriceOfDay]) + ')' AS [RequestedFormat],
				[BuyDayOfMonth],
				[BuyTradePriceOfDay],
				[SellDayOfMonth],
				[SellTradePriceOfDay],  
				[DaysBetweenBuySell],
				[TradeGain] 
			FROM 
				#Results;

		END
		ELSE
		BEGIN
		
			SET @messageString = 'Calculate the best deals for all days within day difference value';

			DECLARE @run INT = 1;

			IF @dayDiff = 0
			SELECT @dayDiff = Max([DayNo]) FROM [StockTrade];
			
			WHILE @run <= @dayDiff
			BEGIN

				INSERT INTO #Results
				(
					[BuyDayOfMonth],
					[BuyTradePriceOfDay],
					[SellDayOfMonth],
					[SellTradePriceOfDay],  
					[DaysBetweenBuySell],
					[TradeGain]
				)
				SELECT TOP 1
					st1.[DayNo]							AS [BuyDayOfMonth], 
					st1.[TradePrice]					AS [BuyTradePriceOfDay],
					st2.[DayNo]							AS [SellDayOfMonth], 
					st2.[TradePrice]					AS [SellTradePriceOfDay],
					@run								AS [DaysBetweenSellBuy],
					st2.[TradePrice] - st1.[TradePrice] AS [TradeGain]
				FROM 
					[dbo].[StockTrade] st1
				INNER JOIN
					[dbo].[StockTrade] st2
					ON st1.[DayNo] + @run = st2.[DayNo] 
					AND st1.[DayNo] BETWEEN @minBuyDay AND @maxBuyDay + @dayDiff
				ORDER BY
					[TradeGain] DESC;
					
				SET @run = @run + 1;

			END	

			SELECT 	
				CONVERT(NVARCHAR(MAX), [BuyDayOfMonth]) + '(' + CONVERT(NVARCHAR(MAX), [BuyTradePriceOfDay]) + '),' + CONVERT(NVARCHAR(MAX), [SellDayOfMonth]) + '(' + CONVERT(NVARCHAR(MAX), [SellTradePriceOfDay]) + ')' AS [RequestedFormat],
				[BuyDayOfMonth],
				[BuyTradePriceOfDay],
				[SellDayOfMonth],
				[SellTradePriceOfDay],  
				[DaysBetweenBuySell],
				[TradeGain] 
			FROM 
				#Results
			ORDER BY 
				[TradeGain] DESC;
				
		END


    COMMIT TRANSACTION;  
END TRY  
BEGIN CATCH  

    IF (XACT_STATE()) = -1  
    BEGIN  
		DECLARE @ErrorSeverity INT;  
		DECLARE @ErrorState INT;  
  
		SELECT    
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();

        PRINT 'The transaction is in an uncommittable state.' + ' Rolling back transaction.';
        ROLLBACK TRANSACTION;
		
		RAISERROR 
		(
			@messageString,  
			@ErrorSeverity,  
			@ErrorState
		);  
    END;
  
    IF (XACT_STATE()) = 1  
    BEGIN  
        PRINT 'The transaction is committable.' + ' Committing transaction.';
        COMMIT TRANSACTION;
    END;

END CATCH;
GO
