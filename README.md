# CS_TradeGain_SQL
Solution for an interview task to calculate the highest trade gain from loaded data.
InterviewScript is a deployment script that will install and configure all required objects:
- Enable x-_cmdshell
- Database CS_TradeGain_SQL
- Table StockTrade
- Stored Procedure 

Installation:
Open SSMS and connect to your test server. 
Run InterviewScript.sql (script can be rerun).

Remarks:
The deployment script also enables xp_cmdshell to run multiple file loads.
Please ensure the user running stored procedure in test scenarios has access to the file path and can run the procedures on the SQL server.
Please make yourself familiar with all variables running this proc. The default settings allow running the SP providing the only @fullPath. However additional data manipulation is possible - please see TestScenarios.sql
Variables description and default values:
- @dayDiff	= 1, --if set to 0 it will run for all possible days otherwise it is a value of days between buy and sell.
-	@bestTrade	= 0, --if set to 1 and dayDiff grater from 1 then SP will rank all days within dayDiff.
-	@allFiles	= 0, -- 0 loads only one selected file and 1 run all files in the folder. Files have to be in alphabetical order without special characters ChallengeSampleDataSet1, ChallengeSampleDataSet2, ChallengeSampleDataSet3 available in folder.
-	@fullPath	= NULL, --UNC standard. The maximum length for a path is MAX_PATH, which is defined as 260 characters. Win 10 allows overriding this setting. Mandatory variable.
- @minBuyDay  = NULL, --select minimum opening trade date. If Null is selected will be a minimum value from the data loaded.
- @maxBuyDay  = NULL --select maximum opening trade date. If Null is selected will be a maximum value from the data loaded.

Test files attached.
