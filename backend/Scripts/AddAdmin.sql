USE [IB210131]
GO

IF NOT EXISTS (SELECT 1 FROM Administrators WHERE Username = 'admin')
BEGIN
    INSERT INTO Administrators (Username, Email, PasswordHash, FirstName, LastName, IsActive, CreatedAt)
    VALUES ('admin', 'admin@transitflow.com', 'jGl25bVBBBW96Qi9Te4V37Fnqchz/Eu4qB9vKrRIqRg=', 'Admin', 'User', 1, GETUTCDATE())
END
GO
