-- ============================================================================
-- Ymmo Real Estate Platform - Initial Database Schema
-- Database: PostgreSQL 13+
-- Author: Stan (DEV Lead)
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================================
-- USERS & AUTHENTICATION
-- ============================================================================

CREATE TABLE auth_user (
    id SERIAL PRIMARY KEY,
    username VARCHAR(150) UNIQUE NOT NULL,
    email VARCHAR(254) UNIQUE NOT NULL,
    first_name VARCHAR(150),
    last_name VARCHAR(150),
    password VARCHAR(128) NOT NULL,
    is_staff BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_superuser BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    date_joined TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auth_user_email ON auth_user(email);
CREATE INDEX idx_auth_user_username ON auth_user(username);

-- ============================================================================
-- PROPERTIES
-- ============================================================================

CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',

    -- Location
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'France',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location GEOGRAPHY(POINT, 4326),

    -- Property details
    property_type VARCHAR(50) NOT NULL, -- 'house', 'apartment', 'land', 'commercial'
    square_meters INTEGER,
    bedrooms INTEGER,
    bathrooms DECIMAL(3, 1),
    living_area INTEGER,
    year_built INTEGER,

    -- Features
    has_garage BOOLEAN DEFAULT FALSE,
    has_garden BOOLEAN DEFAULT FALSE,
    has_pool BOOLEAN DEFAULT FALSE,
    has_elevator BOOLEAN DEFAULT FALSE,
    energy_rating VARCHAR(5), -- A, B, C, D, E, F, G
    condition VARCHAR(50), -- 'new', 'excellent', 'good', 'fair', 'needs_renovation'

    -- Status
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    view_count INTEGER DEFAULT 0,

    -- Relations
    agent_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE SET NULL,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    listed_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_properties_city ON properties(city);
CREATE INDEX idx_properties_price ON properties(price);
CREATE INDEX idx_properties_agent ON properties(agent_id);
CREATE INDEX idx_properties_location ON properties USING GIST(location);
CREATE INDEX idx_properties_type ON properties(property_type);
CREATE INDEX idx_properties_available ON properties(is_available);

-- ============================================================================
-- PROPERTY IMAGES
-- ============================================================================

CREATE TABLE property_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    display_order INTEGER DEFAULT 0,
    alt_text VARCHAR(255),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_property_images_property ON property_images(property_id);

-- ============================================================================
-- AGENTS
-- ============================================================================

CREATE TABLE agents (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE REFERENCES auth_user(id) ON DELETE CASCADE,
    phone VARCHAR(20),
    agency_name VARCHAR(255),
    license_number VARCHAR(100) UNIQUE,
    years_experience INTEGER,
    bio TEXT,
    photo_url VARCHAR(500),
    is_verified BOOLEAN DEFAULT FALSE,
    rating DECIMAL(3, 2), -- 0-5
    total_reviews INTEGER DEFAULT 0,
    properties_sold INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agents_user ON agents(user_id);
CREATE INDEX idx_agents_license ON agents(license_number);

-- ============================================================================
-- TRANSACTIONS / VIEWINGS
-- ============================================================================

CREATE TABLE viewings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    buyer_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    agent_id INTEGER NOT NULL REFERENCES agents(id) ON DELETE SET NULL,

    scheduled_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'scheduled', -- 'scheduled', 'completed', 'cancelled', 'no-show'
    notes TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_viewings_property ON viewings(property_id);
CREATE INDEX idx_viewings_buyer ON viewings(buyer_id);
CREATE INDEX idx_viewings_agent ON viewings(agent_id);
CREATE INDEX idx_viewings_status ON viewings(status);

-- ============================================================================
-- TRANSACTIONS (Sales)
-- ============================================================================

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE RESTRICT,
    buyer_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE SET NULL,
    seller_id INTEGER REFERENCES auth_user(id) ON DELETE SET NULL,
    agent_id INTEGER REFERENCES agents(id) ON DELETE SET NULL,

    sale_price DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',

    -- Status
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'offer', 'accepted', 'completed', 'cancelled'
    transaction_date TIMESTAMP WITH TIME ZONE,
    completion_date TIMESTAMP WITH TIME ZONE,

    -- Commission
    commission_percentage DECIMAL(5, 2),
    commission_amount DECIMAL(12, 2),

    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_property ON transactions(property_id);
CREATE INDEX idx_transactions_buyer ON transactions(buyer_id);
CREATE INDEX idx_transactions_agent ON transactions(agent_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);

-- ============================================================================
-- FAVORITES / WISHLIST
-- ============================================================================

CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, property_id)
);

CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_property ON favorites(property_id);

-- ============================================================================
-- INQUIRIES / CONTACT REQUESTS
-- ============================================================================

CREATE TABLE inquiries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    sender_name VARCHAR(255) NOT NULL,
    sender_email VARCHAR(254) NOT NULL,
    sender_phone VARCHAR(20),
    message TEXT NOT NULL,

    status VARCHAR(50) DEFAULT 'new', -- 'new', 'contacted', 'resolved', 'spam'
    assigned_agent_id INTEGER REFERENCES agents(id) ON DELETE SET NULL,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_inquiries_property ON inquiries(property_id);
CREATE INDEX idx_inquiries_status ON inquiries(status);
CREATE INDEX idx_inquiries_email ON inquiries(sender_email);

-- ============================================================================
-- REVIEWS & RATINGS
-- ============================================================================

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id INTEGER NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    author_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE SET NULL,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,

    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    comment TEXT,

    verified_purchase BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reviews_agent ON reviews(agent_id);
CREATE INDEX idx_reviews_author ON reviews(author_id);

-- ============================================================================
-- ANALYTICS / LOGS
-- ============================================================================

CREATE TABLE property_views_log (
    id BIGSERIAL PRIMARY KEY,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES auth_user(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    referer TEXT,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_property_views_property ON property_views_log(property_id);
CREATE INDEX idx_property_views_date ON property_views_log(viewed_at);

-- ============================================================================
-- AUDIT LOG
-- ============================================================================

CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES auth_user(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(100),
    changes JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_log_user ON audit_log(user_id);
CREATE INDEX idx_audit_log_resource ON audit_log(resource_type, resource_id);
CREATE INDEX idx_audit_log_created ON audit_log(created_at);

-- ============================================================================
-- DJANGO DEFAULT TABLES
-- ============================================================================

CREATE TABLE django_session (
    session_key VARCHAR(40) PRIMARY KEY,
    session_data TEXT NOT NULL,
    expire_date TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_django_session_expire ON django_session(expire_date);

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Create demo user (admin)
INSERT INTO auth_user (username, email, password, is_staff, is_superuser, is_active)
VALUES ('admin', 'admin@ymmo.local', 'pbkdf2_sha256$600000$xxx$xxx', true, true, true)
ON CONFLICT DO NOTHING;

-- Create demo agent
INSERT INTO agents (user_id, agency_name, phone, license_number, years_experience)
SELECT id, 'Ymmo Agency', '+33612345678', 'YMMO-001', 10
FROM auth_user WHERE username = 'admin'
ON CONFLICT DO NOTHING;
