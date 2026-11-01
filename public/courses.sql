CREATE TABLE subjects (
    course_code VARCHAR(50) PRIMARY KEY,
    course_name VARCHAR(255) NOT NULL,
    credit_hours INT NOT NULL,
    prerequisite VARCHAR(255),
    compulsory BOOLEAN NOT NULL,
    available_for VARCHAR(255), 
    international BOOLEAN NOT NULL,
    internship BOOLEAN NOT NULL
);

INSERT INTO subjects (course_code, course_name, credit_hours, prerequisite, compulsory, available_for, international, internship) 
VALUES 
    -- Common Core Subjects
    ('CSEB2113', 'Programming I', 3, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CISB3313', 'Fundamentals of Database', 3, 'CSEB2113', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CSEB3123', 'Software Engineering Principles', 3, 'CSEB2113', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CSEB2213', 'Programming II', 3, 'CSEB2113', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('ISCB112/RELB112', 'Islam & Society / Comparative Religion', 2, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('MPU3182', 'Penghayatan Etika dan Peradaban', 2, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('MPU3192', 'Falsafah dan Isu Semasa', 2, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('MPU3142', 'Bahasa Melayu Komunikasi II', 2, 'None', TRUE, 'CS, SN, BSW, AI', TRUE, FALSE),
    ('CSEB3313', 'Object Oriented Programming', 3, 'CSEB2213', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CISB3323', 'Human Computer Interaction', 3, 'CSEB3123', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('ITCB213', 'IT Communication', 3, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CSEB4123', 'Web Programming', 3, 'CISB3313', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('COEB3052', 'Occupational Safety and Health', 2, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('MPU3372', 'Kursus Integriti dan Antirasuah', 2, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CGEB4112', 'Energy and Computing', 2, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CGEB4313', 'Project I', 3, 'CSEB2213, CSEB3123, CISB3313', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('ISWB112', 'Introduction to Social Work', 2, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CISB3112', 'Ethics and IT Professional Practices', 2, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CGEB4323', 'Project II', 3, 'CGEB4313', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CGEB4123', 'Technology Entrepreneurship', 3, 'None', TRUE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('CGEB4216', 'Industrial Training', 6, 'CSEB2213, CSEB3123, CISB3313, CSEB4123', TRUE, 'CS, SN, BSW, AI', FALSE, TRUE),

    -- Multi-Program Cores
    ('CSNB2123', 'Computer Organization', 3, 'None', TRUE, 'CS, SN, BSW', FALSE, FALSE),
    ('CCSB2113', 'Cyber Security Essentials', 3, 'None', TRUE, 'CS, SN, AI', FALSE, FALSE),
    ('CSNB2133', 'Discrete Structures', 3, 'None', TRUE, 'CS, SN', FALSE, FALSE),
    ('CSNB2113', 'System Administration', 3, 'None', TRUE, 'CS, SN', FALSE, FALSE),
    ('CSNB3113', 'Operating Systems Concepts', 3, 'CSNB2123', TRUE, 'CS, SN, BSW', FALSE, FALSE),
    ('CGEB2113', 'Statistics for Computing', 3, 'None', TRUE, 'CS, SN, AI', FALSE, FALSE),
    ('CSEB3213', 'Data Structures and Algorithms', 3, 'CSEB2213', TRUE, 'CS, SN, AI, BSW', FALSE, FALSE),
    ('CSNB4133', 'Artificial Intelligence', 3, 'CSEB2213', TRUE, 'CS, SN, BSW', FALSE, FALSE),
    ('CSNB3123', 'Data Communication and Computer Networks', 3, 'CSNB2123', TRUE, 'CS, SN, BSW', FALSE, FALSE),
    ('CSNB3213', 'Digital Design and Microprocessor Systems', 3, 'CSNB2123', TRUE, 'CS, SN', FALSE, FALSE),
    ('CSNB4423', 'Parallel Computing', 3, 'CSEB2213', TRUE, 'CS, SN', FALSE, FALSE),
    ('CSNB3413', 'Network Switching and LAN', 3, 'CSNB3123', TRUE, 'CS, SN', FALSE, FALSE),

    -- Cyber Security (CS) Specific Cores
    ('CCSB3133', 'Critical Infrastructure Security', 3, 'CSNB3413', TRUE, 'CS', FALSE, FALSE),
    ('CCSB3113', 'Cryptography', 3, 'CSNB2133', TRUE, 'CS', FALSE, FALSE),
    ('CCSB4122', 'Information Security Management', 2, 'CCSB2113', TRUE, 'CS', FALSE, FALSE),
    ('CCSB3123', 'Network Security', 3, 'CCSB2113, CSNB3123', TRUE, 'CS', FALSE, FALSE),
    ('CCSB4113', 'Ethical Hacking', 3, 'CCSB3123', TRUE, 'CS', FALSE, FALSE),

    -- Systems and Networking (SN) Specific Cores
    ('CSNB4113', 'Internet Protocols', 3, 'CSNB3123', TRUE, 'SN', FALSE, FALSE),
    ('CSNB3222', 'Storage Technologies', 2, 'CSNB2123', TRUE, 'SN', FALSE, FALSE),
    ('CSNB4213', 'Network Analysis and Design', 3, 'CSNB3123', TRUE, 'SN', FALSE, FALSE),
    ('CSNB4413', 'Network Routing and WAN', 3, 'CSNB3413', TRUE, 'SN', FALSE, FALSE),

    -- Software Engineering (BSW) Specific Cores
    ('CSEB1122', 'Software Technologies and Innovation', 2, 'None', TRUE, 'BSW', FALSE, FALSE),
    ('CSEB2123', 'Computational Problem Solving', 3, 'None', TRUE, 'BSW', FALSE, FALSE),
    ('CSEB3443', 'Requirements Engineering', 3, 'CSEB3123', TRUE, 'BSW', FALSE, FALSE),
    ('CSEB3433', 'System Design', 3, 'CSEB3123', TRUE, 'BSW', FALSE, FALSE),
    ('CSEB5223', 'Software Construction & Methods', 3, 'CSEB3313', TRUE, 'BSW', FALSE, FALSE),
    ('CCSB5113', 'Software Security', 3, 'CSEB3313, CSEB4123', TRUE, 'BSW, CS', FALSE, FALSE),
    ('CSEB4113', 'Software Quality', 3, 'CSEB3443, CSEB3433', TRUE, 'BSW', FALSE, FALSE),
    ('CSEB5213', 'Software Evolution & Maintenance', 3, 'CSEB3123', TRUE, 'BSW', FALSE, FALSE),
    ('CSEB4213', 'Software Project Management', 3, 'CSEB3123, CSEB3443', TRUE, 'BSW', FALSE, FALSE),
    ('CSEB4313', 'Software Testing', 3, 'CSEB3433, CSEB3443', TRUE, 'BSW', FALSE, FALSE),

    -- Artificial Intelligence (AI) Specific Cores
    ('CNEB2123', 'Computer Organization (AI Variant)', 3, 'None', TRUE, 'AI', FALSE, FALSE),
    ('CNEB2133', 'Discrete Structures (AI Variant)', 3, 'None', TRUE, 'AI', FALSE, FALSE),
    ('CNEB2112', 'System Administration (AI Variant)', 2, 'None', TRUE, 'AI', FALSE, FALSE),
    ('CNEB3113', 'Operating Systems Concepts (AI Variant)', 3, 'CNEB2123', TRUE, 'AI', FALSE, FALSE),
    ('CNEB3123', 'Data Communication and Computer Networks (AI Variant)', 3, 'CNEB2123', TRUE, 'AI', FALSE, FALSE),
    ('CAIB2113', 'Artificial Intelligence: Principles and Techniques', 3, 'CSEB2213', TRUE, 'AI', FALSE, FALSE),
    ('CNEB4423', 'Parallel Computing (AI Variant)', 3, 'CSEB2213', TRUE, 'AI', FALSE, FALSE),
    ('CAIB2213', 'Machine Learning', 3, 'CAIB2113', TRUE, 'AI', FALSE, FALSE),
    ('CAIB3813', 'Data Science and Data Analytics', 3, 'CGEB2113, CAIB2113', TRUE, 'AI', FALSE, FALSE),
    ('CAIB2413', 'Fuzzy Logic', 3, 'CAIB2113', TRUE, 'AI', FALSE, FALSE),
    ('CAIB2513', 'Evolutionary Computation and Swarm Intelligence', 3, 'CAIB2113', TRUE, 'AI', FALSE, FALSE),
    ('CAIB3213', 'Natural Language Processing', 3, 'CAIB2113', TRUE, 'AI', FALSE, FALSE),
    ('CAIB3413', 'Computer Vision', 3, 'CSEB2113', TRUE, 'AI', FALSE, FALSE),
    ('CAIB3513', 'Generative AI', 3, 'CAIB2113', TRUE, 'AI', FALSE, FALSE),
    ('CAIB3613', 'Reinforcement Learning', 3, 'CAIB2213', TRUE, 'AI', FALSE, FALSE),
    ('CAIB3713', 'Robotics and Autonomous Systems', 3, 'CAIB2213, CAIB3413', TRUE, 'AI', FALSE, FALSE),
    ('CAIB2313', 'AI Applications in Industries', 3, 'CAIB2113', TRUE, 'AI', FALSE, FALSE),

    -- Technical Electives
    ('CSNB5113', 'Embedded Systems', 3, 'CSNB3113', FALSE, 'CS, SN', FALSE, FALSE),
    ('CCSB5133', 'System Security Defense', 3, 'CCSB3123', FALSE, 'CS', FALSE, FALSE),
    ('CISB4313', 'Information Systems Auditing', 3, 'CCSB4122, CISB4223', FALSE, 'CS', FALSE, FALSE),
    ('CSNB5213', 'Machine Learning and Data Analytics', 3, 'CSNB4133', FALSE, 'CS, SN, BSW', FALSE, FALSE),
    ('CCSB5213', 'Malware Analysis', 3, 'CSNB3213, CSEB3213', FALSE, 'CS', FALSE, FALSE),
    ('CCSB5223', 'Computer Forensics', 3, 'CCSB2113, CSNB3113', FALSE, 'CS', FALSE, FALSE),
    ('CSNB5123', 'Mobile Application Development', 3, 'CSEB3313', FALSE, 'CS, SN, BSW', FALSE, FALSE),
    ('CSNB5133', 'Wireless Networking', 3, 'CSNB4113', FALSE, 'SN', FALSE, FALSE),
    ('CISB3453', 'Database Management and Administration', 3, 'CISB3313', FALSE, 'SN', FALSE, FALSE),
    ('CISB5123', 'Text Analytics', 3, 'CISB3313, CSNB5213', FALSE, 'SN, AI', FALSE, FALSE),
    ('CISB5143', 'Data Engineering', 3, 'CISB3313, CSNB5214', FALSE, 'SN, AI', FALSE, FALSE),
    ('CSEB5113', 'Java Programming', 3, 'CSEB3313', FALSE, 'SN, BSW', FALSE, FALSE),
    ('CSEB5123', 'Advanced Web Application Development', 3, 'CSEB4123, CISB3313', FALSE, 'SN, BSW', FALSE, FALSE),
    ('CSEB5133', 'Data Visualization Programming', 3, 'CSEB3313, CSEB4123', FALSE, 'SN, BSW, AI', FALSE, FALSE),
    ('CSEB5233', 'Designing Applications on Cloud', 3, 'CSEB4123', FALSE, 'BSW', FALSE, FALSE),
    ('CSEB5143', 'DevOps: Tools & Technologies', 3, 'CISB3313, CSEB4123', FALSE, 'BSW', FALSE, FALSE),
    ('CNEB5123', 'Mobile Application Development (AI Variant)', 3, 'CSEB3313', FALSE, 'AI', FALSE, FALSE),

    -- Free Electives 
    ('CGMB3723', 'Digital Photography', 3, 'None', FALSE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('PKIB113', 'Creative Thinking', 3, 'None', FALSE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('SPYB113', 'Introduction to Social Psychology', 3, 'None', FALSE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('SPRB113', 'Sport and Recreation Management at Workplace', 3, 'None', FALSE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('BKA103', 'Bahasa Kebangsaan A', 3, 'None', FALSE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('ELRB233', 'Energy Literacy', 3, 'None', FALSE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('GERB113', 'Basic German', 3, 'None', FALSE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('FRAB113', 'Basic French', 3, 'None', FALSE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('MADB113', 'Mandarin Language', 3, 'None', FALSE, 'CS, SN, BSW, AI', FALSE, FALSE),
    ('ARBB113', 'Arabic Language', 3, 'None', FALSE, 'CS, SN, BSW, AI', FALSE, FALSE);

CREATE TABLE internship (
    course VARCHAR(50) PRIMARY KEY,
    prerequisites VARCHAR(255) NOT NULL
);

INSERT INTO internship (course, prerequisites) 
VALUES 
    ('CS', 'CSEB2213, CSEB3123, CISB3313, CSEB4123'),
    ('SN', 'CSEB2213, CSEB3123, CISB3313, CSEB4123'),
    ('BSW', 'CSEB2213, CSEB3123, CISB3313, CSEB4123'),
    ('AI', 'CSEB2213, CSEB3123, CISB3313, CSEB4123');