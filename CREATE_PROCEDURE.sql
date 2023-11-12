GO 
-- Сформировать запросы, которые бы позволили просмотреть заказы по дате создания.
CREATE PROCEDURE GetOrdersByDate
    @TargetDate DATE
AS
BEGIN
    SELECT *
    FROM ServiceOrders
    WHERE OrderDate = @TargetDate
    ORDER BY OrderDate DESC;
END;
GO 
-- EXEC GetOrdersByDate '2023-11-02';
--------------------------------------------------------------------------------------
-- Сформировать запросы, которые бы позволили пользователю сориентироваться в перечне  услуг (использовать фильтры: наименование, стоимость).
CREATE PROCEDURE GetServicesByFilter
    @ServiceNameFilter VARCHAR(100) = NULL,
    @MinAmount DECIMAL(10, 2) = NULL,
    @MaxAmount DECIMAL(10, 2) = NULL
AS
BEGIN
    SELECT *
    FROM Services
    WHERE
        (@ServiceNameFilter IS NULL OR ServiceName LIKE '%' + @ServiceNameFilter + '%')
        AND (@MinAmount IS NULL OR ServiceAmount >= @MinAmount)
        AND (@MaxAmount IS NULL OR ServiceAmount <= @MaxAmount);
END;
GO 
-- EXEC GetServicesByFilter;
-- EXEC GetServicesByFilter @ServiceNameFilter = 'услуга 1';
-- EXEC GetServicesByFilter @MinAmount = 100.00, @MaxAmount = 200.00;
-- EXEC GetServicesByFilter @ServiceNameFilter = 'услуга 3', @MinAmount = 100.00, @MaxAmount = 200.00;
--------------------------------------------------------------------------------------
-- Сформировать запросы, которые позволили бы сравнить зарплату бухгалтера и администратора.
CREATE PROCEDURE GetAverageSalaries
AS
BEGIN

    SELECT
        'Administrator' AS Position,
        AVG(T.NewSalary) AS AverageSalary
    FROM (
        SELECT
            A.EmployeeID,
            ESH.NewSalary
        FROM Administratoren A
        JOIN EmployeeSalaryHistory ESH ON A.EmployeeID = ESH.EmployeeID
        JOIN (
            SELECT
                EmployeeID,
                MAX(ChangeDate) AS MaxChangeDate
            FROM EmployeeSalaryHistory
            GROUP BY EmployeeID
        ) T ON ESH.EmployeeID = T.EmployeeID AND ESH.ChangeDate = T.MaxChangeDate
    ) as T
    UNION ALL
    SELECT
        'Buchhalter' AS Position,
        AVG(T.NewSalary) AS AverageSalary
    FROM (	
        SELECT
            B.EmployeeID,
            ESH.NewSalary
        FROM Buchhalters B
        JOIN EmployeeSalaryHistory ESH ON B.EmployeeID = ESH.EmployeeID
        JOIN (
            SELECT
                EmployeeID,
                MAX(ChangeDate) AS MaxChangeDate
            FROM EmployeeSalaryHistory
            GROUP BY EmployeeID
        ) T ON ESH.EmployeeID = T.EmployeeID AND ESH.ChangeDate = T.MaxChangeDate
    ) AS T


END;
GO 
-- EXEC GetAverageSalaries;
--------------------------------------------------------------------------------------
-- Сформировать запрос, который позволит  рассчитать общую  стоимость  услуг за указанную дату;
CREATE PROCEDURE CalculateTotalServiceCost
    @TargetDate DATE
AS
BEGIN
    SELECT SUM(PaymentAmount) AS TotalServiceCost
    FROM Payments P
    JOIN ServiceOrders SO ON P.PaymentID = SO.PaymentID
    WHERE SO.OrderDate = @TargetDate;
END;
GO 
-- EXEC CalculateTotalServiceCost @TargetDate = '2023-11-10'
--------------------------------------------------------------------------------------
-- Реализовать подсчет общей суммы услуг с учетом скидки клиента.
CREATE PROCEDURE CalculateDiscountedAmount
    @ServiceOrdersID INT
AS
BEGIN
    DECLARE @TotalAmount DECIMAL(10, 2);
    DECLARE @DiscountPercentage DECIMAL(5, 2);
    DECLARE @DiscountedAmount DECIMAL(10, 2);

    -- Вычисление общей суммы заказанных услуг
    SELECT @TotalAmount = SUM(S.ServiceAmount)
    FROM ServiceOrders SO
    JOIN ServiceOrdersServices SOS ON SO.ServiceOrdersID = SOS.ServiceOrdersID
    JOIN Services S ON SOS.ServiceID = S.ServiceID
    WHERE SO.ServiceOrdersID = @ServiceOrdersID;

    -- Получение процента скидки из таблицы ListWeeklyDiscounts
    SELECT @DiscountPercentage = LWD.DiscountPercentage
    FROM ServiceOrders SO
    LEFT JOIN ListWeeklyDiscounts LWD ON SO.ListWeeklyDiscountID = LWD.ListWeeklyDiscountID
    WHERE SO.ServiceOrdersID = @ServiceOrdersID;

    -- Рассчет суммы с учетом скидки
    SET @DiscountedAmount = @TotalAmount - (@TotalAmount * @DiscountPercentage / 100);

    -- Вывод результатов
    SELECT
        @TotalAmount AS OriginalAmount,
        @DiscountPercentage AS DiscountPercentage,
        @DiscountedAmount AS DiscountedAmount;
END;
GO 
-- EXEC CalculateDiscountedAmount @ServiceOrdersID = 1;
--------------------------------------------------------------------------------------
-- Для выбранного клиента  предусмотреть  возможность просмотра истории ранее пройденных услуг.
CREATE PROCEDURE GetServiceHistoryForUser
    @SelectedUserID INT
AS
BEGIN
    SELECT U.FirstName, U.LastName, SO.OrderDate, S.ServiceName, SO.OrderDescription
    FROM Users U
    JOIN Patients P ON U.UserID = P.UserID
    JOIN ServiceOrders SO ON P.PatientID = SO.PatientID
    JOIN ServiceOrdersServices SOS ON SO.ServiceOrdersID = SOS.ServiceOrdersID
    JOIN Services S ON SOS.ServiceID = S.ServiceID
    WHERE U.UserID = @SelectedUserID;
END;
GO 
-- EXEC GetServiceHistoryForUser @SelectedUserID = 1; -- Замените на нужный UserID
--------------------------------------------------------------------------------------
-- Сформировать запрос, который позволит просмотреть все отзывы, оставленные на сайте
CREATE PROCEDURE GetFeedbacks
AS
BEGIN
    SELECT Users.FirstName, Users.LastName, Feedback.FeedbackDate, Feedback.Rating, Feedback.FeedbackText
    FROM Feedback
    INNER JOIN Patients ON Feedback.PatientID = Patients.PatientID
    INNER JOIN Users ON Patients.UserID = Users.UserID;
END;
GO 
-- EXEC GetFeedbacks;
--------------------------------------------------------------------------------------
-- Создать запрос, который будет отображать скидки на определенные услуги в пятницу.
CREATE PROCEDURE GetFridayDiscounts
AS
BEGIN
	SELECT
		S.ServiceName,
		LWD.DiscountPercentage,
		DT.TargetName
	FROM ListWeeklyDiscounts LWD
	JOIN DiscountPeriods D ON LWD.DiscountPeriodID = D.DiscountPeriodID
	JOIN Services S ON LWD.ServiceID = S.ServiceID
	JOIN DiscountTargets DT ON LWD.DiscountTargetID = DT.DiscountTargetID
	WHERE D.StartDate = 5 AND D.EndDate = 5;
END;
GO 
-- EXEC GetFridayDiscounts;
--------------------------------------------------------------------------------------
CREATE PROCEDURE GetCountTable
AS
BEGIN
    SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES
END;
GO
-- EXEC GetCountTable


-- All commands
-- EXEC GetOrdersByDate '2023-11-02';
-------------------------------------
-- EXEC GetServicesByFilter;
-- EXEC GetServicesByFilter @ServiceNameFilter = 'услуга 1';
-- EXEC GetServicesByFilter @MinAmount = 100.00, @MaxAmount = 200.00;
-- EXEC GetServicesByFilter @ServiceNameFilter = 'услуга 3', @MinAmount = 100.00, @MaxAmount = 200.00;
-------------------------------------
-- EXEC GetAverageSalaries;
-------------------------------------
-- EXEC CalculateDiscountedAmount @ServiceOrdersID = 1;
-------------------------------------
-- EXEC GetServiceHistoryForUser @SelectedUserID = 1; -- Замените на нужный UserID
-------------------------------------
-- EXEC GetFeedbacks;
-------------------------------------
-- EXEC GetFridayDiscounts;
-------------------------------------
-- EXEC GetCountTable
