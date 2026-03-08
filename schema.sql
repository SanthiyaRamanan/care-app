-- ═══════════════════════════════════════════════════════
--  C.A.R.E Database Schema
--  Railway-ready: DEFINER removed, localhost refs cleaned
--  Import this into Railway MySQL via Workbench
-- ═══════════════════════════════════════════════════════

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ── Create database if not exists ──
CREATE DATABASE IF NOT EXISTS `railway` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `railway`;

-- ─────────────────────────────────────
--  TABLE: users
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id`                int NOT NULL AUTO_INCREMENT,
  `name`              varchar(100)  COLLATE utf8mb4_unicode_ci NOT NULL,
  `email`             varchar(150)  COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash`     varchar(256)  COLLATE utf8mb4_unicode_ci NOT NULL,
  `role`              enum('student','staff','admin') COLLATE utf8mb4_unicode_ci DEFAULT 'student',
  `department`        varchar(100)  COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `class_name`        varchar(20)   COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `year`              tinyint       DEFAULT '1',
  `roll_number`       varchar(50)   COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `staff_id`          varchar(50)   COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone`             varchar(20)   COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `profile_pic`       varchar(200)  COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `streak_stars`      int           DEFAULT '0',
  `total_stars_earned` int          DEFAULT '0',
  `level`             int           DEFAULT '1',
  `created_at`        datetime      DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: admin_log
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `admin_log`;
CREATE TABLE `admin_log` (
  `id`         int NOT NULL AUTO_INCREMENT,
  `admin_id`   int NOT NULL,
  `action`     varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `detail`     text         COLLATE utf8mb4_unicode_ci,
  `created_at` datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: assignments
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `assignments`;
CREATE TABLE `assignments` (
  `id`          int NOT NULL AUTO_INCREMENT,
  `staff_id`    int NOT NULL,
  `class_name`  varchar(20)  COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `title`       varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text         COLLATE utf8mb4_unicode_ci,
  `subject`     varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `due_date`    date         NOT NULL,
  `max_marks`   int          DEFAULT '10',
  `created_at`  datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `assignments_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: attendance
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `attendance`;
CREATE TABLE `attendance` (
  `id`           int NOT NULL AUTO_INCREMENT,
  `student_id`   int NOT NULL,
  `staff_id`     int NOT NULL,
  `class_name`   varchar(20)  COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `subject`      varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `period`       tinyint      DEFAULT NULL,
  `timetable_id` int          DEFAULT NULL,
  `date`         date         NOT NULL,
  `status`       enum('present','absent','late') COLLATE utf8mb4_unicode_ci DEFAULT 'present',
  `is_swap`      tinyint      DEFAULT '0',
  `swap_note`    varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `marked_at`    datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `no_dup` (`student_id`,`date`,`period`,`subject`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `attendance_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `attendance_ibfk_2` FOREIGN KEY (`staff_id`)  REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: cat_marks
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `cat_marks`;
CREATE TABLE `cat_marks` (
  `id`          int NOT NULL AUTO_INCREMENT,
  `student_id`  int NOT NULL,
  `staff_id`    int NOT NULL,
  `class_name`  varchar(20)  COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `subject`     varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `semester`    tinyint      NOT NULL,
  `cat1_marks`  float        DEFAULT '0',
  `cat2_marks`  float        DEFAULT '0',
  `cat1_max`    int          DEFAULT '100',
  `cat2_max`    int          DEFAULT '100',
  `created_at`  datetime     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  datetime     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `no_dup` (`student_id`,`subject`,`semester`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `cat_marks_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `cat_marks_ibfk_2` FOREIGN KEY (`staff_id`)   REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: certificates
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `certificates`;
CREATE TABLE `certificates` (
  `id`                  int NOT NULL AUTO_INCREMENT,
  `student_id`          int NOT NULL,
  `title`               varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `event_title`         varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `category`            varchar(50)  COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issuer`              varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issue_date`          date         DEFAULT NULL,
  `file_path`           varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ai_confidence`       float        DEFAULT '0',
  `ai_extracted_name`   varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `verification_status` enum('pending','verified','rejected','manual_review') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `stars_earned`        int          DEFAULT '0',
  `verified_by`         int          DEFAULT NULL,
  `created_at`          datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  CONSTRAINT `certificates_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: notifications
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications` (
  `id`         int NOT NULL AUTO_INCREMENT,
  `user_id`    int NOT NULL,
  `title`      varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `message`    text         COLLATE utf8mb4_unicode_ci,
  `type`       enum('streak','warning','assignment','attendance','certificate','quiz','achievement','general') COLLATE utf8mb4_unicode_ci DEFAULT 'general',
  `is_read`    tinyint      DEFAULT '0',
  `created_at` datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: projects
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `projects`;
CREATE TABLE `projects` (
  `id`           int NOT NULL AUTO_INCREMENT,
  `student_id`   int NOT NULL,
  `title`        varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description`  text         COLLATE utf8mb4_unicode_ci,
  `github_link`  varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tech_stack`   varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status`       enum('ongoing','completed') COLLATE utf8mb4_unicode_ci DEFAULT 'ongoing',
  `stars_earned` int          DEFAULT '0',
  `created_at`   datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  CONSTRAINT `projects_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: quizzes
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `quizzes`;
CREATE TABLE `quizzes` (
  `id`               int NOT NULL AUTO_INCREMENT,
  `staff_id`         int NOT NULL,
  `class_name`       varchar(20)  COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `title`            varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subject`          varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `duration_minutes` int          DEFAULT '30',
  `total_marks`      int          DEFAULT '0',
  `due_date`         datetime     DEFAULT NULL,
  `created_at`       datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `quizzes_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: quiz_questions (legacy MCQ)
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `quiz_questions`;
CREATE TABLE `quiz_questions` (
  `id`          int NOT NULL AUTO_INCREMENT,
  `quiz_id`     int NOT NULL,
  `question`    text        COLLATE utf8mb4_unicode_ci NOT NULL,
  `option_a`    varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `option_b`    varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `option_c`    varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `option_d`    varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `correct_ans` char(1)     COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `marks`       int         DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `quiz_id` (`quiz_id`),
  CONSTRAINT `quiz_questions_ibfk_1` FOREIGN KEY (`quiz_id`) REFERENCES `quizzes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: quiz_questions_v2 (multi-type)
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `quiz_questions_v2`;
CREATE TABLE `quiz_questions_v2` (
  `id`           int NOT NULL AUTO_INCREMENT,
  `quiz_id`      int NOT NULL,
  `question`     text COLLATE utf8mb4_unicode_ci NOT NULL,
  `q_type`       enum('mcq','multi_select','short_answer','long_answer') COLLATE utf8mb4_unicode_ci DEFAULT 'mcq',
  `options_json` text COLLATE utf8mb4_unicode_ci,
  `correct_json` text COLLATE utf8mb4_unicode_ci,
  `marks`        int  DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `quiz_id` (`quiz_id`),
  CONSTRAINT `quiz_questions_v2_ibfk_1` FOREIGN KEY (`quiz_id`) REFERENCES `quizzes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: quiz_attempts
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `quiz_attempts`;
CREATE TABLE `quiz_attempts` (
  `id`           int NOT NULL AUTO_INCREMENT,
  `quiz_id`      int NOT NULL,
  `student_id`   int NOT NULL,
  `score`        float   DEFAULT '0',
  `total_marks`  int     DEFAULT '0',
  `percentage`   float   DEFAULT '0',
  `attempted_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `no_dup` (`quiz_id`,`student_id`),
  KEY `student_id` (`student_id`),
  CONSTRAINT `quiz_attempts_ibfk_1` FOREIGN KEY (`quiz_id`)    REFERENCES `quizzes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `quiz_attempts_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `users`   (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: quiz_answers
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `quiz_answers`;
CREATE TABLE `quiz_answers` (
  `id`           int NOT NULL AUTO_INCREMENT,
  `attempt_id`   int NOT NULL,
  `question_id`  int NOT NULL,
  `answer_given` text  COLLATE utf8mb4_unicode_ci,
  `marks_given`  float DEFAULT '0',
  `is_graded`    tinyint DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `attempt_id`  (`attempt_id`),
  KEY `question_id` (`question_id`),
  CONSTRAINT `quiz_answers_ibfk_1` FOREIGN KEY (`attempt_id`)  REFERENCES `quiz_attempts`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `quiz_answers_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `quiz_questions_v2` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: research
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `research`;
CREATE TABLE `research` (
  `id`               int NOT NULL AUTO_INCREMENT,
  `staff_id`         int NOT NULL,
  `title`            varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `journal_name`     varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `publication_date` date         DEFAULT NULL,
  `status`           enum('published','presented','under_review') COLLATE utf8mb4_unicode_ci DEFAULT 'under_review',
  `doi_link`         varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `stars_earned`     int          DEFAULT '0',
  `created_at`       datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `research_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: results
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `results`;
CREATE TABLE `results` (
  `id`              int NOT NULL AUTO_INCREMENT,
  `student_id`      int NOT NULL,
  `staff_id`        int NOT NULL,
  `semester`        tinyint      DEFAULT NULL,
  `subject`         varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `exam_type`       enum('internal','external','practical') COLLATE utf8mb4_unicode_ci DEFAULT 'external',
  `marks_obtained`  float        DEFAULT NULL,
  `max_marks`       int          DEFAULT '100',
  `grade`           varchar(5)   COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `stars_earned`    int          DEFAULT '0',
  `created_at`      datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  KEY `staff_id`   (`staff_id`),
  CONSTRAINT `results_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `results_ibfk_2` FOREIGN KEY (`staff_id`)   REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: semester_results
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `semester_results`;
CREATE TABLE `semester_results` (
  `id`           int NOT NULL AUTO_INCREMENT,
  `student_id`   int NOT NULL,
  `semester`     tinyint      NOT NULL,
  `subject`      varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subject_type` enum('theory','lab','elective') COLLATE utf8mb4_unicode_ci DEFAULT 'theory',
  `grade`        enum('O','A+','A','B+','B','C','F','W') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at`   datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  CONSTRAINT `semester_results_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: seminars
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `seminars`;
CREATE TABLE `seminars` (
  `id`             int NOT NULL AUTO_INCREMENT,
  `student_id`     int NOT NULL,
  `title`          varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description`    text         COLLATE utf8mb4_unicode_ci,
  `conducted_date` date         DEFAULT NULL,
  `audience`       varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image_path`     varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `stars_earned`   int          DEFAULT '0',
  `created_at`     datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  CONSTRAINT `seminars_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: staff_classes
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `staff_classes`;
CREATE TABLE `staff_classes` (
  `id`                int NOT NULL AUTO_INCREMENT,
  `staff_id`          int NOT NULL,
  `class_name`        varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_coordinator`    tinyint     DEFAULT '0',
  `coordinator_class` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at`        datetime    DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `no_dup` (`staff_id`,`class_name`),
  CONSTRAINT `staff_classes_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: streak_log
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `streak_log`;
CREATE TABLE `streak_log` (
  `id`              int NOT NULL AUTO_INCREMENT,
  `user_id`         int NOT NULL,
  `stars_earned`    int          DEFAULT '0',
  `stars_deducted`  int          DEFAULT '0',
  `reason`          varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source`          varchar(50)  COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at`      datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `streak_log_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: subject_master
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `subject_master`;
CREATE TABLE `subject_master` (
  `id`           int NOT NULL AUTO_INCREMENT,
  `department`   varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `semester`     tinyint      NOT NULL,
  `subject`      varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subject_type` enum('theory','lab','elective') COLLATE utf8mb4_unicode_ci DEFAULT 'theory',
  `created_at`   datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `no_dup` (`department`,`semester`,`subject`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: subject_assignments
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `subject_assignments`;
CREATE TABLE `subject_assignments` (
  `id`         int NOT NULL AUTO_INCREMENT,
  `subject_id` int NOT NULL,
  `staff_id`   int NOT NULL,
  `class_name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `no_dup` (`subject_id`,`class_name`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `subject_assignments_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subject_master` (`id`) ON DELETE CASCADE,
  CONSTRAINT `subject_assignments_ibfk_2` FOREIGN KEY (`staff_id`)   REFERENCES `users`          (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: submissions
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `submissions`;
CREATE TABLE `submissions` (
  `id`             int NOT NULL AUTO_INCREMENT,
  `assignment_id`  int NOT NULL,
  `student_id`     int NOT NULL,
  `file_path`      varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status`         enum('submitted','late','graded') COLLATE utf8mb4_unicode_ci DEFAULT 'submitted',
  `marks_obtained` float        DEFAULT NULL,
  `feedback`       text         COLLATE utf8mb4_unicode_ci,
  `submitted_at`   datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `no_dup` (`assignment_id`,`student_id`),
  KEY `student_id` (`student_id`),
  CONSTRAINT `submissions_ibfk_1` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `submissions_ibfk_2` FOREIGN KEY (`student_id`)    REFERENCES `users`       (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: timetable
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `timetable`;
CREATE TABLE `timetable` (
  `id`         int NOT NULL AUTO_INCREMENT,
  `staff_id`   int NOT NULL,
  `class_name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `year`       tinyint     DEFAULT NULL,
  `day`        enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday') COLLATE utf8mb4_unicode_ci NOT NULL,
  `period`     tinyint     NOT NULL,
  `subject`    varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_time` time        NOT NULL,
  `end_time`   time        NOT NULL,
  `created_at` datetime    DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `timetable_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────
--  TABLE: swap_requests
-- ─────────────────────────────────────
DROP TABLE IF EXISTS `swap_requests`;
CREATE TABLE `swap_requests` (
  `id`               int NOT NULL AUTO_INCREMENT,
  `requester_id`     int NOT NULL,
  `target_staff_id`  int NOT NULL,
  `slot_id`          int NOT NULL,
  `target_slot_id`   int NOT NULL,
  `reason`           text         COLLATE utf8mb4_unicode_ci,
  `status`           enum('pending','approved','rejected') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `admin_note`       varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at`       datetime     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `requester_id`    (`requester_id`),
  KEY `target_staff_id` (`target_staff_id`),
  KEY `slot_id`         (`slot_id`),
  KEY `target_slot_id`  (`target_slot_id`),
  CONSTRAINT `swap_requests_ibfk_1` FOREIGN KEY (`requester_id`)    REFERENCES `users`     (`id`) ON DELETE CASCADE,
  CONSTRAINT `swap_requests_ibfk_2` FOREIGN KEY (`target_staff_id`) REFERENCES `users`     (`id`) ON DELETE CASCADE,
  CONSTRAINT `swap_requests_ibfk_3` FOREIGN KEY (`slot_id`)         REFERENCES `timetable` (`id`) ON DELETE CASCADE,
  CONSTRAINT `swap_requests_ibfk_4` FOREIGN KEY (`target_slot_id`)  REFERENCES `timetable` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════
--  VIEWS  (DEFINER removed — works on any MySQL server)
-- ═══════════════════════════════════════════════════════

DROP VIEW IF EXISTS `v_leaderboard`;
CREATE VIEW `v_leaderboard` AS
SELECT
  id, name, class_name, department,
  streak_stars, total_stars_earned, level,
  RANK() OVER (PARTITION BY class_name ORDER BY streak_stars DESC) AS class_rank,
  RANK() OVER (ORDER BY streak_stars DESC)                         AS overall_rank
FROM users
WHERE role = 'student';

DROP VIEW IF EXISTS `v_subjects_with_staff`;
CREATE VIEW `v_subjects_with_staff` AS
SELECT
  sm.id, sm.department, sm.semester, sm.subject, sm.subject_type,
  sa.id          AS assign_id,
  sa.class_name  AS assigned_class,
  u.id           AS staff_user_id,
  u.name         AS assigned_staff
FROM subject_master sm
LEFT JOIN subject_assignments sa ON sa.subject_id = sm.id
LEFT JOIN users u                ON u.id = sa.staff_id;

-- ═══════════════════════════════════════════════════════
--  SEED DATA
-- ═══════════════════════════════════════════════════════

-- Users
INSERT INTO `users` VALUES
(1,'Admin','admin@care.ac.in','scrypt:32768:8:1$JTag6icQ01SU7QLc$e801d192b334fd7ddb8edb66e725fb4636a0e9c31b0946917caef5f61a35910b9e4bbf2ab6c3d3262b7cf7979c0aa5c3f8929289ac810ca4b96915e82d0bbd9a','admin','Administration',NULL,1,NULL,NULL,NULL,NULL,0,0,1,'2026-03-08 09:38:46'),
(2,'Santhiya R','santhiya.r@care.ac.in','scrypt:32768:8:1$RslocgpeJTQms4Iw$b2992c8997f4f861108cffef2c28eb110f418f33cb12bcde19d496b83872e3f7be4d48b3748a691816b63f70d1fced358b8bd9fdf17420a6a301b40872332402','student','AI & DS','AD-B',3,'810723243095',NULL,'+919600350868','uploads/profiles/20260308071000_24.jpg',2,2,1,'2026-03-07 17:49:07'),
(3,'Anitha M','manitha@care.ac.in','scrypt:32768:8:1$wCcnyFg7oocq5B7Y$43002b3715e22327aa4ebaae5ade3eb8e759d4085f2e6d8d605af381f98730ca9159d2ae59333fdedb0fd42e621973ce28622683e48f23b47f4a1dc89528f8c3','staff','AI & DS',NULL,NULL,NULL,'STAFFAD001','9442108806',NULL,1,1,1,'2026-03-07 17:49:47'),
(4,'Selvamanikandan R','r.selvamanikandan@care.ac.in','scrypt:32768:8:1$igA3CQ149xll6ewu$07209e7665a287dc12d3f1eeced795bfa6fc7fb9d8f2e14bf134cb524e03fe32e9fc85f98c05871d0e1e9143e6f1ccae7bd18567c9379197960cf548cd46011b','staff','AI & DS',NULL,NULL,NULL,'STAFFAD002','8778368248',NULL,0,0,1,'2026-03-07 17:55:05'),
(5,'Shakila Banu F','fshakilabanu@care.ac.in','scrypt:32768:8:1$TfPCycz0atoZuprv$2bc30f676e30f461eb56e1a29cad6492c337810e0a8edb933593274b552be58eca4e0065e7a8b778cdf852423b6bb7b8e094ac89fb963b0b1f7490b0140de7ce','staff','AI & DS',NULL,NULL,NULL,'STAFFAD003','9791711089',NULL,0,0,1,'2026-03-07 19:59:41'),
(7,'Kiruthiga D','dkiruthiga@care.ac.in','scrypt:32768:8:1$MQS7QTWSfUE360es$b705e0b0be53987092c52b5c637a3afa7470f76d13093cf3e034767634447b6f04facb5aa2b248c110492f6d87d3166baed023fbf7d5cc0907665591d040edcd','staff','AI & DS',NULL,NULL,NULL,'STAFFAD004','9600880446',NULL,0,0,1,'2026-03-07 20:05:13'),
(8,'Padmasree B','padmasree.kb@care.ac.in','scrypt:32768:8:1$7pIeKLb4Kpzm3Kuz$354c46224c9159898b3fd84e48db65bc68d11660ae8e757a1b9529b13f308c0b1abe8de8b7e0ababd22ee5ac15b3708c2dbdc7f767ba72f6f3a5b5d991327238','staff','AI & DS',NULL,NULL,NULL,'STAFFAD005','8056944019',NULL,0,0,1,'2026-03-07 20:06:50'),
(9,'Anand S','anand.mech@care.ac.in','scrypt:32768:8:1$dejvjhA2fx5KeQwW$a77615a6c07fd7451369a0de7a7a7fbdeef740154105bb98e170ad499d346efb5e570bdb4f48cc992821a8876b0abc91b590c2e872f91a757c7ae928eb6de077','staff','AI & DS',NULL,NULL,NULL,'STAFFAD006','9952292353',NULL,0,0,1,'2026-03-07 20:07:52'),
(10,'Krishnaveni K','k.krishnaveni@care.ac.in','scrypt:32768:8:1$3UjV2n3Dk8S0ZgvW$935862f91d75bb71260f6c87e85b68138fe52e3765c6fd1077265a73885ec3cdefb0c58c887ed7ead4577efb772fd307a1da2ef69ff9073fcd2197b808a333e7','staff','AI & DS',NULL,NULL,NULL,'STAFFAD007','9894309552',NULL,0,0,1,'2026-03-07 20:09:03'),
(11,'Saraswathi M','saraswathi.m@care.ac.in','scrypt:32768:8:1$ibwOYb9RYB9fIeY3$5d557a4e2d820f7eaf3c9819d8486a3f10dccda5299e516dd3ef092dabb8d74873a77d1ef7bced07d6d99b309d6c94f686af0a273d93b3bae70fb0c04e827f45','student','AI & DS','AD-B',3,'810723243098',NULL,'+916379294923',NULL,2,2,1,'2026-03-07 20:09:39'),
(12,'Priyanka Mary J','priyankamary.j@care.ac.in','scrypt:32768:8:1$xmFs9XWmHCkCHYDN$27d5f1c8ab95f0aeaa58677d34a84c29622fab5baf3ac939359f25399dd9b81f3e66b5ae6b752ac66005338ad5c8424b87686dabfa3147f57812b9351f0c9b18','student','AI & DS','AD-B',3,'810723243080',NULL,'8807951773',NULL,2,2,1,'2026-03-07 20:10:35'),
(13,'Yuvanisha M','yuvanisha.m@care.ac.in','scrypt:32768:8:1$yUaGVWHsHS9fxF5t$4bf0c1d391c9935ae693748b53e9cc8590e80308612079e5817f1e692e40dc0471164c605229fb7a86e3dc3a907d1aaf2115236b0434c6bb9092285251374dcc','student','AI & DS','AD-B',3,'810723243126',NULL,'7603865308',NULL,2,2,1,'2026-03-07 20:11:27'),
(14,'Vijaya Kumar T','tvijayakumar@care.ac.in','scrypt:32768:8:1$pHIAu5qIzWP2SnyA$878ce96721da75e57638ff94832c5f84cd9f81be65a51f68ed3af8a4c67254e24982e630415c557ebae26563696294999b20832b2e9120f545009cf28cbebf6a','staff','T&P',NULL,NULL,NULL,'STAFFTP001','8940596855',NULL,0,0,1,'2026-03-07 20:16:21'),
(15,'Amba Bharati S','ambabharati@care.ac.in','scrypt:32768:8:1$HWQIkhAZFMumGtfI$bb60e053f960264ea6a3da6c8de4396fea8d81201c7d578c866d8e5cb8d8884cd10009bdab7319bdaaa1d59dc5c46f305844290bed37107a9e2c7ff66c7d7d50','staff','T&P',NULL,NULL,NULL,'STAFFTP002','9944488857',NULL,0,0,1,'2026-03-07 20:17:16'),
(16,'Nivetha M','m.nivetha@care.ac.in','scrypt:32768:8:1$dN0l5SOs60HO8lQz$973b7a0213b58b08af9fa890f60623451d87e8e5dc1893e4f51f8e4e860c8994531576999333ad5aab867db9494a9c2169a3c2f22dac1908eb0e7414206f30ed','staff','AI & DS',NULL,NULL,NULL,'STAFFAD007','7094546717',NULL,0,0,1,'2026-03-07 20:21:45'),
(17,'Shanmuga Priya A','a.shanmugapriya@care.ac.in','scrypt:32768:8:1$xnlAMBWxJ5TNI18G$235c39496ffcd147e50755474940fee27ae2d70cad66bb84919b0c0173dc84b894eb2ac8698bbc790acf2dc089bd7d5297978a67773cc85b294dc9e8575f54da','staff','AI & DS',NULL,NULL,NULL,'STAFFAD008','9677577074',NULL,0,0,1,'2026-03-07 20:27:26');

-- Subject master
INSERT INTO `subject_master` VALUES
(1,'AD',6,'STORAGE TECHNOLOGIES','elective','2026-03-08 10:33:10'),
(2,'AD',6,'MULTIMEDIA AND ANIMATIONS','elective','2026-03-08 10:33:22'),
(3,'AD',6,'NETWORK SECURITY','elective','2026-03-08 10:33:30'),
(4,'AD',6,'HEALTH CARE ANALYTICS','elective','2026-03-08 10:33:39'),
(5,'AD',6,'EMBEDDED SYSTEMS AND IOT','theory','2026-03-08 10:33:55'),
(6,'AD',6,'RENEWABLE ENERGY SYSTEMS','theory','2026-03-08 10:34:04');

-- Subject assignments
INSERT INTO `subject_assignments` VALUES
(1,5,8,'AD-B','2026-03-08 10:34:27'),
(2,5,8,'AD-A','2026-03-08 10:34:51');

-- Staff classes
INSERT INTO `staff_classes` VALUES
(1,3,'AD-A',0,NULL,'2026-03-08 10:35:38'),
(2,3,'AD-B',0,NULL,'2026-03-08 10:35:38');

-- Timetable
INSERT INTO `timetable` VALUES
(1,3,'AD-B',3,'Monday',1,'STORAGE TECHNOLOGIES','09:00:00','09:45:00','2026-03-08 10:32:23'),
(2,7,'AD-B',3,'Monday',2,'M&A LAB','09:45:00','10:40:00','2026-03-08 10:32:23'),
(3,7,'AD-B',3,'Monday',3,'M&A LAB','10:55:00','11:45:00','2026-03-08 10:32:23'),
(4,7,'AD-B',3,'Monday',4,'M&A LAB','11:45:00','12:35:00','2026-03-08 10:32:23'),
(5,8,'AD-B',3,'Monday',5,'EMBEDDED SYSTEMS AND IOT','13:30:00','14:20:00','2026-03-08 10:32:23'),
(6,10,'AD-B',3,'Monday',6,'HEALTH CARE ANALYTICS','14:20:00','15:10:00','2026-03-08 10:32:23'),
(7,17,'AD-B',3,'Monday',7,'YOGA, AYURVEDHA & SIDDHA','15:20:00','16:10:00','2026-03-08 10:32:23'),
(8,9,'AD-B',3,'Monday',8,'RENEWABLE ENERGY SYSTEMS','16:10:00','17:00:00','2026-03-08 10:32:23'),
(9,7,'AD-B',3,'Tuesday',1,'MULTIMEDIA AND ANIMATION','09:00:00','09:45:00','2026-03-08 10:32:23'),
(10,3,'AD-B',3,'Tuesday',2,'STORAGE TECHNOLOGIES','09:45:00','10:40:00','2026-03-08 10:32:23'),
(11,10,'AD-B',3,'Tuesday',3,'HEALTH CARE ANALYTICS','10:55:00','11:45:00','2026-03-08 10:32:23'),
(12,16,'AD-B',3,'Tuesday',4,'P&T','11:45:00','12:35:00','2026-03-08 10:32:23'),
(13,5,'AD-B',3,'Tuesday',5,'NETWORK SECURITY','13:30:00','14:20:00','2026-03-08 10:32:23'),
(14,5,'AD-B',3,'Tuesday',6,'N&S LAB','14:20:00','15:10:00','2026-03-08 10:32:23'),
(15,5,'AD-B',3,'Tuesday',7,'N&S LAB','15:20:00','16:10:00','2026-03-08 10:32:23'),
(16,5,'AD-B',3,'Tuesday',8,'N&S LAB','16:10:00','17:00:00','2026-03-08 10:32:23'),
(17,8,'AD-B',3,'Wednesday',1,'EMBEDDED SYSTEMS AND IOT','09:00:00','09:45:00','2026-03-08 10:32:23'),
(18,5,'AD-B',3,'Wednesday',2,'NETWORK SECURITY','09:45:00','10:40:00','2026-03-08 10:32:23'),
(19,10,'AD-B',3,'Wednesday',3,'HEALTH CARE ANALYTICS','10:55:00','11:45:00','2026-03-08 10:32:23'),
(20,9,'AD-B',3,'Wednesday',4,'RENEWABLE ENERGY SYSTEMS','11:45:00','12:35:00','2026-03-08 10:32:23'),
(21,17,'AD-B',3,'Wednesday',5,'YOGA, AYURVEDHA & SIDDHA','13:30:00','14:20:00','2026-03-08 10:32:23'),
(22,7,'AD-B',3,'Wednesday',6,'MULTIMEDIA AND ANIMATION','14:20:00','15:10:00','2026-03-08 10:32:23'),
(23,15,'AD-B',3,'Wednesday',7,'T&P','15:20:00','16:10:00','2026-03-08 10:32:23'),
(24,4,'AD-B',3,'Wednesday',8,'LIBRARY','16:10:00','17:00:00','2026-03-08 10:32:23'),
(25,9,'AD-B',3,'Thursday',1,'RENEWABLE ENERGY SYSTEMS','09:00:00','09:45:00','2026-03-08 10:32:23'),
(26,8,'AD-B',3,'Thursday',2,'ES&IOT LAB','09:45:00','10:40:00','2026-03-08 10:32:23'),
(27,8,'AD-B',3,'Thursday',3,'ES&IOT LAB','10:55:00','11:45:00','2026-03-08 10:32:23'),
(28,8,'AD-B',3,'Thursday',4,'ES&IOT LAB','11:45:00','12:35:00','2026-03-08 10:32:23'),
(29,10,'AD-B',3,'Thursday',5,'HEALTH CARE ANALYTICS','13:30:00','14:20:00','2026-03-08 10:32:23'),
(30,3,'AD-B',3,'Thursday',6,'STORAGE TECHNOLOGIES','14:20:00','15:10:00','2026-03-08 10:32:23'),
(31,8,'AD-B',3,'Thursday',7,'EMBEDDED SYSTEMS AND IOT','15:20:00','16:10:00','2026-03-08 10:32:23'),
(32,16,'AD-B',3,'Thursday',8,'P&T','16:10:00','17:00:00','2026-03-08 10:32:23'),
(33,5,'AD-B',3,'Friday',1,'NETWORK SECURITY','09:00:00','09:45:00','2026-03-08 10:32:23'),
(34,7,'AD-B',3,'Friday',2,'MULTIMEDIA AND ANIMATION','09:45:00','10:40:00','2026-03-08 10:32:23'),
(35,17,'AD-B',3,'Friday',3,'YOGA, AYURVEDHA & SIDDHA','10:55:00','11:45:00','2026-03-08 10:32:23'),
(36,8,'AD-B',3,'Friday',4,'EMBEDDED SYSTEMS AND IOT','11:45:00','12:35:00','2026-03-08 10:32:23'),
(37,14,'AD-B',3,'Friday',5,'T&P','13:30:00','14:20:00','2026-03-08 10:32:23'),
(38,9,'AD-B',3,'Friday',6,'RENEWABLE ENERGY SYSTEMS','14:20:00','15:10:00','2026-03-08 10:32:23'),
(39,3,'AD-B',3,'Friday',7,'STORAGE TECHNOLOGIES','15:20:00','16:10:00','2026-03-08 10:32:23'),
(40,4,'AD-B',3,'Friday',8,'COUNCELLING','16:10:00','17:00:00','2026-03-08 10:32:23');

-- Attendance sample data
INSERT INTO `attendance` VALUES
(1,12,3,'AD-B','Storage Technologies',1,NULL,'2026-03-09','present',0,'','2026-03-08 10:37:22'),
(2,2,3,'AD-B','Storage Technologies',1,NULL,'2026-03-09','present',0,'','2026-03-08 10:37:22'),
(3,11,3,'AD-B','Storage Technologies',1,NULL,'2026-03-09','present',0,'','2026-03-08 10:37:22'),
(4,13,3,'AD-B','Storage Technologies',1,NULL,'2026-03-09','present',0,'','2026-03-08 10:37:22');

-- Notifications sample data
INSERT INTO `notifications` VALUES
(1,12,'+2 ⭐ Stars Earned','Attendance: Storage Technologies P1','attendance',0,'2026-03-08 10:37:22'),
(2,2,'+2 ⭐ Stars Earned','Attendance: Storage Technologies P1','attendance',1,'2026-03-08 10:37:22'),
(3,11,'+2 ⭐ Stars Earned','Attendance: Storage Technologies P1','attendance',0,'2026-03-08 10:37:22'),
(4,13,'+2 ⭐ Stars Earned','Attendance: Storage Technologies P1','attendance',0,'2026-03-08 10:37:22'),
(5,3,'+1 ⭐ Stars Earned','Marked attendance: AD-B Storage Technologies P1','attendance',0,'2026-03-08 10:37:22'),
(6,8,'Result: Santhiya R','Sem 6 — EMBEDDED SYSTEMS AND IOT: O','achievement',0,'2026-03-08 10:40:28');

-- Streak log sample data
INSERT INTO `streak_log` VALUES
(1,12,2,0,'Attendance: Storage Technologies P1',NULL,'2026-03-08 10:37:22'),
(2,2,2,0,'Attendance: Storage Technologies P1',NULL,'2026-03-08 10:37:22'),
(3,11,2,0,'Attendance: Storage Technologies P1',NULL,'2026-03-08 10:37:22'),
(4,13,2,0,'Attendance: Storage Technologies P1',NULL,'2026-03-08 10:37:22'),
(5,3,1,0,'Marked attendance: AD-B Storage Technologies P1',NULL,'2026-03-08 10:37:22');

SET FOREIGN_KEY_CHECKS = 1;
