-- =============================================
-- CREATE OLTP DATABASE (Transactional System)
-- =============================================
USE master;
GO

-- Create OLTP Database
CREATE DATABASE Healthcare_OLTP;
GO

USE Healthcare_OLTP;
GO

-- Enable CDC for Change Data Capture (Optional Enhancement)
EXEC sys.sp_cdc_enable_db;
GO

-- =============================================
-- CREATE TABLES WITH SAMPLE DATA
-- =============================================

-- 1. Providers Table
CREATE TABLE Providers (
    ProviderID INT IDENTITY(1,1) PRIMARY KEY,
    NPI_Number CHAR(10) UNIQUE NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    FullName AS (FirstName + ' ' + LastName),
    Specialty VARCHAR(100) NOT NULL,
    SubSpecialty VARCHAR(100),
    LicenseNumber VARCHAR(50),
    LicenseState CHAR(2) NOT NULL,
    YearsOfExperience INT CHECK (YearsOfExperience >= 0),
    MedicalSchool VARCHAR(200),
    GraduationYear INT,
    HospitalAffiliation VARCHAR(200),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);

-- Insert Sample Providers (50 records)
INSERT INTO Providers (NPI_Number, FirstName, LastName, Specialty, SubSpecialty, LicenseState, YearsOfExperience, MedicalSchool, HospitalAffiliation)
VALUES 
('1234567890', 'James', 'Wilson', 'Cardiology', 'Interventional Cardiology', 'NY', 15, 'Harvard Medical School', 'Mount Sinai Hospital'),
('2345678901', 'Sarah', 'Johnson', 'Pediatrics', 'Neonatology', 'CA', 8, 'Stanford University School of Medicine', 'UCLA Medical Center'),
('3456789012', 'Michael', 'Brown', 'Orthopedics', 'Sports Medicine', 'TX', 20, 'Johns Hopkins School of Medicine', 'Texas Medical Center'),
('4567890123', 'Emily', 'Davis', 'Dermatology', 'Cosmetic Dermatology', 'FL', 12, 'Mayo Clinic School of Medicine', 'Cleveland Clinic Florida'),
('5678901234', 'Robert', 'Miller', 'Neurology', 'Epilepsy', 'IL', 18, 'University of Chicago Medical School', 'Northwestern Memorial Hospital'),
('6789012345', 'Jennifer', 'Taylor', 'Oncology', 'Medical Oncology', 'MA', 10, 'Boston University School of Medicine', 'Massachusetts General Hospital'),
('7890123456', 'William', 'Anderson', 'Surgery', 'Cardiothoracic Surgery', 'PA', 25, 'University of Pennsylvania Medical School', 'Hospital of University of Pennsylvania'),
('8901234567', 'Lisa', 'Thomas', 'Psychiatry', 'Child Psychiatry', 'CA', 7, 'University of California, San Francisco', 'Stanford Health Care'),
('9012345678', 'David', 'Martinez', 'Family Medicine', NULL, 'TX', 5, 'University of Texas Medical School', 'Houston Methodist Hospital'),
('0123456789', 'Amanda', 'Garcia', 'Obstetrics', 'Maternal-Fetal Medicine', 'FL', 14, 'University of Miami Medical School', 'Jackson Memorial Hospital');

-- Add 40 more providers
DECLARE @i INT = 11;
WHILE @i <= 50
BEGIN
    INSERT INTO Providers (NPI_Number, FirstName, LastName, Specialty, LicenseState, YearsOfExperience)
    VALUES (
        RIGHT('0000000000' + CAST(@i * 1234567 AS VARCHAR(10)), 10),
        CASE (@i % 5)
            WHEN 0 THEN 'Christopher' WHEN 1 THEN 'Jessica' WHEN 2 THEN 'Matthew' 
            WHEN 3 THEN 'Ashley' WHEN 4 THEN 'Daniel'
        END,
        CASE (@i % 6)
            WHEN 0 THEN 'Rodriguez' WHEN 1 THEN 'Lee' WHEN 2 THEN 'Walker'
            WHEN 3 THEN 'Young' WHEN 4 THEN 'King' WHEN 5 THEN 'Scott'
        END,
        CASE (@i % 8)
            WHEN 0 THEN 'Cardiology' WHEN 1 THEN 'Pediatrics' WHEN 2 THEN 'Orthopedics'
            WHEN 3 THEN 'Dermatology' WHEN 4 THEN 'Neurology' WHEN 5 THEN 'Oncology'
            WHEN 6 THEN 'Surgery' WHEN 7 THEN 'Psychiatry'
        END,
        CASE (@i % 4)
            WHEN 0 THEN 'CA' WHEN 1 THEN 'TX' WHEN 2 THEN 'NY' WHEN 3 THEN 'FL'
        END,
        (@i % 30) + 1
    );
    SET @i = @i + 1;
END;
GO

-- 2. Patients Table
CREATE TABLE Patients (
    PatientID INT IDENTITY(1,1) PRIMARY KEY,
    MRN_Number VARCHAR(20) UNIQUE NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    FullName AS (FirstName + ' ' + LastName),
    DateOfBirth DATE NOT NULL,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F', 'O')),
    SSN_Last4 CHAR(4),
    Email VARCHAR(100),
    Phone VARCHAR(20),
    AddressLine1 VARCHAR(200),
    City VARCHAR(100),
    State CHAR(2),
    ZipCode VARCHAR(10),
    PrimaryInsurance VARCHAR(100),
    InsuranceID VARCHAR(50),
    EmergencyContact VARCHAR(100),
    EmergencyPhone VARCHAR(20),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Insert Sample Patients (200 records)
DECLARE @j INT = 1;
WHILE @j <= 200
BEGIN
    INSERT INTO Patients (MRN_Number, FirstName, LastName, DateOfBirth, Gender, State, PrimaryInsurance)
    VALUES (
        'MRN' + RIGHT('000000' + CAST(@j AS VARCHAR(10)), 6),
        CASE (@j % 10)
            WHEN 0 THEN 'John' WHEN 1 THEN 'Mary' WHEN 2 THEN 'David' WHEN 3 THEN 'Lisa'
            WHEN 4 THEN 'Paul' WHEN 5 THEN 'Karen' WHEN 6 THEN 'Mark' WHEN 7 THEN 'Nancy'
            WHEN 8 THEN 'Steve' WHEN 9 THEN 'Laura'
        END,
        CASE (@j % 12)
            WHEN 0 THEN 'Smith' WHEN 1 THEN 'Johnson' WHEN 2 THEN 'Williams' WHEN 3 THEN 'Jones'
            WHEN 4 THEN 'Brown' WHEN 5 THEN 'Davis' WHEN 6 THEN 'Miller' WHEN 7 THEN 'Wilson'
            WHEN 8 THEN 'Moore' WHEN 9 THEN 'Taylor' WHEN 10 THEN 'Anderson' WHEN 11 THEN 'Thomas'
        END,
        DATEADD(YEAR, -(@j % 80 + 18), DATEADD(DAY, @j % 365, '2000-01-01')),
        CASE (@j % 3) WHEN 0 THEN 'M' WHEN 1 THEN 'F' WHEN 2 THEN 'O' END,
        CASE (@j % 8)
            WHEN 0 THEN 'CA' WHEN 1 THEN 'TX' WHEN 2 THEN 'NY' WHEN 3 THEN 'FL'
            WHEN 4 THEN 'IL' WHEN 5 THEN 'PA' WHEN 6 THEN 'OH' WHEN 7 THEN 'GA'
        END,
        CASE (@j % 5)
            WHEN 0 THEN 'Blue Cross' WHEN 1 THEN 'Aetna' WHEN 2 THEN 'UnitedHealth'
            WHEN 3 THEN 'Cigna' WHEN 4 THEN 'Medicare'
        END
    );
    SET @j = @j + 1;
END;
GO

-- 3. Appointments Table
CREATE TABLE Appointments (
    AppointmentID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    ProviderID INT NOT NULL FOREIGN KEY REFERENCES Providers(ProviderID),
    AppointmentDate DATETIME NOT NULL,
    AppointmentType VARCHAR(50) CHECK (AppointmentType IN ('New Patient', 'Follow-up', 'Consultation', 'Procedure', 'Emergency')),
    Status VARCHAR(20) CHECK (Status IN ('Scheduled', 'Completed', 'Cancelled', 'No-show')),
    ReasonForVisit VARCHAR(200),
    RoomNumber VARCHAR(20),
    DurationMinutes INT DEFAULT 30,
    IsNoShow BIT DEFAULT 0,
    CancellationReason VARCHAR(200),
    CreatedBy VARCHAR(50),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);

-- Insert Sample Appointments (1000 records)
DECLARE @k INT = 1;
WHILE @k <= 1000
BEGIN
    INSERT INTO Appointments (PatientID, ProviderID, AppointmentDate, AppointmentType, Status, DurationMinutes, IsNoShow)
    VALUES (
        (SELECT TOP 1 PatientID FROM Patients ORDER BY NEWID()),
        (SELECT TOP 1 ProviderID FROM Providers ORDER BY NEWID()),
        DATEADD(DAY, -(@k % 365), DATEADD(HOUR, (@k % 10) + 8, GETDATE())),
        CASE (@k % 5)
            WHEN 0 THEN 'New Patient' WHEN 1 THEN 'Follow-up' WHEN 2 THEN 'Consultation'
            WHEN 3 THEN 'Procedure' WHEN 4 THEN 'Emergency'
        END,
        CASE (@k % 100)
            WHEN 0 THEN 'No-show' 
            WHEN 1 THEN 'Cancelled'
            ELSE 'Completed'
        END,
        CASE (@k % 4)
            WHEN 0 THEN 15 WHEN 1 THEN 30 WHEN 2 THEN 45 WHEN 3 THEN 60
        END,
        CASE WHEN @k % 100 = 0 THEN 1 ELSE 0 END
    );
    SET @k = @k + 1;
END;
GO

-- 4. MedicalRecords Table
CREATE TABLE MedicalRecords (
    RecordID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    ProviderID INT NOT NULL FOREIGN KEY REFERENCES Providers(ProviderID),
    VisitDate DATE NOT NULL,
    DiagnosisCode VARCHAR(20),
    DiagnosisDescription VARCHAR(500),
    ProcedureCode VARCHAR(20),
    ProcedureDescription VARCHAR(500),
    ICD10_Code VARCHAR(10),
    CPT_Code VARCHAR(10),
    Medications VARCHAR(1000),
    Notes TEXT,
    FollowUpDate DATE,
    IsChronic BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Common ICD-10 Codes for sample data
DECLARE @ICD10_Codes TABLE (Code VARCHAR(10), Description VARCHAR(200));
INSERT INTO @ICD10_Codes VALUES
('I10', 'Essential (primary) hypertension'),
('E11.9', 'Type 2 diabetes mellitus without complications'),
('J06.9', 'Acute upper respiratory infection, unspecified'),
('M54.5', 'Low back pain'),
('K21.9', 'Gastro-esophageal reflux disease without esophagitis'),
('F41.9', 'Anxiety disorder, unspecified'),
('E78.5', 'Hyperlipidemia, unspecified'),
('J44.9', 'Chronic obstructive pulmonary disease, unspecified'),
('I25.10', 'Atherosclerotic heart disease of native coronary artery without angina pectoris'),
('N39.0', 'Urinary tract infection, site not specified');

-- Insert Sample Medical Records (500 records)
DECLARE @m INT = 1;
WHILE @m <= 500
BEGIN
    DECLARE @ICDCode VARCHAR(10), @ICDDesc VARCHAR(200);
    SELECT TOP 1 @ICDCode = Code, @ICDDesc = Description 
    FROM @ICD10_Codes 
    ORDER BY NEWID();
    
    INSERT INTO MedicalRecords (PatientID, ProviderID, VisitDate, DiagnosisCode, DiagnosisDescription, ICD10_Code, Medications, IsChronic)
    VALUES (
        (SELECT TOP 1 PatientID FROM Patients ORDER BY NEWID()),
        (SELECT TOP 1 ProviderID FROM Providers ORDER BY NEWID()),
        DATEADD(DAY, -(@m % 365), GETDATE()),
        'DX' + RIGHT('0000' + CAST((@m % 1000) AS VARCHAR(4)), 4),
        @ICDDesc,
        @ICDCode,
        CASE (@m % 7)
            WHEN 0 THEN 'Lisinopril 10mg daily'
            WHEN 1 THEN 'Metformin 500mg twice daily'
            WHEN 2 THEN 'Atorvastatin 20mg daily'
            WHEN 3 THEN 'Albuterol inhaler as needed'
            WHEN 4 THEN 'Ibuprofen 400mg as needed'
            WHEN 5 THEN 'Omeprazole 20mg daily'
            WHEN 6 THEN 'Sertraline 50mg daily'
        END,
        CASE WHEN @m % 5 = 0 THEN 1 ELSE 0 END
    );
    SET @m = @m + 1;
END;
GO

-- 5. ProviderCredentials Table
CREATE TABLE ProviderCredentials (
    CredentialID INT IDENTITY(1,1) PRIMARY KEY,
    ProviderID INT NOT NULL FOREIGN KEY REFERENCES Providers(ProviderID),
    Degree VARCHAR(50),
    MedicalSchool VARCHAR(200),
    GraduationYear INT,
    BoardCertification VARCHAR(100),
    CertificationDate DATE,
    ExpirationDate DATE,
    LicenseExpiration DATE,
    DEA_Number VARCHAR(20),
    IsBoardCertified BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Insert Sample Credentials
INSERT INTO ProviderCredentials (ProviderID, Degree, MedicalSchool, BoardCertification, IsBoardCertified)
SELECT 
    ProviderID,
    CASE Specialty
        WHEN 'Cardiology' THEN 'MD, Cardiology'
        WHEN 'Pediatrics' THEN 'MD, Pediatrics'
        WHEN 'Orthopedics' THEN 'MD, Orthopedic Surgery'
        ELSE 'MD'
    END,
    MedicalSchool,
    CASE WHEN ProviderID % 3 = 0 THEN 'American Board of ' + Specialty ELSE NULL END,
    CASE WHEN ProviderID % 3 = 0 THEN 1 ELSE 0 END
FROM Providers;
GO

-- 6. PatientFeedback Table
CREATE TABLE PatientFeedback (
    FeedbackID INT IDENTITY(1,1) PRIMARY KEY,
    AppointmentID INT FOREIGN KEY REFERENCES Appointments(AppointmentID),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    ProviderID INT NOT NULL FOREIGN KEY REFERENCES Providers(ProviderID),
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    WaitTimeRating INT CHECK (WaitTimeRating BETWEEN 1 AND 5),
    CommunicationRating INT CHECK (CommunicationRating BETWEEN 1 AND 5),
    CleanlinessRating INT CHECK (CleanlinessRating BETWEEN 1 AND 5),
    OverallExperience INT CHECK (OverallExperience BETWEEN 1 AND 10),
    Comments TEXT,
    WouldRecommend BIT,
    FeedbackDate DATE DEFAULT GETDATE(),
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Insert Sample Feedback (300 records)
DECLARE @f INT = 1;
WHILE @f <= 300
BEGIN
    INSERT INTO PatientFeedback (AppointmentID, PatientID, ProviderID, Rating, WaitTimeRating, CommunicationRating, OverallExperience, WouldRecommend)
    VALUES (
        (SELECT TOP 1 AppointmentID FROM Appointments WHERE Status = 'Completed' ORDER BY NEWID()),
        (SELECT TOP 1 PatientID FROM Patients ORDER BY NEWID()),
        (SELECT TOP 1 ProviderID FROM Providers ORDER BY NEWID()),
        CASE (@f % 20)
            WHEN 0 THEN 1
            WHEN 1 THEN 2
            WHEN 2 THEN 3
            ELSE 4 + (@f % 2)
        END,
        3 + (@f % 3),
        4 + (@f % 2),
        6 + (@f % 4),
        CASE WHEN @f % 10 > 1 THEN 1 ELSE 0 END
    );
    SET @f = @f + 1;
END;
GO

-- 7. Billing Table (Additional)
CREATE TABLE Billing (
    BillID INT IDENTITY(1,1) PRIMARY KEY,
    AppointmentID INT FOREIGN KEY REFERENCES Appointments(AppointmentID),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    ProviderID INT NOT NULL FOREIGN KEY REFERENCES Providers(ProviderID),
    ServiceDate DATE NOT NULL,
    CPT_Code VARCHAR(10),
    Description VARCHAR(200),
    Amount DECIMAL(10,2),
    InsurancePaid DECIMAL(10,2),
    PatientPaid DECIMAL(10,2),
    Balance DECIMAL(10,2),
    Status VARCHAR(20) CHECK (Status IN ('Pending', 'Submitted', 'Paid', 'Denied', 'Appealed')),
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Insert Sample Billing Records
INSERT INTO Billing (AppointmentID, PatientID, ProviderID, ServiceDate, Amount, InsurancePaid, Status)
SELECT TOP 200
    a.AppointmentID,
    a.PatientID,
    a.ProviderID,
    CAST(a.AppointmentDate AS DATE),
    CASE 
        WHEN a.AppointmentType = 'New Patient' THEN 200.00
        WHEN a.AppointmentType = 'Follow-up' THEN 100.00
        WHEN a.AppointmentType = 'Procedure' THEN 500.00
        ELSE 150.00
    END,
    CASE 
        WHEN a.AppointmentType = 'New Patient' THEN 160.00
        WHEN a.AppointmentType = 'Follow-up' THEN 80.00
        WHEN a.AppointmentType = 'Procedure' THEN 400.00
        ELSE 120.00
    END,
    CASE (@f % 5)
        WHEN 0 THEN 'Pending' WHEN 1 THEN 'Submitted' WHEN 2 THEN 'Paid' 
        WHEN 3 THEN 'Denied' WHEN 4 THEN 'Appealed'
    END
FROM Appointments a
WHERE a.Status = 'Completed';
GO

-- Create Indexes for Performance
CREATE INDEX IX_Appointments_Provider ON Appointments(ProviderID);
CREATE INDEX IX_Appointments_Patient ON Appointments(PatientID);
CREATE INDEX IX_Appointments_Date ON Appointments(AppointmentDate);
CREATE INDEX IX_MedicalRecords_Patient ON MedicalRecords(PatientID);
CREATE INDEX IX_MedicalRecords_Provider ON MedicalRecords(ProviderID);
CREATE INDEX IX_Feedback_Provider ON PatientFeedback(ProviderID);
GO

-- Create Views for Common Queries
CREATE VIEW vw_ProviderAppointments AS
SELECT 
    p.ProviderID,
    p.FullName AS ProviderName,
    p.Specialty,
    COUNT(a.AppointmentID) AS TotalAppointments,
    SUM(CASE WHEN a.Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedAppointments,
    SUM(CASE WHEN a.Status = 'No-show' THEN 1 ELSE 0 END) AS NoShowAppointments,
    AVG(CASE WHEN a.Status = 'Completed' THEN a.DurationMinutes END) AS AvgDuration
FROM Providers p
LEFT JOIN Appointments a ON p.ProviderID = a.ProviderID
GROUP BY p.ProviderID, p.FullName, p.Specialty;
GO

CREATE VIEW vw_PatientVisits AS
SELECT 
    pat.PatientID,
    pat.FullName AS PatientName,
    pat.State,
    COUNT(DISTINCT mr.VisitDate) AS TotalVisits,
    COUNT(DISTINCT mr.ProviderID) AS UniqueProviders,
    MIN(mr.VisitDate) AS FirstVisitDate,
    MAX(mr.VisitDate) AS LastVisitDate
FROM Patients pat
LEFT JOIN MedicalRecords mr ON pat.PatientID = mr.PatientID
GROUP BY pat.PatientID, pat.FullName, pat.State;
GO