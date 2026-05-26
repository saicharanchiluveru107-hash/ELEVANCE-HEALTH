-- =============================================
-- CREATE OLTP DATABASE WITH SAMPLE DATA
-- =============================================
USE master;
GO

CREATE DATABASE Healthcare_OLTP;
GO

USE Healthcare_OLTP;
GO

-- Enable CDC for auditing
EXEC sys.sp_cdc_enable_db;
GO

-- Create and populate lookup tables first
CREATE TABLE Ref_Specialties (
    SpecialtyID INT PRIMARY KEY IDENTITY(1,1),
    SpecialtyCode VARCHAR(10) UNIQUE NOT NULL,
    SpecialtyName VARCHAR(100) NOT NULL,
    Category VARCHAR(50),
    IsActive BIT DEFAULT 1
);

INSERT INTO Ref_Specialties (SpecialtyCode, SpecialtyName, Category) VALUES
('CARD', 'Cardiology', 'Medical'),
('PEDS', 'Pediatrics', 'Medical'),
('ORTHO', 'Orthopedics', 'Surgical'),
('DERM', 'Dermatology', 'Medical'),
('NEURO', 'Neurology', 'Medical'),
('ONCO', 'Oncology', 'Medical'),
('SURG', 'General Surgery', 'Surgical'),
('PSYCH', 'Psychiatry', 'Behavioral'),
('FMED', 'Family Medicine', 'Primary Care'),
('OBGYN', 'Obstetrics & Gynecology', 'Surgical');

CREATE TABLE Ref_States (
    StateCode CHAR(2) PRIMARY KEY,
    StateName VARCHAR(50) NOT NULL,
    Region VARCHAR(20)
);

INSERT INTO Ref_States VALUES
('CA', 'California', 'West'),
('NY', 'New York', 'Northeast'),
('TX', 'Texas', 'South'),
('FL', 'Florida', 'South'),
('IL', 'Illinois', 'Midwest'),
('PA', 'Pennsylvania', 'Northeast'),
('OH', 'Ohio', 'Midwest'),
('GA', 'Georgia', 'South'),
('NC', 'North Carolina', 'South'),
('MI', 'Michigan', 'Midwest');

-- =============================================
-- MAIN TRANSACTIONAL TABLES
-- =============================================

-- 1. Providers Table (Healthcare Professionals)
CREATE TABLE Providers (
    ProviderID INT PRIMARY KEY IDENTITY(1001,1),
    NPI_Number CHAR(10) UNIQUE NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    FullName AS (FirstName + ' ' + LastName) PERSISTED,
    SpecialtyCode VARCHAR(10) FOREIGN KEY REFERENCES Ref_Specialties(SpecialtyCode),
    LicenseNumber VARCHAR(20),
    LicenseState CHAR(2) FOREIGN KEY REFERENCES Ref_States(StateCode),
    YearsOfExperience INT,
    MedicalSchool VARCHAR(100),
    GraduationYear INT,
    HospitalAffiliation VARCHAR(100),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);

-- Insert 50 sample providers
INSERT INTO Providers (NPI_Number, FirstName, LastName, SpecialtyCode, LicenseState, YearsOfExperience, HospitalAffiliation)
SELECT 
    '10' + RIGHT('0000000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(7)), 8) AS NPI_Number,
    FirstName,
    LastName,
    SpecialtyCode,
    StateCode,
    Experience,
    Hospital
FROM (
    VALUES 
    ('James', 'Wilson', 'CARD', 'CA', 15, 'Mount Sinai Hospital'),
    ('Sarah', 'Johnson', 'PEDS', 'NY', 8, 'Children''s Hospital'),
    ('Michael', 'Brown', 'ORTHO', 'TX', 20, 'Texas Medical Center'),
    ('Emily', 'Davis', 'DERM', 'FL', 12, 'Skin Care Specialists'),
    ('Robert', 'Miller', 'NEURO', 'IL', 18, 'Neurology Institute'),
    ('Jennifer', 'Taylor', 'ONCO', 'PA', 10, 'Cancer Treatment Center'),
    ('William', 'Anderson', 'SURG', 'OH', 25, 'General Hospital'),
    ('Lisa', 'Thomas', 'PSYCH', 'GA', 7, 'Mental Health Clinic'),
    ('David', 'Martinez', 'FMED', 'NC', 5, 'Family Care Center'),
    ('Amanda', 'Garcia', 'OBGYN', 'MI', 14, 'Women''s Health Center')
) AS Base(FirstName, LastName, SpecialtyCode, StateCode, Experience, Hospital)
CROSS JOIN (
    SELECT TOP 40 1 FROM sys.objects
) AS Multiplier;

-- Update remaining 40 providers with varied data
UPDATE TOP(40) p
SET 
    p.FirstName = CASE (p.ProviderID % 5)
        WHEN 0 THEN 'Christopher' WHEN 1 THEN 'Jessica' 
        WHEN 2 THEN 'Matthew' WHEN 3 THEN 'Ashley' WHEN 4 THEN 'Daniel'
    END,
    p.LastName = CASE (p.ProviderID % 6)
        WHEN 0 THEN 'Rodriguez' WHEN 1 THEN 'Lee' 
        WHEN 2 THEN 'Walker' WHEN 3 THEN 'Young' 
        WHEN 4 THEN 'King' WHEN 5 THEN 'Scott'
    END,
    p.SpecialtyCode = CASE (p.ProviderID % 10)
        WHEN 0 THEN 'CARD' WHEN 1 THEN 'PEDS' WHEN 2 THEN 'ORTHO'
        WHEN 3 THEN 'DERM' WHEN 4 THEN 'NEURO' WHEN 5 THEN 'ONCO'
        WHEN 6 THEN 'SURG' WHEN 7 THEN 'PSYCH' WHEN 8 THEN 'FMED' WHEN 9 THEN 'OBGYN'
    END,
    p.LicenseState = CASE (p.ProviderID % 10)
        WHEN 0 THEN 'CA' WHEN 1 THEN 'NY' WHEN 2 THEN 'TX'
        WHEN 3 THEN 'FL' WHEN 4 THEN 'IL' WHEN 5 THEN 'PA'
        WHEN 6 THEN 'OH' WHEN 7 THEN 'GA' WHEN 8 THEN 'NC' WHEN 9 THEN 'MI'
    END,
    p.YearsOfExperience = (p.ProviderID % 30) + 1,
    p.HospitalAffiliation = CASE (p.ProviderID % 4)
        WHEN 0 THEN 'General Hospital' WHEN 1 THEN 'Specialty Clinic'
        WHEN 2 THEN 'Medical Center' WHEN 3 THEN 'Private Practice'
    END
FROM Providers p
WHERE p.ProviderID > 1010;

-- 2. Patients Table
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY IDENTITY(20001,1),
    MRN_Number VARCHAR(20) UNIQUE NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    FullName AS (FirstName + ' ' + LastName) PERSISTED,
    DateOfBirth DATE NOT NULL,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F', 'O')),
    Email VARCHAR(100),
    Phone VARCHAR(20),
    Address VARCHAR(200),
    City VARCHAR(50),
    State CHAR(2) FOREIGN KEY REFERENCES Ref_States(StateCode),
    ZipCode VARCHAR(10),
    PrimaryInsurance VARCHAR(50),
    InsuranceID VARCHAR(30),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Insert 200 sample patients
INSERT INTO Patients (MRN_Number, FirstName, LastName, DateOfBirth, Gender, State, PrimaryInsurance)
SELECT 
    'MRN' + RIGHT('000000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(6)), 6),
    FirstNames.FirstName,
    LastNames.LastName,
    DATEADD(YEAR, -(18 + (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 60)), 
           DATEADD(DAY, (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 365), '2000-01-01')),
    Genders.Gender,
    States.StateCode,
    Insurances.InsuranceName
FROM (
    VALUES ('John'), ('Mary'), ('David'), ('Lisa'), ('Paul'), 
           ('Karen'), ('Mark'), ('Nancy'), ('Steve'), ('Laura')
) AS FirstNames(FirstName)
CROSS JOIN (
    VALUES ('Smith'), ('Johnson'), ('Williams'), ('Jones'), ('Brown'),
           ('Davis'), ('Miller'), ('Wilson'), ('Moore'), ('Taylor')
) AS LastNames(LastName)
CROSS JOIN (
    VALUES ('M'), ('F'), ('O')
) AS Genders(Gender)
CROSS JOIN (
    VALUES ('CA'), ('NY'), ('TX'), ('FL'), ('IL'), ('PA'), ('OH'), ('GA'), ('NC'), ('MI')
) AS States(StateCode)
CROSS JOIN (
    VALUES ('Blue Cross'), ('Aetna'), ('UnitedHealth'), ('Cigna'), ('Medicare')
) AS Insurances(InsuranceName);

-- 3. Appointments Table (Core transactional table)
CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    ProviderID INT NOT NULL FOREIGN KEY REFERENCES Providers(ProviderID),
    AppointmentDate DATETIME NOT NULL,
    AppointmentType VARCHAR(30) CHECK (AppointmentType IN 
        ('New Patient', 'Follow-up', 'Consultation', 'Procedure', 'Emergency', 'Wellness')),
    Status VARCHAR(20) CHECK (Status IN 
        ('Scheduled', 'Completed', 'Cancelled', 'No-show', 'Rescheduled')),
    ReasonForVisit VARCHAR(200),
    DurationMinutes INT DEFAULT 30,
    IsNoShow BIT DEFAULT 0,
    CancellationReason VARCHAR(100),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    
    INDEX IX_Appointments_Date (AppointmentDate),
    INDEX IX_Appointments_Provider (ProviderID),
    INDEX IX_Appointments_Patient (PatientID)
);

-- Insert 1000 sample appointments
INSERT INTO Appointments (PatientID, ProviderID, AppointmentDate, AppointmentType, Status, DurationMinutes, IsNoShow)
SELECT TOP 1000
    (SELECT TOP 1 PatientID FROM Patients ORDER BY NEWID()),
    (SELECT TOP 1 ProviderID FROM Providers ORDER BY NEWID()),
    DATEADD(DAY, -(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 365), 
           DATEADD(HOUR, (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 10) + 8, GETDATE())),
    AppointmentTypes.TypeName,
    CASE 
        WHEN (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 100) = 0 THEN 'No-show'
        WHEN (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 50) = 0 THEN 'Cancelled'
        ELSE 'Completed'
    END,
    Durations.Minutes,
    CASE WHEN (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 100) = 0 THEN 1 ELSE 0 END
FROM sys.objects s1
CROSS JOIN sys.objects s2
CROSS JOIN (
    VALUES ('New Patient'), ('Follow-up'), ('Consultation'), ('Procedure'), ('Emergency')
) AS AppointmentTypes(TypeName)
CROSS JOIN (
    VALUES (15), (30), (45), (60)
) AS Durations(Minutes);

-- 4. Medical Records Table
CREATE TABLE MedicalRecords (
    RecordID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    ProviderID INT NOT NULL FOREIGN KEY REFERENCES Providers(ProviderID),
    VisitDate DATE NOT NULL,
    DiagnosisCode VARCHAR(10),
    DiagnosisDescription VARCHAR(200),
    ProcedureCode VARCHAR(10),
    ProcedureDescription VARCHAR(200),
    Medications VARCHAR(500),
    Notes TEXT,
    IsChronic BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Insert 500 sample medical records
INSERT INTO MedicalRecords (PatientID, ProviderID, VisitDate, DiagnosisCode, DiagnosisDescription, IsChronic)
SELECT TOP 500
    (SELECT TOP 1 PatientID FROM Patients ORDER BY NEWID()),
    (SELECT TOP 1 ProviderID FROM Providers ORDER BY NEWID()),
    DATEADD(DAY, -(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 365), GETDATE()),
    DiagnosisCodes.Code,
    DiagnosisCodes.Description,
    CASE WHEN (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 5) = 0 THEN 1 ELSE 0 END
FROM sys.objects s1
CROSS JOIN sys.objects s2
CROSS JOIN (
    VALUES 
    ('I10', 'Essential hypertension'),
    ('E11.9', 'Type 2 diabetes'),
    ('J06.9', 'Acute upper respiratory infection'),
    ('M54.5', 'Low back pain'),
    ('K21.9', 'Gastro-esophageal reflux disease')
) AS DiagnosisCodes(Code, Description);

-- 5. Provider Credentials Table
CREATE TABLE ProviderCredentials (
    CredentialID INT PRIMARY KEY IDENTITY(1,1),
    ProviderID INT NOT NULL FOREIGN KEY REFERENCES Providers(ProviderID),
    Degree VARCHAR(50),
    BoardCertification VARCHAR(100),
    CertificationDate DATE,
    ExpirationDate DATE,
    IsBoardCertified BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE()
);

INSERT INTO ProviderCredentials (ProviderID, Degree, BoardCertification, IsBoardCertified)
SELECT 
    ProviderID,
    CASE SpecialtyCode
        WHEN 'CARD' THEN 'MD, Cardiology'
        WHEN 'PEDS' THEN 'MD, Pediatrics'
        WHEN 'ORTHO' THEN 'MD, Orthopedic Surgery'
        ELSE 'MD'
    END,
    CASE WHEN ProviderID % 3 = 0 THEN 'American Board Certified' ELSE NULL END,
    CASE WHEN ProviderID % 3 = 0 THEN 1 ELSE 0 END
FROM Providers;

-- 6. Patient Feedback Table
CREATE TABLE PatientFeedback (
    FeedbackID INT PRIMARY KEY IDENTITY(1,1),
    AppointmentID INT FOREIGN KEY REFERENCES Appointments(AppointmentID),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    ProviderID INT NOT NULL FOREIGN KEY REFERENCES Providers(ProviderID),
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    WaitTimeRating INT CHECK (WaitTimeRating BETWEEN 1 AND 5),
    CommunicationRating INT CHECK (CommunicationRating BETWEEN 1 AND 5),
    OverallExperience INT CHECK (OverallExperience BETWEEN 1 AND 10),
    WouldRecommend BIT,
    Comments TEXT,
    FeedbackDate DATE DEFAULT GETDATE(),
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Insert 300 sample feedback records
INSERT INTO PatientFeedback (AppointmentID, PatientID, ProviderID, Rating, WaitTimeRating, CommunicationRating, OverallExperience, WouldRecommend)
SELECT TOP 300
    a.AppointmentID,
    a.PatientID,
    a.ProviderID,
    CASE (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 20)
        WHEN 0 THEN 1 WHEN 1 THEN 2 WHEN 2 THEN 3 ELSE 4 + ((ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 2))
    END,
    3 + ((ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 3)),
    4 + ((ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 2)),
    6 + ((ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 4)),
    CASE WHEN (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 10) > 1 THEN 1 ELSE 0 END
FROM Appointments a
WHERE a.Status = 'Completed';

-- 7. Billing Table
CREATE TABLE Billing (
    BillID INT PRIMARY KEY IDENTITY(1,1),
    AppointmentID INT FOREIGN KEY REFERENCES Appointments(AppointmentID),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    ProviderID INT NOT NULL FOREIGN KEY REFERENCES Providers(ProviderID),
    ServiceDate DATE NOT NULL,
    CPT_Code VARCHAR(10),
    Description VARCHAR(200),
    Amount DECIMAL(10,2) NOT NULL,
    InsurancePaid DECIMAL(10,2),
    PatientPaid DECIMAL(10,2),
    Balance DECIMAL(10,2),
    Status VARCHAR(20) CHECK (Status IN ('Pending', 'Submitted', 'Paid', 'Denied')),
    CreatedDate DATETIME DEFAULT GETDATE()
);

INSERT INTO Billing (AppointmentID, PatientID, ProviderID, ServiceDate, Amount, InsurancePaid, Status)
SELECT TOP 200
    a.AppointmentID,
    a.PatientID,
    a.ProviderID,
    CAST(a.AppointmentDate AS DATE),
    CASE a.AppointmentType
        WHEN 'New Patient' THEN 200.00
        WHEN 'Procedure' THEN 500.00
        ELSE 100.00
    END,
    CASE a.AppointmentType
        WHEN 'New Patient' THEN 160.00
        WHEN 'Procedure' THEN 400.00
        ELSE 80.00
    END,
    CASE (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 4)
        WHEN 0 THEN 'Pending' WHEN 1 THEN 'Submitted' 
        WHEN 2 THEN 'Paid' WHEN 3 THEN 'Denied'
    END
FROM Appointments a
WHERE a.Status = 'Completed';

GO

-- =============================================
-- CREATE VIEWS FOR REPORTING
-- =============================================
CREATE VIEW vw_ProviderPerformance AS
SELECT 
    p.ProviderID,
    p.FullName,
    p.SpecialtyCode,
    s.SpecialtyName,
    COUNT(DISTINCT a.AppointmentID) AS TotalAppointments,
    SUM(CASE WHEN a.Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedAppointments,
    SUM(CASE WHEN a.IsNoShow = 1 THEN 1 ELSE 0 END) AS NoShowAppointments,
    AVG(pf.Rating) AS AvgPatientRating,
    COUNT(DISTINCT a.PatientID) AS UniquePatients
FROM Providers p
LEFT JOIN Appointments a ON p.ProviderID = a.ProviderID
LEFT JOIN PatientFeedback pf ON p.ProviderID = pf.ProviderID
LEFT JOIN Ref_Specialties s ON p.SpecialtyCode = s.SpecialtyCode
GROUP BY p.ProviderID, p.FullName, p.SpecialtyCode, s.SpecialtyName;

CREATE VIEW vw_PatientVisits AS
SELECT 
    pat.PatientID,
    pat.FullName,
    pat.State,
    COUNT(DISTINCT mr.VisitDate) AS TotalVisits,
    COUNT(DISTINCT mr.ProviderID) AS UniqueProviders,
    MIN(mr.VisitDate) AS FirstVisit,
    MAX(mr.VisitDate) AS LastVisit
FROM Patients pat
LEFT JOIN MedicalRecords mr ON pat.PatientID = mr.PatientID
GROUP BY pat.PatientID, pat.FullName, pat.State;

GO