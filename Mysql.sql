use Mental_Health;
-- Find All Employees Who Participated in an In-Person Survey but Not an Online Survey
SELECT e.Emp_ID, e.Name
FROM Employee e
WHERE EXISTS (
    SELECT 1
    FROM Wellbeing_Survey ws
    JOIN In_Person_Survey ips ON ws.Survey_ID = ips.Survey_ID
    WHERE ws.Emp_ID = e.Emp_ID
) AND NOT EXISTS (
    SELECT 1
    FROM Wellbeing_Survey ws
    JOIN Online_Survey os ON ws.Survey_ID = os.Survey_ID
    WHERE ws.Emp_ID = e.Emp_ID
);
-- Inner join to get employees and their assigned wellness programs
SELECT e.Emp_ID, e.Name, wp.Description
FROM Employee e
INNER JOIN Employee_Wellness_Program ewp ON e.Emp_ID = ewp.Emp_ID
INNER JOIN Wellness_Program wp ON ewp.Program_ID = wp.Program_ID;

-- Nested query to find the wellness program with the highest number of enrolled employees
SELECT wp.Program_ID, wp.Description
FROM Wellness_Program wp
WHERE wp.Program_ID = (
    SELECT Program_ID
    FROM Employee_Wellness_Program
    GROUP BY Program_ID
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

-- Nested query with inner join to find the most recommended wellness program
SELECT wp.Program_ID, wp.Description
FROM Wellness_Program wp
INNER JOIN (
    SELECT Recommendations, COUNT(*) as recommendation_count
    FROM Report
    GROUP BY Recommendations
    ORDER BY recommendation_count DESC
    LIMIT 1
) most_recommended ON wp.Description = most_recommended.Recommendations;

-- Correlated query with outer join to find employees who have completed more sessions than the average for their department
SELECT e.Emp_ID, e.Name, e.Department, COUNT(s.Session_ID) as completed_sessions
FROM Employee e
LEFT OUTER JOIN Session s ON e.Emp_ID = s.Emp_ID AND s.Status = 'Completed'
GROUP BY e.Emp_ID, e.Name, e.Department
HAVING COUNT(s.Session_ID) > (
    SELECT AVG(session_count)
    FROM (
        SELECT e2.Department, COUNT(s2.Session_ID) as session_count
        FROM Employee e2
        LEFT OUTER JOIN Session s2 ON e2.Emp_ID = s2.Emp_ID AND s2.Status = 'Completed'
        WHERE e2.Department = e.Department
        GROUP BY e2.Emp_ID
    ) dept_avg
);
-- ALL query to find employees with perfect attendance (0 absenteeism days)
SELECT e.Emp_ID, e.Name
FROM Employee e
INNER JOIN Worklife_Data wd ON e.Emp_ID = wd.Emp_ID
WHERE wd.Absenteeism_Days = 0
AND wd.Absenteeism_Days <= ALL (
    SELECT Absenteeism_Days
    FROM Worklife_Data
);

-- EXISTS query with inner join to find therapists who have conducted sessions for high-risk employees
SELECT DISTINCT t.Therapist_ID, t.Name
FROM Therapist t
INNER JOIN Therapist_Session ts ON t.Therapist_ID = ts.Therapist_ID
WHERE EXISTS (
    SELECT 1
    FROM Session s
    INNER JOIN Report r ON s.Emp_ID = r.Emp_ID
    WHERE s.Session_ID = ts.Session_ID
    AND r.High_Risk_Employees = 'High'
);

-- Nested query with outer join to find the least popular wellness program
SELECT wp.Program_ID, wp.Description, COALESCE(enrollment_count, 0) as enrollment_count
FROM Wellness_Program wp
LEFT OUTER JOIN (
    SELECT Program_ID, COUNT(*) as enrollment_count
    FROM Employee_Wellness_Program
    GROUP BY Program_ID
) enrollments ON wp.Program_ID = enrollments.Program_ID
ORDER BY enrollment_count ASC
LIMIT 1;


-- Correlated query to find employees who have participated in more wellness programs than the average
SELECT e.Emp_ID, e.Name, COUNT(*) as program_count
FROM Employee e
INNER JOIN Employee_Wellness_Program ewp ON e.Emp_ID = ewp.Emp_ID
GROUP BY e.Emp_ID, e.Name
HAVING COUNT(*) > (
    SELECT AVG(program_count)
    FROM (
        SELECT COUNT(*) as program_count
        FROM Employee_Wellness_Program
        GROUP BY Emp_ID
    ) avg_count
);

-- Nested query with inner join to find the most common therapy location
SELECT tl.Location_ID, tl.Location_Name
FROM Therapy_Location tl
INNER JOIN (
    SELECT Location_ID, COUNT(*) as session_count
    FROM Session
    GROUP BY Location_ID
    ORDER BY session_count DESC
    LIMIT 1
) most_common ON tl.Location_ID = most_common.Location_ID;

-- ALL query to find therapists who have more experience than all therapists offering a 'Group' therapy type
SELECT t.Therapist_ID, t.Name, t.Experience
FROM Therapist t
WHERE t.Experience > ALL (
    SELECT Experience
    FROM Therapist
    WHERE Therapy_type_offered = 'Individual'
);

-- Union query to  List all sessions and surveys an employee has participated in

SELECT e.Emp_ID, e.Name, 'Session' AS ActivityType, s.Session_Date AS Date, s.Type
FROM Employee e
JOIN Session s ON e.Emp_ID = s.Emp_ID
UNION
SELECT e.Emp_ID, e.Name, 'Survey' AS ActivityType, ws.Survey_Date AS Date, ws.Survey_Type
FROM Employee e
JOIN Wellbeing_Survey ws ON e.Emp_ID = ws.Emp_ID
ORDER BY Emp_ID, Date;