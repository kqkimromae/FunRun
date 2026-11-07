SET NAMES utf8mb4;
SET time_zone = '+07:00';

CREATE TABLE events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  slug VARCHAR(190) NOT NULL UNIQUE,
  description TEXT NULL,
  location VARCHAR(255) NULL,
  event_date DATE NOT NULL,
  start_time TIME NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'published',
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE roles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(125) NOT NULL,
  guard_name VARCHAR(125) NOT NULL DEFAULT 'web',
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY roles_name_guard_unique (name, guard_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  email_verified_at TIMESTAMP NULL,
  password VARCHAR(255) NOT NULL,
  remember_token VARCHAR(100) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE model_has_roles (
  role_id BIGINT UNSIGNED NOT NULL,
  model_type VARCHAR(255) NOT NULL,
  model_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (role_id, model_id, model_type),
  KEY model_has_roles_model_id_model_type_index (model_id, model_type),
  CONSTRAINT model_has_roles_role_fk FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE registrations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  event_id BIGINT UNSIGNED NOT NULL,
  bib_number VARCHAR(30) NULL,
  full_name VARCHAR(255) NOT NULL,
  fullname VARCHAR(255) NOT NULL,
  applicant_type VARCHAR(20) NOT NULL DEFAULT 'general',
  student_id VARCHAR(50) NULL,
  faculty VARCHAR(255) NULL,
  title VARCHAR(20) NOT NULL,
  age TINYINT UNSIGNED NOT NULL,
  gender VARCHAR(10) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  emergency_name VARCHAR(255) NOT NULL,
  emergency_phone VARCHAR(20) NOT NULL,
  emergency_rel VARCHAR(100) NOT NULL,
  distance VARCHAR(10) NOT NULL,
  age_group VARCHAR(80) NOT NULL,
  no_shirt TINYINT(1) NOT NULL DEFAULT 0,
  shirt_size VARCHAR(10) NULL,
  pickup_option VARCHAR(100) NOT NULL,
  fee_amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'confirmed',
  registration_status VARCHAR(30) NOT NULL DEFAULT 'confirmed',
  kit_received_at DATETIME NULL,
  kit_received_by BIGINT UNSIGNED NULL,
  kit_signature_path VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY registrations_event_bib_unique (event_id, bib_number),
  KEY registrations_name_index (fullname),
  KEY registrations_phone_index (phone),
  KEY registrations_distance_index (distance),
  KEY registrations_age_group_index (age_group),
  KEY registrations_pickup_received_index (pickup_option, kit_received_at),
  CONSTRAINT registrations_event_fk FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  CONSTRAINT registrations_kit_receiver_fk FOREIGN KEY (kit_received_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE payments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  registration_id BIGINT UNSIGNED NOT NULL UNIQUE,
  amount DECIMAL(10,2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL DEFAULT 'promptpay',
  slip_path VARCHAR(255) NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  verified_by BIGINT UNSIGNED NULL,
  verified_at DATETIME NULL,
  note TEXT NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY payments_status_index (status),
  CONSTRAINT payments_registration_fk FOREIGN KEY (registration_id) REFERENCES registrations(id) ON DELETE CASCADE,
  CONSTRAINT payments_verifier_fk FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bib_counters (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  event_id BIGINT UNSIGNED NOT NULL,
  category VARCHAR(20) NOT NULL,
  last_number INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY bib_counters_event_category_unique (event_id, category),
  CONSTRAINT bib_counters_event_fk FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE settings (
  `key` VARCHAR(100) NOT NULL PRIMARY KEY,
  `value` LONGTEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE homepage_sections (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `key` VARCHAR(40) NOT NULL UNIQUE,
  section_type VARCHAR(30) NOT NULL,
  title VARCHAR(180) NULL,
  subtitle VARCHAR(255) NULL,
  body LONGTEXT NULL,
  image_path VARCHAR(255) NULL,
  button_text VARCHAR(80) NULL,
  button_url VARCHAR(2048) NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY homepage_sections_order_index (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE registration_assets (
  `key` VARCHAR(40) NOT NULL PRIMARY KEY,
  image_path VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE page_view_stats (
  view_date DATE NOT NULL,
  page_key VARCHAR(100) NOT NULL,
  views BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (view_date, page_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE rate_limits (
  bucket CHAR(64) NOT NULL,
  window_start INT UNSIGNED NOT NULL,
  hits SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (bucket, window_start)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO events (name, slug, description, location, event_date, status)
VALUES ('FUNRUN PUNRUK #4', 'funrun-punruk-4', 'วิ่งด้วยรัก ส่งต่อสุขภาพ', 'มหาวิทยาลัยทักษิณ วิทยาเขตพัทลุง', '2027-01-30', 'published');

INSERT INTO roles (name, guard_name) VALUES
('admin', 'web'), ('super_admin', 'web'), ('finance', 'web');

INSERT INTO settings (`key`, `value`) VALUES
('form_status', 'open'),
('promptpay_id', '0631945880'),
('promptpay_name', 'นัซมี เจ๊ะอาแซ');

INSERT INTO registration_assets (`key`) VALUES
('shirt_5km'), ('shirt_10km'), ('shirt_vip'), ('size_chart');

INSERT INTO homepage_sections (`key`, section_type, title, subtitle, body, button_text, button_url, sort_order, is_active) VALUES
('hero', 'hero', 'FUNRUN PUNRUK #4', 'สวนสนุกแห่งความสุข วิ่งด้วยรัก ส่งต่อสุขภาพ', 'ชวนทุกคนมาสนุกกับงานวิ่งเพื่อสุขภาพ ณ มหาวิทยาลัยทักษิณ วิทยาเขตพัทลุง', 'สมัครเข้าร่วมกิจกรรม', '/register', 1, 1),
('slide_1', 'slide', 'วิ่งด้วยรัก ส่งต่อสุขภาพ', 'มาสนุกและสร้างความทรงจำดี ๆ ไปด้วยกัน', 'เปิดประสบการณ์งานวิ่งในบรรยากาศสวนสนุก', 'สมัครเลย', '/register', 10, 1),
('slide_2', 'slide', 'Fun Run 5 กิโลเมตร', 'ระยะสนุกสำหรับทุกคน', 'วิ่งสบาย ๆ ชวนเพื่อนและครอบครัวมาร่วมกิจกรรม', 'ดูรายละเอียดการสมัคร', '/register', 20, 1),
('slide_3', 'slide', 'Mini Marathon 10 กิโลเมตร', 'พร้อมท้าทายไปให้ถึงเส้นชัย', 'เตรียมตัวให้พร้อม แล้วมาเข้าเส้นชัยไปด้วยกัน', 'สมัครเข้าร่วม', '/register', 30, 1),
('slide_4', 'slide', 'VIP วิ่งด้วยใจ', 'ร่วมกิจกรรมในแพ็กเกจ VIP', 'เลือกแพ็กเกจที่ใช่ แล้วพบกันที่งาน', 'สมัครเลย', '/register', 40, 0),
('slide_5', 'slide', 'แล้วพบกันที่เส้นชัย', 'FUNRUN PUNRUK #4', 'เก็บความทรงจำดี ๆ ไปด้วยกัน', 'ตรวจสอบการสมัคร', '/registration/search', 50, 0),
('body_about', 'body', 'วิ่งสนุก ได้สุขภาพ และแบ่งปันความรัก', 'กิจกรรมสำหรับนักวิ่งทุกวัย', 'เลือกได้ทั้ง Fun Run 5 กิโลเมตร, Mini Marathon 10 กิโลเมตร และ VIP พร้อมพบกับบรรยากาศงานวิ่งธีมสวนสนุก', NULL, NULL, 60, 1),
('body_event', 'body', 'เตรียมตัวให้พร้อมก่อนวันงาน', 'สมัครออนไลน์และเก็บเลข BIB ไว้', 'กรอกข้อมูล เลือกระยะวิ่ง ชำระเงินพร้อมแนบสลิป แล้วบันทึกการ์ด BIB ไว้แสดงในวันงาน', 'ตรวจสอบข้อมูล / เลข BIB', '/registration/search', 70, 1),
('footer', 'footer', 'FUNRUN PUNRUK #4', 'สวนสนุกแห่งการวิ่ง · วิ่งด้วยรัก ส่งต่อสุขภาพ', 'คณะกรรมการจัดโครงการ มหาวิทยาลัยทักษิณ วิทยาเขตพัทลุง', NULL, NULL, 100, 1);
