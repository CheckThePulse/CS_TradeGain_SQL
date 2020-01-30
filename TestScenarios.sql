--TEST CASE 1
--User didn't provide the @fullPath varaible

EXEC [dbo].[TradeCalculation] 
	@fullPath	= NULL;

--Expected Error: Please provide full file path and rerun stored procedure

--TEST CASE 2
--Invalid file/path/file content
EXEC [dbo].[TradeCalculation] 
	@fullPath	= 'C:\Temp\ChallengeSampleDataSet2';

--Expected Error: Single run. Please check file path, name and format.

--TEST CASE 3
--Run best deal report from loaded file with 1 day between buy and sell date
EXEC [dbo].[TradeCalculation] 
	@fullPath	= 'C:\Temp\ChallengeSampleDataSet2.txt';

--Expected Results: 
--RequestedFormat		BuyDayOfMonth	BuyTradePriceOfDay	SellDayOfMonth	SellTradePriceOfDay	DaysBetweenBuySell	TradeGain
--20(15.79),21(26.19)	20				15.79				21				26.19				1					10.40

--TEST CASE 4
--Run best deal report from loaded file with 2 days between buy and sell date
EXEC [dbo].[TradeCalculation] 
	@dayDiff	= 2, 
	@fullPath	= 'C:\Temp\ChallengeSampleDataSet2.txt';

--Expected Results: 
--RequestedFormat		BuyDayOfMonth	BuyTradePriceOfDay	SellDayOfMonth	SellTradePriceOfDay	DaysBetweenBuySell	TradeGain
--16(16.57),18(25.91)	16				16.57				18				25.91				2					9.34

--TEST CASE 5
--Run best deal report from all files in the folder with 1 days between buy and sell date
EXEC [dbo].[TradeCalculation] 
	@dayDiff	= 1, 
	@fullPath	= 'C:\Temp\ChallengeSampleDataSet2.txt',
	@allFiles	= 1;

--Expected Results: 
--RequestedFormat		BuyDayOfMonth	BuyTradePriceOfDay	SellDayOfMonth	SellTradePriceOfDay	DaysBetweenBuySell	TradeGain
--50(15.79),51(26.19)	50				15.79				51				26.19				1					10.40

--TEST CASE 6
--Run best deal report from one file in the folder with range within 5 days between buy and sell date
EXEC [dbo].[TradeCalculation] 
	@dayDiff	= 5, 
	@fullPath	= 'C:\Temp\ChallengeSampleDataSet2.txt',
	@allFiles	= 0,
	@bestTrade = 1;

--Expected Results: 
--RequestedFormat		BuyDayOfMonth	BuyTradePriceOfDay	SellDayOfMonth	SellTradePriceOfDay	DaysBetweenBuySell	TradeGain
--20(15.79),21(26.19)	20				15.79				21				26.19				1					10.40
--16(16.57),21(26.19)	16				16.57				21				26.19				5					9.62
--16(16.57),18(25.91)	16				16.57				18				25.91				2					9.34
--24(19.02),28(25.94)	24				19.02				28				25.94				4					6.92
--15(19.13),18(25.91)	15				19.13				18				25.91				3					6.78

--TEST CASE 7
--SELECT Minimum buy date
EXEC [dbo].[TradeCalculation] 
	@fullPath	= 'C:\Temp\ChallengeSampleDataSet2.txt',
	@minBuyDay  = 22;

--Expected Results: 
--RequestedFormat		BuyDayOfMonth	BuyTradePriceOfDay	SellDayOfMonth	SellTradePriceOfDay	DaysBetweenBuySell	TradeGain
--27(21.06),28(25.94)	27				21.06				28				25.94				1					4.88


--TEST CASE 8
--SELECT Maximum buy date
EXEC [dbo].[TradeCalculation] 
	@fullPath	= 'C:\Temp\ChallengeSampleDataSet2.txt',
	@maxBuyDay  = 17;

--Expected Results: 
--RequestedFormat		BuyDayOfMonth	BuyTradePriceOfDay	SellDayOfMonth	SellTradePriceOfDay	DaysBetweenBuySell	TradeGain
--16(16.57),17(26.71)	16				16.57				17				26.71				1					10.14

--TEST CASE 9
--SELECT Min > Max buy date
EXEC [dbo].[TradeCalculation] 
	@fullPath	= 'C:\Temp\ChallengeSampleDataSet2.txt',
	@minBuyDay  = 18,
	@maxBuyDay  = 17;

--Expected Results: Warning: The Minimum Buy Day 18 cannot be greater than Maximum Buy Day 17

--TEST CASE 9
--DayDiff set to 0 ranks and displays all data
EXEC [dbo].[TradeCalculation]
	@dayDiff	= 0, --if set to 0 it will run for all possible days otherwise it is a value of days between buy and sell
	@bestTrade	= 1, --If set to one and dayDiff grater from 1 then it SP will rank all days within dayDiff
	@allFiles	= 1, --0 load only 1 selected file and 1 run all files in folder. Files have to be in alphabetical order without special characters ChallengeSampleDataSet1, ChallengeSampleDataSet2, ChallengeSampleDataSet3 available in folder
	@fullPath	= 'C:\Temp\ChallengeSampleDataSet2.txt', --UNC standard. The maximum length for a path is MAX_PATH, which is defined as 260 characters. Win 10 allows to override this setting
	@minBuyDay  = NULL, --select minimum starting opening trade date
	@maxBuyDay  = NULL --select maximum starting opening trade date

--Expected resuls:
--RequestedFormat		BuyDayOfMonth	BuyTradePriceOfDay	SellDayOfMonth	SellTradePriceOfDay	DaysBetweenBuySell	TradeGain
--15(15.28),21(27.39)	15				15.28				21				27.39				6					12.11
--15(15.28),44(27.20)	15				15.28				44				27.20				29					11.92
--15(15.28),19(27.03)	15				15.28				19				27.03				4					11.75
--15(15.28),47(26.71)	15				15.28				47				26.71				32					11.43
--15(15.28),42(26.67)	15				15.28				42				26.67				27					11.39
--15(15.28),18(26.58)	15				15.28				18				26.58				3					11.30
--15(15.28),41(26.56)	15				15.28				41				26.56				26					11.28
--22(15.93),44(27.20)	22				15.93				44				27.20				22					11.27
--6(16.22),21(27.39)	6				16.22				21				27.39				15					11.17
--6(16.22),44(27.20)	6				16.22				44				27.20				38					10.98
--6(16.22),8(27.13)		6				16.22				8				27.13				2					10.91
--15(15.28),51(26.19)	15				15.28				51				26.19				36					10.91
--15(15.28),34(26.15)	15				15.28				34				26.15				19					10.87
--6(16.22),19(27.03)	6				16.22				19				27.03				13					10.81
--4(16.59),21(27.39)	4				16.59				21				27.39				17					10.80
--22(15.93),47(26.71)	22				15.93				47				26.71				25					10.78
--22(15.93),42(26.67)	22				15.93				42				26.67				20					10.74
--15(15.28),43(26.02)	15				15.28				43				26.02				28					10.74
--15(15.28),58(25.94)	15				15.28				58				25.94				43					10.66
--15(15.28),48(25.91)	15				15.28				48				25.91				33					10.63
--4(16.59),44(27.20)	4				16.59				44				27.20				40					10.61
--6(16.22),47(26.71)	6				16.22				47				26.71				41					10.49
--50(15.79),51(26.19)	50				15.79				51				26.19				1					10.40
--6(16.22),18(26.58)	6				16.22				18				26.58				12					10.36
--3(17.05),21(27.39)	3				17.05				21				27.39				18					10.34
--6(16.22),41(26.56)	6				16.22				41				26.56				35					10.34
--50(15.79),58(25.94)	50				15.79				58				25.94				8					10.15
--22(15.93),43(26.02)	22				15.93				43				26.02				21					10.09
--3(17.05),8(27.13)		3				17.05				8				27.13				5					10.08
--15(15.28),26(25.33)	15				15.28				26				25.33				11					10.05
--4(16.59),18(26.58)	4				16.59				18				26.58				14					9.99
--3(17.05),19(27.03)	3				17.05				19				27.03				16					9.98
--4(16.59),41(26.56)	4				16.59				41				26.56				37					9.97
--6(16.22),51(26.19)	6				16.22				51				26.19				45					9.97
--6(16.22),58(25.94)	6				16.22				58				25.94				52					9.72
--6(16.22),48(25.91)	6				16.22				48				25.91				42					9.69
--3(17.05),47(26.71)	3				17.05				47				26.71				44					9.66
--3(17.05),42(26.67)	3				17.05				42				26.67				39					9.62
--4(16.59),51(26.19)	4				16.59				51				26.19				47					9.60
--4(16.59),34(26.15)	4				16.59				34				26.15				30					9.56
--4(16.59),58(25.94)	4				16.59				58				25.94				54					9.35
--3(17.05),51(26.19)	3				17.05				51				26.19				48					9.14
--3(17.05),34(26.15)	3				17.05				34				26.15				31					9.10
--3(17.05),58(25.94)	3				17.05				58				25.94				55					8.89
--23(17.83),47(26.71)	23				17.83				47				26.71				24					8.88
--15(15.28),38(24.11)	15				15.28				38				24.11				23					8.83
--3(17.05),12(25.52)	3				17.05				12				25.52				9					8.47
--9(18.62),19(27.03)	9				18.62				19				27.03				10					8.41
--1(18.93),8(27.13)		1				18.93				8				27.13				7					8.20
--1(18.93),47(26.71)	1				18.93				47				26.71				46					7.78
--4(16.59),38(24.11)	4				16.59				38				24.11				34					7.52
--9(18.62),58(25.94)	9				18.62				58				25.94				49					7.32
--1(18.93),51(26.19)	1				18.93				51				26.19				50					7.26
--1(18.93),58(25.94)	1				18.93				58				25.94				57					7.01
--2(20.25),58(25.94)	2				20.25				58				25.94				56					5.69
--5(21.09),58(25.94)	5				21.09				58				25.94				53					4.85
--6(16.22),57(21.06)	6				16.22				57				21.06				51					4.84
--1(18.93),59(17.03)	1				18.93				59				17.03				58					-1.90
--1(18.93),60(15.61)	1				18.93				60				15.61				59					-3.32