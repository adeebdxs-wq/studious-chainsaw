-- إنشاء قاعدة البيانات
CREATE DATABASE IF NOT EXISTS ship_registration;
USE ship_registration;

-- ================================================
-- جدول الفروع
-- ================================================
CREATE TABLE branches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code ENUM('main','aden','mukalla','hodeidah') UNIQUE NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================
-- جدول المستخدمين
-- ================================================
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    national_id VARCHAR(20) UNIQUE,
    phone VARCHAR(20),
    secondary_phone VARCHAR(20),
    address TEXT,
    nationality VARCHAR(100),
    gender ENUM('male','female') DEFAULT 'male',
    role ENUM('admin','branch_employee','ship_owner') DEFAULT 'ship_owner',
    branch_code ENUM('main','aden','mukalla','hodeidah') NULL,
    position VARCHAR(100),
    owner_type ENUM('individual','company') DEFAULT 'individual',
    company_name VARCHAR(255),
    commercial_registration VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    status ENUM('active','inactive') DEFAULT 'active',
    FOREIGN KEY (branch_code) REFERENCES branches(code) ON DELETE SET NULL
);

-- ================================================
-- جدول السفن (محدث بجميع الحقول من صفحة التسجيل)
-- ================================================
CREATE TABLE ships (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    
    -- المعلومات الأساسية
    ship_name_ar VARCHAR(255) NOT NULL,
    ship_name_en VARCHAR(255),
    previous_names TEXT,
    imo_number VARCHAR(50) UNIQUE NOT NULL,
    last_port VARCHAR(255),
    ship_type VARCHAR(100) NOT NULL,
    
    -- تفاصيل البناء
    build_date DATE,
    build_place VARCHAR(255),
    builder_name VARCHAR(255),
    hull_type VARCHAR(100),
    
    -- الأبعاد والحمولة
    gross_tonnage DECIMAL(10,2) NOT NULL,
    net_tonnage DECIMAL(10,2),
    deadweight DECIMAL(10,2),
    length DECIMAL(10,2),
    beam DECIMAL(10,2),
    depth DECIMAL(10,2),
    draft DECIMAL(10,2),
    
    -- المحركات
    engine_power DECIMAL(10,2),
    engine_type VARCHAR(100),
    
    -- السعة والطاقم
    crew_count INT,
    passenger_capacity INT,
    cabins_count INT,
    
    -- معلومات التسجيل
    port_of_registry ENUM('aden','mukalla','hodeidah') NOT NULL,
    port_of_origin VARCHAR(100),
    flag_state VARCHAR(100),
    nationality VARCHAR(100),
    registration_number VARCHAR(100) UNIQUE,
    registration_date DATE,
    expiry_date DATE,
    
    -- حالة السفينة
    status ENUM('active','pending','expired','suspended') DEFAULT 'pending',
    
    -- ملاحظات إضافية
    additional_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ================================================
-- جدول محركات السفن (للسفن متعددة المحركات)
-- ================================================
CREATE TABLE ship_engines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ship_id INT NOT NULL,
    engine_number VARCHAR(100),
    engine_type VARCHAR(100),
    engine_manufacturer VARCHAR(100),
    engine_model VARCHAR(100),
    engine_power DECIMAL(10,2),
    engine_power_unit VARCHAR(20) DEFAULT 'hp',
    engine_year INT,
    cylinder_count INT,
    FOREIGN KEY (ship_id) REFERENCES ships(id) ON DELETE CASCADE
);

-- ================================================
-- جدول الطلبات
-- ================================================
CREATE TABLE applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_number VARCHAR(50) UNIQUE NOT NULL,
    owner_id INT NOT NULL,
    ship_id INT NOT NULL,
    application_type ENUM('new','renewal','amendment','cancellation') DEFAULT 'new',
    status ENUM(
        'pending',           -- قيد المراجعة
        'reviewing',         -- جاري المعالجة
        'approved',          -- مقبول
        'rejected',          -- مرفوض
        'rejected_by_employee', -- مرفوض من موظف
        'ready_for_employee',    -- جاهز للموظف (بعد تعديل المسؤول)
        'certificate_issued',    -- تم إصدار الشهادة
        'completed',         -- مكتمل
        'pending_payment'    -- بانتظار الدفع
    ) DEFAULT 'pending',
    branch_code ENUM('main','aden','mukalla','hodeidah') NOT NULL,
    assigned_to INT NULL,
    rejected_by INT NULL,
    rejected_at TIMESTAMP NULL,
    rejection_reason TEXT,
    admin_modified_by INT NULL,
    admin_modified_at TIMESTAMP NULL,
    admin_notes TEXT,
    ready_for_employee_id INT NULL,
    
    -- معلومات الدفع
    payment_option ENUM('full','partial') NULL,
    payment_amount DECIMAL(10,2),
    payment_receipt_url TEXT,
    payment_reference VARCHAR(100),
    payment_date DATE,
    payment_status ENUM('pending','verified','rejected') DEFAULT 'pending',
    
    -- تواريخ الطلب
    submission_date DATE,
    completion_date DATE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (owner_id) REFERENCES users(id),
    FOREIGN KEY (ship_id) REFERENCES ships(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id),
    FOREIGN KEY (rejected_by) REFERENCES users(id),
    FOREIGN KEY (admin_modified_by) REFERENCES users(id),
    FOREIGN KEY (ready_for_employee_id) REFERENCES users(id),
    FOREIGN KEY (branch_code) REFERENCES branches(code)
);

-- ================================================
-- جدول مستندات الطلب
-- ================================================
CREATE TABLE application_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    document_type ENUM('ownership','buildCertificate','idDocument','inspection','deletion','other') NOT NULL,
    file_url TEXT NOT NULL,
    verification_status ENUM('pending','verified','rejected') DEFAULT 'pending',
    verified_by INT NULL,
    verified_at TIMESTAMP NULL,
    notes TEXT,
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id)
);

-- ================================================
-- جدول الشهادات
-- ================================================
CREATE TABLE certificates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ship_id INT NOT NULL,
    application_id INT NULL,
    certificate_number VARCHAR(100) UNIQUE NOT NULL,
    certificate_type VARCHAR(100) DEFAULT 'registration',
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    validity_period INT COMMENT 'فترة الصلاحية بالأشهر: 6,12,24,60',
    issued_by INT NULL,
    issuing_authority VARCHAR(255),
    pdf_url TEXT,  -- رابط ملف PDF للشهادة (إذا تم رفعها)
    status ENUM('active','expired','revoked') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ship_id) REFERENCES ships(id) ON DELETE CASCADE,
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE SET NULL,
    FOREIGN KEY (issued_by) REFERENCES users(id)
);

-- ================================================
-- جدول الإشعارات
-- ================================================
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    user_role VARCHAR(50) NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('success','warning','info','reminder','deadline') DEFAULT 'info',
    link TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ================================================
-- جدول التقارير المصدرة
-- ================================================
CREATE TABLE exported_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    report_type VARCHAR(100) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    generated_by INT NOT NULL,
    date_from DATE,
    date_to DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (generated_by) REFERENCES users(id)
);

-- ================================================
-- إضافة الفروع الأساسية
-- ================================================
INSERT INTO branches (name, code, phone, email, address) VALUES
('المقر الرئيسي', 'main', '0123456789', 'main@maritime.gov.ye', 'صنعاء - شارع الجزائر'),
('فرع عدن', 'aden', '0123456790', 'aden@maritime.gov.ye', 'عدن - منطقة المعلا'),
('فرع المكلا', 'mukalla', '0123456791', 'mukalla@maritime.gov.ye', 'المكلا - منطقة الشحر'),
('فرع الحديدة', 'hodeidah', '0123456792', 'hodeidah@maritime.gov.ye', 'الحديدة - شارع الميناء');

-- ================================================
-- إضافة المستخدمين الأساسيين
-- كلمة المرور للجميع: admin123
-- استخدم هذا الكود PHP لتوليد التجزئة: password_hash('admin123', PASSWORD_DEFAULT)
-- ================================================
INSERT INTO users (email, password_hash, full_name, role, branch_code, position, status) VALUES
('admin@maritime.gov.ye', '$2y$10$YourHashedPasswordHere', 'المدير العام', 'admin', 'main', 'مدير النظام', 'active'),
('aden@maritime.gov.ye', '$2y$10$YourHashedPasswordHere', 'أحمد محمد - موظف فرع عدن', 'branch_employee', 'aden', 'موظف الفرع', 'active'),
('mukalla@maritime.gov.ye', '$2y$10$YourHashedPasswordHere', 'سالم بازرعة - موظف فرع المكلا', 'branch_employee', 'mukalla', 'موظف الفرع', 'active'),
('hodeidah@maritime.gov.ye', '$2y$10$YourHashedPasswordHere', 'محمد عبدالله - موظف فرع الحديدة', 'branch_employee', 'hodeidah', 'موظف الفرع', 'active'),
('owner@example.com', '$2y$10$YourHashedPasswordHere', 'محمد المالك', 'ship_owner', NULL, NULL, 'active');

-- ================================================
-- إنشاء المستخدم التجريبي لمالك السفينة مع بيانات كاملة
-- ================================================
INSERT INTO users (email, password_hash, full_name, national_id, phone, secondary_phone, address, nationality, gender, role, owner_type, company_name, commercial_registration, status) VALUES
('company@example.com', '$2y$10$YourHashedPasswordHere', 'شركة الشحن السريع', '1234567890', '0123456789', '0123456790', 'صنعاء - شارع حدة', 'YE', 'male', 'ship_owner', 'company', 'شركة الشحن السريع', 'CR-2025-001', 'active');

-- ================================================
-- إضافة بعض السفن التجريبية
-- ================================================
INSERT INTO ships (
    owner_id, ship_name_ar, ship_name_en, imo_number, ship_type, 
    gross_tonnage, net_tonnage, length, beam, draft, port_of_registry,
    build_date, builder_name, build_place, engine_power, engine_type,
    crew_count, passenger_capacity, status
) VALUES
(5, 'البحر الأحمر', 'Red Sea', '1234567', 'سفينة شحن', 12500, 8000, 150, 25, 8, 'aden', '2020-05-15', 'Hyundai Heavy Industries', 'كوريا الجنوبية', 12000, 'ديزل', 25, 0, 'active'),
(5, 'النفطية 1', 'Oil Tanker 1', '2345678', 'ناقلة نفط', 45000, 35000, 250, 40, 15, 'mukalla', '2018-10-20', 'Samsung Heavy Industries', 'كوريا الجنوبية', 25000, 'ديزل توربيني', 35, 0, 'active'),
(6, 'اليمن السعيد', 'Happy Yemen', '3456789', 'سفينة ركاب', 8500, 6000, 120, 20, 6, 'hodeidah', '2022-03-10', 'Meyer Werft', 'ألمانيا', 8000, 'ديزل', 50, 300, 'active');

-- ================================================
-- إضافة بعض الطلبات التجريبية
-- ================================================
INSERT INTO applications (
    application_number, owner_id, ship_id, application_type, status, 
    branch_code, submission_date, payment_option, payment_amount, 
    payment_reference, payment_date, payment_status
) VALUES
('APP-2025-0001', 5, 1, 'new', 'completed', 'aden', '2025-01-15', 'full', 12500, 'TRX-2025-001', '2025-01-15', 'verified'),
('APP-2025-0002', 5, 2, 'new', 'certificate_issued', 'mukalla', '2025-02-20', 'full', 45000, 'TRX-2025-002', '2025-02-20', 'verified'),
('APP-2025-0003', 6, 3, 'new', 'pending', 'hodeidah', '2025-03-10', 'partial', 4500, 'TRX-2025-003', '2025-03-10', 'pending');

-- ================================================
-- إضافة بعض الشهادات التجريبية
-- ================================================
INSERT INTO certificates (
    ship_id, application_id, certificate_number, issue_date, expiry_date, 
    validity_period, issued_by, issuing_authority, status
) VALUES
(1, 1, 'CERT-2025-0001', '2025-01-20', '2026-01-20', 12, 2, 'الهيئة العامة للشئون البحرية - فرع عدن', 'active'),
(2, 2, 'CERT-2025-0002', '2025-02-25', '2026-02-25', 12, 3, 'الهيئة العامة للشئون البحرية - فرع المكلا', 'active');

-- ================================================
-- إضافة بعض الإشعارات التجريبية
-- ================================================
INSERT INTO notifications (user_id, title, message, type, link) VALUES
(5, 'تم إصدار شهادة التسجيل', 'تم إصدار شهادة تسجيل لسفينتك "البحر الأحمر" برقم CERT-2025-0001', 'success', '/ship-details.html?id=1'),
(5, 'طلب قيد المراجعة', 'طلب تسجيل السفينة "النفطية 1" قيد المراجعة من قبل الموظف', 'info', '/application-details.html?id=2'),
(6, 'تم استلام الطلب', 'تم استلام طلب تسجيل السفينة "اليمن السعيد" بنجاح', 'success', '/application-details.html?id=3');

-- ================================================
-- عرض جميع الجداول التي تم إنشاؤها
-- ================================================
SHOW TABLES;