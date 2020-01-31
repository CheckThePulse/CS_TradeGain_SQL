# CS_TradeGain_SQL
Development script for an interview task to calculate the highest trade gain from loaded data.
InterviewScript is a deployment script that will install all required objects.
The deployment script also enables xp_cmdshell to run multiple file loads.
Please ensure the user running stored procedure in test scenarios has access to the file path and can run the procedures on the SQL server.
Please make yourself familiar with all variables running this proc. The default settings allow running the SP providing the only @fullPath. However additional data manipulation is possible - please see TestScenarios.sql 

Test files attached.
