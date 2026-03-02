-- =================================================================
-- FILE SQL UNTUK APLIKASI ZIPAY RUSSIA (Laravel 11)
-- Dibuat berdasarkan database/migrations source code
-- Jalankan: mysql -u root -p zipay_db < zipay_database.sql
-- =================================================================

-- Buat database (opsional jika sudah dibuat manual)
CREATE DATABASE IF NOT EXISTS `zipay_db`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `zipay_db`;

-- =================================================================
-- TABEL: users
-- Sumber: migrations/0001_01_01_000000_create_users_table.php
-- =================================================================
CREATE TABLE IF NOT EXISTS `users` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(255) NOT NULL,
    `email`             VARCHAR(255) NOT NULL,
    `email_verified_at` TIMESTAMP NULL DEFAULT NULL,
    `password`          VARCHAR(255) NOT NULL,
    `remember_token`    VARCHAR(100) NULL DEFAULT NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =================================================================
-- TABEL: password_reset_tokens
-- Sumber: migrations/0001_01_01_000000_create_users_table.php
-- =================================================================
CREATE TABLE IF NOT EXISTS `password_reset_tokens` (
    `email`      VARCHAR(255) NOT NULL,
    `token`      VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =================================================================
-- TABEL: sessions
-- Sumber: migrations/0001_01_01_000000_create_users_table.php
-- (Aktif jika SESSION_DRIVER=database, saat ini pakai 'file')
-- =================================================================
CREATE TABLE IF NOT EXISTS `sessions` (
    `id`            VARCHAR(255) NOT NULL,
    `user_id`       BIGINT UNSIGNED NULL DEFAULT NULL,
    `ip_address`    VARCHAR(45) NULL DEFAULT NULL,
    `user_agent`    TEXT NULL,
    `payload`       LONGTEXT NOT NULL,
    `last_activity` INT NOT NULL,
    PRIMARY KEY (`id`),
    KEY `sessions_user_id_index` (`user_id`),
    KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =================================================================
-- TABEL: cache
-- Sumber: migrations/0001_01_01_000001_create_cache_table.php
-- =================================================================
CREATE TABLE IF NOT EXISTS `cache` (
    `key`        VARCHAR(255) NOT NULL,
    `value`      MEDIUMTEXT NOT NULL,
    `expiration` INT NOT NULL,
    PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =================================================================
-- TABEL: cache_locks
-- Sumber: migrations/0001_01_01_000001_create_cache_table.php
-- =================================================================
CREATE TABLE IF NOT EXISTS `cache_locks` (
    `key`        VARCHAR(255) NOT NULL,
    `owner`      VARCHAR(255) NOT NULL,
    `expiration` INT NOT NULL,
    PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =================================================================
-- TABEL: jobs
-- Sumber: migrations/0001_01_01_000002_create_jobs_table.php
-- =================================================================
CREATE TABLE IF NOT EXISTS `jobs` (
    `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `queue`        VARCHAR(255) NOT NULL,
    `payload`      LONGTEXT NOT NULL,
    `attempts`     TINYINT UNSIGNED NOT NULL,
    `reserved_at`  INT UNSIGNED NULL DEFAULT NULL,
    `available_at` INT UNSIGNED NOT NULL,
    `created_at`   INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =================================================================
-- TABEL: job_batches
-- Sumber: migrations/0001_01_01_000002_create_jobs_table.php
-- =================================================================
CREATE TABLE IF NOT EXISTS `job_batches` (
    `id`             VARCHAR(255) NOT NULL,
    `name`           VARCHAR(255) NOT NULL,
    `total_jobs`     INT NOT NULL,
    `pending_jobs`   INT NOT NULL,
    `failed_jobs`    INT NOT NULL,
    `failed_job_ids` LONGTEXT NOT NULL,
    `options`        MEDIUMTEXT NULL,
    `cancelled_at`   INT NULL DEFAULT NULL,
    `created_at`     INT NOT NULL,
    `finished_at`    INT NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =================================================================
-- TABEL: failed_jobs
-- Sumber: migrations/0001_01_01_000002_create_jobs_table.php
-- =================================================================
CREATE TABLE IF NOT EXISTS `failed_jobs` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid`       VARCHAR(255) NOT NULL,
    `connection` TEXT NOT NULL,
    `queue`      TEXT NOT NULL,
    `payload`    LONGTEXT NOT NULL,
    `exception`  LONGTEXT NOT NULL,
    `failed_at`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =================================================================
-- TABEL: migrations (dicatat Laravel otomatis, buat manual untuk sinkron)
-- =================================================================
CREATE TABLE IF NOT EXISTS `migrations` (
    `id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `migration` VARCHAR(255) NOT NULL,
    `batch`     INT NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tandai migration sudah dijalankan agar php artisan migrate tidak jalankan ulang
INSERT IGNORE INTO `migrations` (`migration`, `batch`) VALUES
('0001_01_01_000000_create_users_table', 1),
('0001_01_01_000001_create_cache_table', 1),
('0001_01_01_000002_create_jobs_table', 1);

-- =================================================================
-- SELESAI
-- =================================================================
