--
-- PostgreSQL database dump
--


-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: clean_expired_verification_codes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.clean_expired_verification_codes() RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN

    DELETE FROM verification_codes WHERE expires_at < CURRENT_TIMESTAMP;

END;

$$;


ALTER FUNCTION public.clean_expired_verification_codes() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

    NEW.updated_at = CURRENT_TIMESTAMP;

    RETURN NEW;

END;

$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_versions (
    id integer NOT NULL,
    version character varying(50) NOT NULL,
    platform character varying(20) NOT NULL,
    distribution_type character varying(20) DEFAULT 'oss'::character varying,
    package_url text,
    oss_object_key character varying(500),
    release_notes text,
    status character varying(20) DEFAULT 'draft'::character varying,
    is_force_update boolean DEFAULT false,
    min_supported_version character varying(50),
    file_size bigint DEFAULT 0,
    file_hash character varying(128),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    published_at timestamp with time zone,
    created_by character varying(100)
);


ALTER TABLE public.app_versions OWNER TO postgres;

--
-- Name: TABLE app_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.app_versions IS 'Application version upgrade information table';


--
-- Name: COLUMN app_versions.version; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.version IS 'Version number';


--
-- Name: COLUMN app_versions.platform; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.platform IS 'Platform: windows, android, ios';


--
-- Name: COLUMN app_versions.distribution_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.distribution_type IS 'Distribution type: oss(OSS file), url(external link like TestFlight)';


--
-- Name: COLUMN app_versions.package_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.package_url IS 'Upgrade package download address/distribution address';


--
-- Name: COLUMN app_versions.oss_object_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.oss_object_key IS 'OSS object storage key (only for oss type)';


--
-- Name: COLUMN app_versions.release_notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.release_notes IS 'Upgrade description information';


--
-- Name: COLUMN app_versions.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.status IS 'Status: draft, published, deprecated';


--
-- Name: COLUMN app_versions.is_force_update; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.is_force_update IS 'Whether to force update';


--
-- Name: COLUMN app_versions.min_supported_version; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.min_supported_version IS 'Minimum supported version';


--
-- Name: COLUMN app_versions.file_size; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.file_size IS 'File size (bytes, only for oss type)';


--
-- Name: COLUMN app_versions.file_hash; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.app_versions.file_hash IS 'File hash value (only for oss type)';


--
-- Name: app_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.app_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_versions_id_seq OWNER TO postgres;

--
-- Name: app_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.app_versions_id_seq OWNED BY public.app_versions.id;


--
-- Name: device_registrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_registrations (
    id integer NOT NULL,
    uuid character varying(255) NOT NULL,
    request_ip character varying(50) NOT NULL,
    platform character varying(20) NOT NULL,
    system_info jsonb NOT NULL,
    installed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.device_registrations OWNER TO postgres;

--
-- Name: TABLE device_registrations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.device_registrations IS 'Device registration table: records device information on first app startup';


--
-- Name: COLUMN device_registrations.uuid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.device_registrations.uuid IS 'Database encryption key UUID (original UUID, not MD5 encrypted)';


--
-- Name: COLUMN device_registrations.request_ip; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.device_registrations.request_ip IS 'Client request IP address';


--
-- Name: COLUMN device_registrations.platform; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.device_registrations.platform IS 'Operating system platform: android, ios, windows, macos, linux';


--
-- Name: COLUMN device_registrations.system_info; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.device_registrations.system_info IS 'System detailed information in JSON format, includes device model, OS version, etc';


--
-- Name: COLUMN device_registrations.installed_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.device_registrations.installed_at IS 'Application first installation/startup time';


--
-- Name: device_registrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.device_registrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.device_registrations_id_seq OWNER TO postgres;

--
-- Name: device_registrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.device_registrations_id_seq OWNED BY public.device_registrations.id;


--
-- Name: favorite_contacts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favorite_contacts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    contact_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.favorite_contacts OWNER TO postgres;

--
-- Name: TABLE favorite_contacts; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.favorite_contacts IS 'Favorite Contacts Table';


--
-- Name: COLUMN favorite_contacts.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorite_contacts.user_id IS 'User ID';


--
-- Name: COLUMN favorite_contacts.contact_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorite_contacts.contact_id IS 'Favorite contact ID';


--
-- Name: COLUMN favorite_contacts.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorite_contacts.created_at IS 'Created at';


--
-- Name: favorite_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.favorite_contacts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.favorite_contacts_id_seq OWNER TO postgres;

--
-- Name: favorite_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.favorite_contacts_id_seq OWNED BY public.favorite_contacts.id;


--
-- Name: favorite_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favorite_groups (
    id integer NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.favorite_groups OWNER TO postgres;

--
-- Name: TABLE favorite_groups; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.favorite_groups IS 'Favorite Groups Table';


--
-- Name: COLUMN favorite_groups.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorite_groups.user_id IS 'User ID';


--
-- Name: COLUMN favorite_groups.group_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorite_groups.group_id IS 'Favorite group ID';


--
-- Name: COLUMN favorite_groups.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorite_groups.created_at IS 'Created at';


--
-- Name: favorite_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.favorite_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.favorite_groups_id_seq OWNER TO postgres;

--
-- Name: favorite_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.favorite_groups_id_seq OWNED BY public.favorite_groups.id;


--
-- Name: favorites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favorites (
    id integer NOT NULL,
    user_id integer NOT NULL,
    message_id integer,
    content text NOT NULL,
    message_type character varying(20) DEFAULT 'text'::character varying,
    file_name character varying(255),
    sender_id integer NOT NULL,
    sender_name character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    server_id integer,
    sync_status character varying(20) DEFAULT 'synced'::character varying
);


ALTER TABLE public.favorites OWNER TO postgres;

--
-- Name: TABLE favorites; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.favorites IS 'User Favorite Messages Table';


--
-- Name: COLUMN favorites.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorites.user_id IS 'User ID who favorited this message';


--
-- Name: COLUMN favorites.message_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorites.message_id IS 'Favorited message ID (nullable if original message is deleted)';


--
-- Name: COLUMN favorites.content; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorites.content IS 'Message content';


--
-- Name: COLUMN favorites.message_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorites.message_type IS 'Message type: text, image, file, quoted';


--
-- Name: COLUMN favorites.file_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorites.file_name IS 'File name (for file type)';


--
-- Name: COLUMN favorites.sender_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorites.sender_id IS 'Original message sender ID';


--
-- Name: COLUMN favorites.sender_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorites.sender_name IS 'Original message sender name';


--
-- Name: COLUMN favorites.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.favorites.created_at IS 'Favorited at';


--
-- Name: favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.favorites_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.favorites_id_seq OWNER TO postgres;

--
-- Name: favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.favorites_id_seq OWNED BY public.favorites.id;


--
-- Name: file_assistant_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_assistant_messages (
    id integer NOT NULL,
    user_id integer NOT NULL,
    content text NOT NULL,
    message_type character varying(20) DEFAULT 'text'::character varying,
    file_name character varying(255),
    quoted_message_id integer,
    quoted_message_content text,
    status character varying(20) DEFAULT 'normal'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    server_id integer
);


ALTER TABLE public.file_assistant_messages OWNER TO postgres;

--
-- Name: TABLE file_assistant_messages; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.file_assistant_messages IS 'File Assistant Messages Table';


--
-- Name: COLUMN file_assistant_messages.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.file_assistant_messages.user_id IS 'User ID';


--
-- Name: COLUMN file_assistant_messages.content; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.file_assistant_messages.content IS 'Message content';


--
-- Name: COLUMN file_assistant_messages.message_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.file_assistant_messages.message_type IS 'Message type: text, image, file, quoted';


--
-- Name: COLUMN file_assistant_messages.file_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.file_assistant_messages.file_name IS 'File name (for file type)';


--
-- Name: COLUMN file_assistant_messages.quoted_message_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.file_assistant_messages.quoted_message_id IS 'Quoted message ID';


--
-- Name: COLUMN file_assistant_messages.quoted_message_content; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.file_assistant_messages.quoted_message_content IS 'Quoted message content';


--
-- Name: COLUMN file_assistant_messages.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.file_assistant_messages.status IS 'Message status: normal, recalled';


--
-- Name: COLUMN file_assistant_messages.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.file_assistant_messages.created_at IS 'Created at';


--
-- Name: file_assistant_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.file_assistant_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.file_assistant_messages_id_seq OWNER TO postgres;

--
-- Name: file_assistant_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.file_assistant_messages_id_seq OWNED BY public.file_assistant_messages.id;


--
-- Name: group_members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_members (
    id integer NOT NULL,
    group_id integer NOT NULL,
    user_id integer NOT NULL,
    nickname character varying(100),
    remark character varying(255),
    role character varying(20) DEFAULT 'member'::character varying,
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_muted boolean DEFAULT false,
    approval_status character varying(20) DEFAULT 'approved'::character varying,
    do_not_disturb boolean DEFAULT false,
    CONSTRAINT check_approval_status CHECK (((approval_status)::text = ANY (ARRAY[('pending'::character varying)::text, ('approved'::character varying)::text, ('rejected'::character varying)::text])))
);


ALTER TABLE public.group_members OWNER TO postgres;

--
-- Name: COLUMN group_members.is_muted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_members.is_muted IS 'Whether the member is muted';


--
-- Name: COLUMN group_members.approval_status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_members.approval_status IS 'Approval status: pending, approved, rejected';


--
-- Name: COLUMN group_members.do_not_disturb; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_members.do_not_disturb IS 'Do not disturb: true displays only a red dot, false displays unread message count';


--
-- Name: group_members_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.group_members_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.group_members_id_seq OWNER TO postgres;

--
-- Name: group_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.group_members_id_seq OWNED BY public.group_members.id;


--
-- Name: group_message_reads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_message_reads (
    id integer NOT NULL,
    group_message_id integer NOT NULL,
    user_id integer NOT NULL,
    read_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.group_message_reads OWNER TO postgres;

--
-- Name: group_message_reads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.group_message_reads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.group_message_reads_id_seq OWNER TO postgres;

--
-- Name: group_message_reads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.group_message_reads_id_seq OWNED BY public.group_message_reads.id;


--
-- Name: group_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_messages (
    id integer NOT NULL,
    group_id integer NOT NULL,
    sender_id integer,
    sender_name character varying(100) NOT NULL,
    content text NOT NULL,
    message_type character varying(20) DEFAULT 'text'::character varying,
    file_name character varying(255),
    quoted_message_id integer,
    quoted_message_content text,
    status character varying(20) DEFAULT 'normal'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    sender_avatar text,
    mentioned_user_ids text,
    mentions text,
    deleted_by_users text DEFAULT ''::text,
    call_type character varying(20),
    channel_name character varying(255),
    sender_nickname character varying(100),
    sender_full_name character varying(100),
    server_id integer,
    voice_duration integer
);


ALTER TABLE public.group_messages OWNER TO postgres;

--
-- Name: COLUMN group_messages.sender_avatar; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_messages.sender_avatar IS 'Sender avatar URL';


--
-- Name: COLUMN group_messages.mentioned_user_ids; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_messages.mentioned_user_ids IS 'List of mentioned user IDs (comma-separated string)';


--
-- Name: COLUMN group_messages.mentions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_messages.mentions IS 'Mention text content (e.g., "@all" or "@username")';


--
-- Name: COLUMN group_messages.deleted_by_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_messages.deleted_by_users IS 'Comma-separated list of user IDs who have deleted this message';


--
-- Name: COLUMN group_messages.call_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_messages.call_type IS 'Call type (voice/video), only used for call_initiated type messages';


--
-- Name: COLUMN group_messages.channel_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_messages.channel_name IS 'Agora channel name, used to join group calls, only used for call_initiated type messages';


--
-- Name: COLUMN group_messages.sender_nickname; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_messages.sender_nickname IS 'Sender group nickname (from group_members.nickname)';


--
-- Name: COLUMN group_messages.sender_full_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_messages.sender_full_name IS 'Sender full name (from users.full_name)';


--
-- Name: COLUMN group_messages.voice_duration; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.group_messages.voice_duration IS 'Voice message duration (seconds)';


--
-- Name: group_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.group_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.group_messages_id_seq OWNER TO postgres;

--
-- Name: group_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.group_messages_id_seq OWNED BY public.group_messages.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.groups (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    announcement text,
    avatar character varying(255),
    owner_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone,
    all_muted boolean DEFAULT false NOT NULL,
    invite_confirmation boolean DEFAULT false,
    admin_only_edit_name boolean DEFAULT false NOT NULL,
    member_view_permission boolean DEFAULT true
);


ALTER TABLE public.groups OWNER TO postgres;

--
-- Name: COLUMN groups.deleted_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.groups.deleted_at IS 'Soft delete timestamp (NULL means not deleted)';


--
-- Name: COLUMN groups.all_muted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.groups.all_muted IS 'Whether all members are muted';


--
-- Name: COLUMN groups.invite_confirmation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.groups.invite_confirmation IS 'Enable group invite confirmation (member invitations require approval)';


--
-- Name: COLUMN groups.admin_only_edit_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.groups.admin_only_edit_name IS 'Whether only the group owner/admins can modify the group name';


--
-- Name: COLUMN groups.member_view_permission; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.groups.member_view_permission IS 'Member view permission: true = regular members can view other members'' information, false = only the owner and administrators can view member information.';


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.groups_id_seq OWNER TO postgres;

--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    sender_id integer NOT NULL,
    receiver_id integer NOT NULL,
    content text NOT NULL,
    message_type character varying(20) DEFAULT 'text'::character varying,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    read_at timestamp without time zone,
    sender_name character varying(100),
    receiver_name character varying(100),
    file_name character varying(255) DEFAULT NULL::character varying,
    quoted_message_id integer,
    quoted_message_content text,
    status character varying(20) DEFAULT 'normal'::character varying,
    deleted_by_users text DEFAULT ''::text,
    sender_avatar text,
    receiver_avatar text,
    call_type character varying(20) DEFAULT NULL::character varying,
    server_id integer,
    voice_duration integer
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: COLUMN messages.sender_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.sender_name IS 'Sender username (expanded from 50 to 100 characters to match user full_name length)';


--
-- Name: COLUMN messages.receiver_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.receiver_name IS 'Receiver username (expanded from 50 to 100 characters to match user full_name length)';


--
-- Name: COLUMN messages.file_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.file_name IS 'File name (for file type messages)';


--
-- Name: COLUMN messages.quoted_message_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.quoted_message_id IS 'Quoted message ID';


--
-- Name: COLUMN messages.quoted_message_content; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.quoted_message_content IS 'Quoted message content (for display)';


--
-- Name: COLUMN messages.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.status IS 'Message status: normal, recalled';


--
-- Name: COLUMN messages.deleted_by_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.deleted_by_users IS 'List of user IDs who deleted this message (comma-separated), e.g., 1,2,3';


--
-- Name: COLUMN messages.sender_avatar; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.sender_avatar IS 'Sender avatar URL';


--
-- Name: COLUMN messages.receiver_avatar; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.receiver_avatar IS 'Receiver avatar URL';


--
-- Name: COLUMN messages.call_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.call_type IS 'Call type (voice/video), used only for call message types';


--
-- Name: COLUMN messages.voice_duration; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.voice_duration IS 'Voice message duration (seconds)';


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_id_seq OWNER TO postgres;

--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: server_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.server_settings (
    id integer NOT NULL,
    key character varying(100) NOT NULL,
    value text NOT NULL,
    description character varying(255) DEFAULT ''::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.server_settings OWNER TO postgres;

--
-- Name: TABLE server_settings; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.server_settings IS 'Server Settings Table';


--
-- Name: server_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.server_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.server_settings_id_seq OWNER TO postgres;

--
-- Name: server_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.server_settings_id_seq OWNED BY public.server_settings.id;


--
-- Name: user_relations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_relations (
    id integer NOT NULL,
    user_id integer NOT NULL,
    friend_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    approval_status character varying(20) DEFAULT 'approved'::character varying NOT NULL,
    is_blocked boolean DEFAULT false NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    blocked_by_user_id integer,
    deleted_by_user_id integer,
    CONSTRAINT check_approval_status CHECK (((approval_status)::text = ANY (ARRAY[('pending'::character varying)::text, ('approved'::character varying)::text, ('rejected'::character varying)::text])))
);


ALTER TABLE public.user_relations OWNER TO postgres;

--
-- Name: TABLE user_relations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_relations IS 'User Relations Table';


--
-- Name: COLUMN user_relations.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_relations.user_id IS 'User ID';


--
-- Name: COLUMN user_relations.friend_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_relations.friend_id IS 'Friend user ID';


--
-- Name: COLUMN user_relations.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_relations.created_at IS 'Created at';


--
-- Name: COLUMN user_relations.approval_status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_relations.approval_status IS 'Approval status: pending, approved, rejected';


--
-- Name: COLUMN user_relations.is_blocked; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_relations.is_blocked IS 'Whether the user is blocked; true means blocked';


--
-- Name: COLUMN user_relations.is_deleted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_relations.is_deleted IS 'Whether the relation is deleted (soft delete); true means deleted';


--
-- Name: COLUMN user_relations.blocked_by_user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_relations.blocked_by_user_id IS 'User ID who performed the block operation';


--
-- Name: COLUMN user_relations.deleted_by_user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_relations.deleted_by_user_id IS 'User ID who performed the delete operation';


--
-- Name: user_relations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_relations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_relations_id_seq OWNER TO postgres;

--
-- Name: user_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_relations_id_seq OWNED BY public.user_relations.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    password character varying(255) NOT NULL,
    phone character varying(20) DEFAULT NULL::character varying,
    email character varying(100) DEFAULT NULL::character varying,
    avatar character varying(255) DEFAULT ''::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    auth_code character varying(100) DEFAULT NULL::character varying,
    full_name character varying(100) DEFAULT NULL::character varying,
    gender character varying(10) DEFAULT NULL::character varying,
    work_signature character varying(500) DEFAULT NULL::character varying,
    status character varying(50) DEFAULT 'offline'::character varying,
    landline character varying(20) DEFAULT NULL::character varying,
    short_number character varying(10) DEFAULT NULL::character varying,
    department character varying(100) DEFAULT NULL::character varying,
    "position" character varying(100) DEFAULT NULL::character varying,
    region character varying(100) DEFAULT NULL::character varying,
    invite_code character varying(6) DEFAULT NULL::character varying,
    invited_by_code character varying(6) DEFAULT NULL::character varying,
    CONSTRAINT check_gender CHECK (((gender)::text = ANY (ARRAY[(NULL::character varying)::text, ('male'::character varying)::text, ('female'::character varying)::text, ('other'::character varying)::text]))),
    CONSTRAINT check_status CHECK (((status)::text = ANY (ARRAY[('online'::character varying)::text, ('busy'::character varying)::text, ('away'::character varying)::text, ('offline'::character varying)::text])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.users IS 'Users Table';


--
-- Name: COLUMN users.auth_code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.auth_code IS 'Authorization code';


--
-- Name: COLUMN users.full_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.full_name IS 'Full name';


--
-- Name: COLUMN users.gender; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.gender IS 'Gender: male, female, other';


--
-- Name: COLUMN users.work_signature; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.work_signature IS 'Work signature';


--
-- Name: COLUMN users.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.status IS 'Status: online, busy, away, offline';


--
-- Name: COLUMN users.landline; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.landline IS 'Landline';


--
-- Name: COLUMN users.short_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.short_number IS 'Short number';


--
-- Name: COLUMN users.department; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.department IS 'Department';


--
-- Name: COLUMN users."position"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users."position" IS 'Position';


--
-- Name: COLUMN users.region; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.region IS 'Region';


--
-- Name: COLUMN users.invite_code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.invite_code IS 'User''s own invite code (6 characters, 0-9a-zA-Z)';


--
-- Name: COLUMN users.invited_by_code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.invited_by_code IS 'Invite code used during registration';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: verification_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.verification_codes (
    id integer NOT NULL,
    account character varying(100) NOT NULL,
    code character varying(10) NOT NULL,
    type character varying(20) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT verification_codes_type_check CHECK (((type)::text = ANY (ARRAY[('login'::character varying)::text, ('register'::character varying)::text, ('reset'::character varying)::text])))
);


ALTER TABLE public.verification_codes OWNER TO postgres;

--
-- Name: TABLE verification_codes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.verification_codes IS 'Verification Codes Table';


--
-- Name: verification_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.verification_codes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.verification_codes_id_seq OWNER TO postgres;

--
-- Name: verification_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.verification_codes_id_seq OWNED BY public.verification_codes.id;


--
-- Name: app_versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_versions ALTER COLUMN id SET DEFAULT nextval('public.app_versions_id_seq'::regclass);


--
-- Name: device_registrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_registrations ALTER COLUMN id SET DEFAULT nextval('public.device_registrations_id_seq'::regclass);


--
-- Name: favorite_contacts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_contacts ALTER COLUMN id SET DEFAULT nextval('public.favorite_contacts_id_seq'::regclass);


--
-- Name: favorite_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_groups ALTER COLUMN id SET DEFAULT nextval('public.favorite_groups_id_seq'::regclass);


--
-- Name: favorites id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites ALTER COLUMN id SET DEFAULT nextval('public.favorites_id_seq'::regclass);


--
-- Name: file_assistant_messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assistant_messages ALTER COLUMN id SET DEFAULT nextval('public.file_assistant_messages_id_seq'::regclass);


--
-- Name: group_members id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_members ALTER COLUMN id SET DEFAULT nextval('public.group_members_id_seq'::regclass);


--
-- Name: group_message_reads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_message_reads ALTER COLUMN id SET DEFAULT nextval('public.group_message_reads_id_seq'::regclass);


--
-- Name: group_messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_messages ALTER COLUMN id SET DEFAULT nextval('public.group_messages_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: server_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.server_settings ALTER COLUMN id SET DEFAULT nextval('public.server_settings_id_seq'::regclass);


--
-- Name: user_relations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_relations ALTER COLUMN id SET DEFAULT nextval('public.user_relations_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: verification_codes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.verification_codes ALTER COLUMN id SET DEFAULT nextval('public.verification_codes_id_seq'::regclass);


--
-- Data for Name: app_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_versions (id, version, platform, distribution_type, package_url, oss_object_key, release_notes, status, is_force_update, min_supported_version, file_size, file_hash, created_at, updated_at, published_at, created_by) FROM stdin;
3	1.0.23-1765520167	ios	url	https://mtg4n.xmlac168.com/MRq5/hONr3hEJxoJXez4z	\N	浼樺寲瀹夎鍖呬笅杞藉拰寮圭獥鍏抽棴闂	published	f	\N	0	\N	2025-12-11 00:06:46.823815+08	2025-12-14 01:03:22+08	2025-12-14 01:03:22+08	
2	1.0.23-1765520167	windows	url	https://xn--wxtp0q.vip/releases/windows/1.0.23-1765520167.zip	\N	浼樺寲瀹夎鍖呬笅杞藉拰寮圭獥鍏抽棴闂	published	f	\N	65322192	61a610e2b18bab7f5daddfdec0edb064	2025-12-10 23:59:46.57674+08	2025-12-14 16:38:42+08	2025-12-14 16:38:42+08	
4	1.0.23-1765520167	android	url	https://xn--wxtp0q.vip/releases/android/1.0.23-1765520167.apk	\N	浼樺寲瀹夎鍖呬笅杞藉拰寮圭獥鍏抽棴闂	published	f	\N	304619933	8ea6f67f23d4ebe7421a24d66d060165	2025-12-11 00:09:54.601814+08	2025-12-14 16:39:17+08	2025-12-14 16:39:17+08	
\.


--
-- Data for Name: device_registrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_registrations (id, uuid, request_ip, platform, system_info, installed_at, created_at, updated_at) FROM stdin;
1	65456255-5196-4d8a-96ee-0653cbf22b03	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 16:32:52.691175	2025-11-24 16:32:52.399671	2025-11-24 16:32:52.399671
2	73c978aa-91c1-4a78-a5b4-2f5fe96bdffb	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 16:59:42.547024	2025-11-24 16:59:42.160502	2025-11-24 16:59:42.160502
3	36f60dbf-5cb8-4f7a-811e-4df7a88fab98	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 17:03:19.046834	2025-11-24 17:03:18.664769	2025-11-24 17:03:18.664769
5	e1f51d0d-049b-4ac5-bb7e-d9b8fa6e597d	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 17:23:18.035138	2025-11-24 17:23:17.616277	2025-11-24 17:23:17.616277
6	6c330562-016b-4e2f-9ec8-4d37a07535a9	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 17:25:01.609749	2025-11-24 17:25:01.193762	2025-11-24 17:25:01.193762
7	08063d2e-5811-4d18-ad09-fe10d715cb6b	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 18:31:51.740815	2025-11-24 18:31:51.280192	2025-11-24 18:31:51.280192
8	e4b06750-ba49-41bc-b1cc-58a62a606aca	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 18:49:29.879892	2025-11-24 18:49:29.370826	2025-11-24 18:49:29.370826
9	3106432c-f53e-4404-9552-b5d8bba52c45	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 18:51:17.015426	2025-11-24 18:51:16.544603	2025-11-24 18:51:16.544603
10	56755645-eaf6-4c0f-9136-158f9cd83aa9	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 18:52:03.292145	2025-11-24 18:52:02.794389	2025-11-24 18:52:02.794389
11	82015ad5-9fb8-4903-8bc2-c37a96c3c31a	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 18:54:37.352337	2025-11-24 18:54:36.900083	2025-11-24 18:54:36.900083
12	fce81ded-188c-46ce-854e-6ebc582132ec	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 18:55:47.033147	2025-11-24 18:55:46.534483	2025-11-24 18:55:46.534483
13	ee37dbdd-c016-475f-9767-2a6aa09414ea	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 19:22:00.760805	2025-11-24 19:22:00.232015	2025-11-24 19:22:00.232015
14	e794de5d-438f-46e8-9aa8-06dcc3aacf75	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 19:36:29.31927	2025-11-24 19:36:28.853927	2025-11-24 19:36:28.853927
15	2389c0e7-eef1-4835-8ff3-b07fef2b424f	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 20:24:24.407072	2025-11-24 20:24:23.867995	2025-11-24 20:24:23.867995
16	e70cc0eb-5d3d-4b1e-8a4a-d36eaa377ff7	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 21:05:42.752888	2025-11-24 21:05:42.136421	2025-11-24 21:05:42.136421
17	87be40bb-b6b7-4316-902b-9d2bc986274a	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 21:09:35.86997	2025-11-24 21:09:35.240155	2025-11-24 21:09:35.240155
18	28b8a56e-4d1c-49e4-80ab-038c88e51465	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 21:25:37.164615	2025-11-24 21:25:37.906537	2025-11-24 21:25:37.906537
19	fade0452-0db9-4316-98ff-0c0c070fa0a7	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 21:43:45.453674	2025-11-24 21:43:44.941572	2025-11-24 21:43:44.941572
20	916c0ce5-3397-4266-bff2-401c3fc3935e	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 21:49:50.617456	2025-11-24 21:49:49.962452	2025-11-24 21:49:49.962452
21	4ef9553a-b4f0-4cce-9e40-88e74a087084	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 21:55:30.356098	2025-11-24 21:55:29.739815	2025-11-24 21:55:29.739815
22	809d2349-6474-4bc2-9bd5-a8f002d9a181	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 22:11:03.742009	2025-11-24 22:11:03.063577	2025-11-24 22:11:03.063577
23	584b8d8a-c699-459a-9ac1-efefd1394022	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 22:18:47.363102	2025-11-24 22:18:46.728666	2025-11-24 22:18:46.728666
24	b0b3eb0b-e7fa-49be-9296-dcc5e24de9a6	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 22:19:23.608649	2025-11-24 22:19:22.934494	2025-11-24 22:19:22.934494
25	c9445ad5-203c-4c46-b5c3-09cc919cec0c	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 22:34:33.1772	2025-11-24 22:34:32.479725	2025-11-24 22:34:32.479725
26	f27e50f7-83b8-483c-8ab1-b6c0b516cfd6	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 00:03:41.342239	2025-11-25 00:03:40.550861	2025-11-25 00:03:40.550861
27	d163df22-c6d1-400e-8143-462395277ed8	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 00:05:53.019333	2025-11-25 00:05:52.248281	2025-11-25 00:05:52.248281
4	682fa00e-43d7-4218-b110-e17e7d84b5d3	192.168.1.6	windows	{"os": "windows", "is_web": false, "locale": "zh_CN", "is_debug": true, "os_version": "\\"Windows 10 Pro\\" 10.0 (Build 19045)", "number_of_processors": 16}	2025-11-24 17:03:53.236877	2025-11-24 17:03:54.632007	2025-12-10 22:26:43.296421
28	22b596e4-b8c0-4957-bdbb-ce5f19178f67	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 00:16:17.107674	2025-11-25 00:16:16.353663	2025-11-25 00:16:16.353663
29	dff8391f-d956-43f3-999c-d7febcf0723e	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 08:18:10.978674	2025-11-25 08:18:11.49042	2025-11-25 08:18:11.49042
30	8d6a82ce-4f7b-47d6-aa16-41af524a9bcd	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 08:28:20.15522	2025-11-25 08:28:20.595404	2025-11-25 08:28:20.595404
31	48767bc9-275d-45c6-a9ad-c710b7a1ee63	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 08:34:24.036256	2025-11-25 08:34:24.494151	2025-11-25 08:34:24.494151
32	d5029c8f-892a-41e7-878a-ae03bffdd824	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 08:37:53.699159	2025-11-25 08:37:54.144359	2025-11-25 08:37:54.144359
33	cb15ceff-8484-4f69-b3db-3d4574d9d1ff	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 08:41:28.664037	2025-11-25 08:41:29.11547	2025-11-25 08:41:29.11547
34	7091dc72-2c27-4db4-88ad-88ad66bc84d2	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 08:47:21.316979	2025-11-25 08:47:23.160436	2025-11-25 08:47:23.160436
35	3eacb277-4129-4bf2-8767-9c2ca53afb9c	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 08:52:38.939582	2025-11-25 08:52:39.369406	2025-11-25 08:52:39.369406
36	c1135659-fcbc-414a-a2be-549c20ab7a58	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 08:56:09.652759	2025-11-25 08:56:10.085898	2025-11-25 08:56:10.085898
37	246ea2ea-bf1c-437e-abdc-e168e9569a13	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 08:56:25.013069	2025-11-25 08:56:25.450198	2025-11-25 08:56:25.450198
38	0558766f-0c26-4199-8282-b451ab49c91a	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 08:59:58.9532	2025-11-25 08:59:59.393356	2025-11-25 08:59:59.393356
39	d85b1192-9aa5-4a4c-9e8d-12839f376a02	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 09:02:09.025642	2025-11-25 09:02:09.455145	2025-11-25 09:02:09.455145
40	2f16f48b-bf89-4d63-8299-53d632537086	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 09:04:09.891849	2025-11-25 09:04:10.323325	2025-11-25 09:04:10.323325
41	bd33dc2f-a36a-4e25-b107-893dad65f2b8	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 09:10:04.785869	2025-11-25 09:10:05.23198	2025-11-25 09:10:05.23198
42	69586b51-c69e-4726-9256-6c5f7a33c8ab	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 09:14:08.319645	2025-11-25 09:14:08.730014	2025-11-25 09:14:08.730014
43	b56f40a7-e92e-4258-bbfd-3173222a9734	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 09:21:04.546752	2025-11-25 09:21:04.999374	2025-11-25 09:21:04.999374
44	762c6262-2e6c-41f2-bcad-9d0fd1fd992e	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-25 11:11:57.929186	2025-11-25 11:11:58.225914	2025-11-25 11:11:58.225914
45	fc544ae2-4b60-40a6-82d4-4ca1a84d1b29	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 11:19:30.049053	2025-11-25 11:19:29.020267	2025-11-25 11:19:29.020267
46	bd5019ba-a67c-4fbe-9537-c8d1174dce45	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 11:32:23.338895	2025-11-25 11:32:22.1247	2025-11-25 11:32:22.1247
47	33cc8ede-faf3-49d2-bd0f-aece1b7f18d9	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 11:35:58.716565	2025-11-25 11:35:58.376009	2025-11-25 11:35:58.376009
48	f2032178-76ce-47ff-a875-f9d3196c809c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 11:53:03.75144	2025-11-25 11:53:04.111254	2025-11-25 11:53:04.111254
49	915c5527-cbef-40e7-a768-f9597a1d5093	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 11:54:37.821247	2025-11-25 11:54:37.867014	2025-11-25 11:54:37.867014
50	25236a4f-8012-419c-a570-89c479291a84	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 12:04:01.442658	2025-11-25 12:04:01.469949	2025-11-25 12:04:01.469949
51	a15ba249-f8d0-4bf7-9f7b-5cc1b805fb72	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 12:07:09.202745	2025-11-25 12:07:09.265357	2025-11-25 12:07:09.265357
52	1d02925d-f835-4f45-af50-7c995b6ace83	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 12:22:04.767515	2025-11-25 12:22:04.998069	2025-11-25 12:22:04.998069
53	77f31dae-e86d-4400-8bc3-3039363d511b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 12:24:40.700709	2025-11-25 12:24:40.759095	2025-11-25 12:24:40.759095
54	e0330999-3e46-429b-bfd1-f3a136bb8e0e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 12:29:12.995706	2025-11-25 12:29:13.014599	2025-11-25 12:29:13.014599
55	a752c3d7-80de-41ef-8863-234c552babb9	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 13:22:20.501071	2025-11-25 13:22:20.726887	2025-11-25 13:22:20.726887
56	7e3842d6-82e5-4336-bd4d-b5772e576edd	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 13:32:35.966598	2025-11-25 13:32:35.919187	2025-11-25 13:32:35.919187
58	b9e9764b-17dc-45b8-8bfd-2437f2c831d7	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 13:38:48.268297	2025-11-25 13:38:48.266142	2025-11-25 13:38:48.266142
59	c1e3880e-f5e8-4acf-ae02-5bfd9279a757	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 13:40:52.462031	2025-11-25 13:40:52.745461	2025-11-25 13:40:52.745461
57	ff0894cf-9adb-44c9-8095-29aff7f3edac	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 13:36:17.950608	2025-11-25 13:36:17.928761	2025-11-25 13:36:17.928761
60	83c48b4b-ce17-42f4-b6d6-01af0d53c6fe	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 14:01:45.321208	2025-11-25 14:01:45.232188	2025-11-25 14:01:45.232188
61	9f53e28c-5ff7-4540-979b-730ff0932744	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 14:04:36.057292	2025-11-25 14:04:36.027166	2025-11-25 14:04:36.027166
62	079fbc65-27aa-4912-8768-d3c8b0b658dc	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 14:10:26.108408	2025-11-25 14:10:26.048856	2025-11-25 14:10:26.048856
63	9d9f1cac-cce2-4adf-9279-370ac4be4d50	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 14:21:34.473242	2025-11-25 14:21:34.393043	2025-11-25 14:21:34.393043
64	24a39f06-b0a5-4d1d-b040-2b560147d0fd	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 14:24:09.402386	2025-11-25 14:24:09.312326	2025-11-25 14:24:09.312326
65	026bc387-61dd-46b3-843d-785a0652f76f	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 14:27:10.979887	2025-11-25 14:27:10.889383	2025-11-25 14:27:10.889383
66	d8f2fadc-5277-4424-9328-c4f60e5f8bef	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 15:38:53.010322	2025-11-25 15:38:52.868778	2025-11-25 15:38:52.868778
67	c738543c-08ec-4f34-96e7-0d399ac467d7	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 15:49:14.387703	2025-11-25 15:49:14.386368	2025-11-25 15:49:14.386368
68	0ade46ac-26a3-48b1-8fa4-a0afc0949115	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 17:19:30.403515	2025-11-25 17:19:30.267807	2025-11-25 17:19:30.267807
69	d8785cd2-4a5c-44c2-bd04-df053cec856a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 17:43:38.497821	2025-11-25 17:43:38.219704	2025-11-25 17:43:38.219704
70	d52a6cfc-13ce-42ad-a6da-90ab5ceda3ea	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 17:53:00.457868	2025-11-25 17:53:00.19576	2025-11-25 17:53:00.19576
71	043c5242-06f3-49ca-bc85-3b6b3a13223a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 18:11:45.130728	2025-11-25 18:11:44.82889	2025-11-25 18:11:44.82889
72	5f91a934-60a7-4157-ac39-156fe3ff9e43	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 18:38:22.495311	2025-11-25 18:38:22.216062	2025-11-25 18:38:22.216062
73	806d8ba8-104a-46ce-a417-0a7aeb0719c4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 19:41:06.463983	2025-11-25 19:41:06.063551	2025-11-25 19:41:06.063551
74	76fb355c-64d8-4daf-913a-7fdb0c87c70c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 19:42:38.706995	2025-11-25 19:42:38.306272	2025-11-25 19:42:38.306272
75	58f1e12d-4e2e-42be-bcb9-75117b170148	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 19:48:22.518389	2025-11-25 19:48:22.112773	2025-11-25 19:48:22.112773
76	4fefdba2-2bd0-4451-8f7c-4b5134c4144a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 19:48:28.33671	2025-11-25 19:48:27.933706	2025-11-25 19:48:27.933706
77	4c75e6df-3eb7-45b6-b186-119753374a30	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 19:54:09.96777	2025-11-25 19:54:09.554267	2025-11-25 19:54:09.554267
78	d8d4acb8-4f4a-4022-9f47-3d91e51bd6a5	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 19:56:03.081249	2025-11-25 19:56:02.85509	2025-11-25 19:56:02.85509
79	2620a77f-a102-446b-b988-5d83d4ab5108	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:04:24.236337	2025-11-25 20:04:23.814206	2025-11-25 20:04:23.814206
80	6a4a6019-a6f2-4c93-a2f2-086e8f59a298	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:04:38.377972	2025-11-25 20:04:37.976805	2025-11-25 20:04:37.976805
81	fcec6d95-1d38-4886-bd3d-18b14e5fc325	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:06:26.82803	2025-11-25 20:06:26.475581	2025-11-25 20:06:26.475581
82	3f4b7969-a306-4256-b5c9-1492dab57cd0	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:10:57.856977	2025-11-25 20:10:57.43292	2025-11-25 20:10:57.43292
83	734e9b02-12b4-4bcc-8493-90cb15f2d20a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:19:03.598085	2025-11-25 20:19:03.181447	2025-11-25 20:19:03.181447
84	a936ebac-6c57-41b4-b322-b59233603f9c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:22:57.277069	2025-11-25 20:22:56.838712	2025-11-25 20:22:56.838712
85	4221d994-5b44-4b43-9716-6cd6d626504a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:23:49.165553	2025-11-25 20:23:48.750801	2025-11-25 20:23:48.750801
86	0f0ba7fd-afba-4d2b-83e1-90c214ef7bc4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:26:30.035708	2025-11-25 20:26:29.597847	2025-11-25 20:26:29.597847
87	6b92c8d7-a62a-4f55-94fb-9e25bb478a9d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:28:56.748026	2025-11-25 20:28:58.263482	2025-11-25 20:28:58.263482
88	77e42379-69f8-48a9-ab40-a9951317079e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:30:32.065887	2025-11-25 20:30:31.62035	2025-11-25 20:30:31.62035
89	d6467e49-2a40-482c-9025-d891461096b6	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:36:40.713391	2025-11-25 20:36:40.276314	2025-11-25 20:36:40.276314
90	347ea98e-e287-4072-8193-893b563747ae	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:40:20.988008	2025-11-25 20:40:20.535356	2025-11-25 20:40:20.535356
91	2373eecb-2b13-4c23-893e-5dab32491d0c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:44:37.067307	2025-11-25 20:44:36.612692	2025-11-25 20:44:36.612692
92	eba49194-37ff-4779-9559-3d13370272bb	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 20:54:35.376118	2025-11-25 20:54:34.921801	2025-11-25 20:54:34.921801
93	ec655448-7286-4377-ab2a-16b3df0a0b68	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 21:23:21.979589	2025-11-25 21:23:21.508674	2025-11-25 21:23:21.508674
94	0c18308a-4149-4625-8927-1e515d6ce1fb	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 21:24:17.87072	2025-11-25 21:24:17.41687	2025-11-25 21:24:17.41687
95	612a609b-cd03-45ea-8c01-464a3458613a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 21:39:20.61494	2025-11-25 21:39:20.117964	2025-11-25 21:39:20.117964
96	bb64819a-f399-4b0d-9404-684c3c34758c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 21:46:43.35785	2025-11-25 21:46:42.882371	2025-11-25 21:46:42.882371
97	5dea924b-7ccd-49a7-9fe2-220059144a06	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 21:52:35.185834	2025-11-25 21:52:34.691173	2025-11-25 21:52:34.691173
98	57724f32-1297-490b-a22d-66c2ab551f2c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 21:59:42.8241	2025-11-25 21:59:42.302139	2025-11-25 21:59:42.302139
99	49855997-3145-4ed1-8bd2-64eb54808e5e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 22:33:34.191296	2025-11-25 22:33:33.639834	2025-11-25 22:33:33.639834
100	7858fe7a-7a4a-456a-af78-8e8a265fbd94	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 22:33:41.688928	2025-11-25 22:33:41.153782	2025-11-25 22:33:41.153782
101	59d7abd0-ef1e-4fb7-9ebd-30b6d0c4a2a6	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 22:55:15.255051	2025-11-25 22:55:14.679492	2025-11-25 22:55:14.679492
102	a9b6f598-995f-424b-a766-49c6d984b9ab	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 23:04:32.378093	2025-11-25 23:04:31.821277	2025-11-25 23:04:31.821277
103	30afb8de-4119-483f-8e0c-b41a06448a3d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 23:06:26.89113	2025-11-25 23:06:26.373377	2025-11-25 23:06:26.373377
104	2a574dcd-2cee-434f-9552-75e9f67570f8	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 23:09:29.015874	2025-11-25 23:09:28.432674	2025-11-25 23:09:28.432674
105	ab9a6512-fc0b-478e-a467-69d6c08c74b2	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-25 23:10:48.161651	2025-11-25 23:10:47.585239	2025-11-25 23:10:47.585239
106	7502e17e-2335-4e91-9ed3-43607a99c314	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 07:37:15.095649	2025-11-26 07:37:15.071057	2025-11-26 07:37:15.071057
107	bb912307-7a38-45cb-a3ef-307ea953e5de	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 07:45:30.948205	2025-11-26 07:45:30.868409	2025-11-26 07:45:30.868409
108	0c2c6024-f7dd-4d63-9722-0adc4f483956	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 07:49:32.876205	2025-11-26 07:49:32.774263	2025-11-26 07:49:32.774263
109	e6d54af7-b374-41fb-bf75-1250ad486277	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 07:54:29.392304	2025-11-26 07:54:29.319695	2025-11-26 07:54:29.319695
110	0d9a2290-0dbd-448d-b55e-cd7e170e3719	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 07:56:37.549591	2025-11-26 07:56:37.43188	2025-11-26 07:56:37.43188
111	04d14f0b-791d-431a-bab2-d98bbdb25d89	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 07:58:16.969043	2025-11-26 07:58:16.854123	2025-11-26 07:58:16.854123
112	8b5ef048-8c53-4137-aa25-c68f775a9583	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 08:01:11.370084	2025-11-26 08:01:11.269399	2025-11-26 08:01:11.269399
113	bd87d81c-9401-451d-a5f9-31dba29f4608	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 08:31:29.203971	2025-11-26 08:31:29.095157	2025-11-26 08:31:29.095157
114	87994e87-18f1-461f-8fbc-9ab5bd4c3356	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 08:33:37.747346	2025-11-26 08:33:37.598261	2025-11-26 08:33:37.598261
115	8ec2fec1-02b8-4ec4-a001-f165bf59e553	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 08:34:15.11509	2025-11-26 08:34:14.995446	2025-11-26 08:34:14.995446
116	41e6e1ff-74ea-4a0d-91c4-03e4aefc8d65	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 08:40:12.619438	2025-11-26 08:40:12.473357	2025-11-26 08:40:12.473357
117	1498650b-8481-4545-9ab8-e29f19caf08d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 08:42:10.637891	2025-11-26 08:42:10.49893	2025-11-26 08:42:10.49893
119	b6b65dda-cc2a-41d8-9b64-f49ef24f3514	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 09:12:54.934906	2025-11-26 09:12:54.964311	2025-11-26 09:12:54.964311
120	ce4bdcd8-b0c7-4cb5-8069-5f9c4d36f442	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 09:14:30.726773	2025-11-26 09:14:30.543446	2025-11-26 09:14:30.543446
121	3ad91b55-4ea3-42f6-83b2-7fd900083a03	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 09:49:58.228205	2025-11-26 09:49:58.005009	2025-11-26 09:49:58.005009
124	5d0337d2-c9be-44f0-9054-eb46071276d6	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 09:55:48.976975	2025-11-26 09:55:48.770567	2025-11-26 09:55:48.770567
128	bfc46bfb-d53a-44aa-9fce-bca85a32b6b3	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 10:18:00.006837	2025-11-26 10:17:59.796355	2025-11-26 10:17:59.796355
129	2ec7773a-f8cc-4412-80c1-6283c7a994c1	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 10:20:34.724345	2025-11-26 10:20:34.521563	2025-11-26 10:20:34.521563
118	d9ebd50e-481f-4847-87de-6d6b257f0ff5	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 08:54:32.776096	2025-11-26 08:54:32.615509	2025-11-26 08:54:32.615509
122	46c4bb01-6ec4-4b6c-86e5-85494bdb9b3b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 09:50:26.779556	2025-11-26 09:50:26.5866	2025-11-26 09:50:26.5866
123	9a003691-8ccd-4cc8-9504-597c070cc2ee	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 09:55:17.907777	2025-11-26 09:55:17.663782	2025-11-26 09:55:17.663782
125	e5a4a66e-d30a-490c-9842-a5775cda5332	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 10:01:11.430038	2025-11-26 10:01:11.212401	2025-11-26 10:01:11.212401
126	475ef081-1093-44b0-9192-7aa49166ddb4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 10:15:45.329098	2025-11-26 10:15:45.1006	2025-11-26 10:15:45.1006
127	ebe6e58f-bcd9-4437-b38b-284c0643be2c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 10:17:26.210485	2025-11-26 10:17:25.950785	2025-11-26 10:17:25.950785
130	89d836f4-1a44-48f9-a4f0-0309c84de9b3	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 10:39:07.373826	2025-11-26 10:39:07.111645	2025-11-26 10:39:07.111645
131	b4c47205-eca1-4667-9332-b24c30eead51	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 10:54:51.847937	2025-11-26 10:54:51.615992	2025-11-26 10:54:51.615992
132	6f3965bf-7844-47f9-b85a-8d635d63e292	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 10:57:04.154982	2025-11-26 10:57:03.877745	2025-11-26 10:57:03.877745
133	770fe5d6-4953-4c9e-8e78-9cbe4d575517	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 11:01:48.538703	2025-11-26 11:01:48.239702	2025-11-26 11:01:48.239702
134	f7987cb2-f029-4d93-857a-d5106560b4e4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 11:04:42.226135	2025-11-26 11:04:41.930408	2025-11-26 11:04:41.930408
135	2e144eec-51f7-47f2-a4eb-cc2d7280ebac	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 11:10:43.694737	2025-11-26 11:10:43.396671	2025-11-26 11:10:43.396671
136	0f2a6a6f-f7c2-4fc0-ac67-b9b8c754999e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 11:13:07.178014	2025-11-26 11:13:06.87064	2025-11-26 11:13:06.87064
137	bf44eb15-d488-4108-8aa4-70679926e786	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 11:30:12.627627	2025-11-26 11:30:12.318306	2025-11-26 11:30:12.318306
138	fcfc7d70-de95-4515-bb91-b70f4c2dc942	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 11:30:30.377454	2025-11-26 11:30:30.047432	2025-11-26 11:30:30.047432
139	db018109-e244-4220-b335-b47c494093ea	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 11:39:40.511148	2025-11-26 11:39:40.176858	2025-11-26 11:39:40.176858
140	1f8a331a-4b5f-4746-8ba1-0b6722f59b52	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 11:49:53.876705	2025-11-26 11:49:53.538408	2025-11-26 11:49:53.538408
141	f2b74f9a-5734-4899-81e5-a77021127e73	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 11:54:50.517873	2025-11-26 11:54:50.351237	2025-11-26 11:54:50.351237
142	00120942-70b2-4450-978d-d3caec3e0cbe	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 12:02:03.915081	2025-11-26 12:02:03.556492	2025-11-26 12:02:03.556492
143	244edff2-0ff8-48ca-bd50-8184fb9d3722	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 12:16:45.828892	2025-11-26 12:16:45.458784	2025-11-26 12:16:45.458784
144	a19d202f-3f72-4484-b663-71b26d1dc9bd	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 12:31:33.266459	2025-11-26 12:31:32.895131	2025-11-26 12:31:32.895131
145	502f31ab-ed28-4a6b-ae4c-fb1a51466f4d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 12:42:00.911159	2025-11-26 12:42:00.547747	2025-11-26 12:42:00.547747
146	e1ac652f-afcd-4fa8-8488-31616c96909f	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 12:57:36.187309	2025-11-26 12:57:35.805418	2025-11-26 12:57:35.805418
147	5eae4864-3a51-4fb7-8274-fc81d38e1b9c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 13:01:28.766734	2025-11-26 13:01:28.386295	2025-11-26 13:01:28.386295
148	d46033cb-692d-4f74-86e2-c0c509cb88ad	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 13:06:41.047895	2025-11-26 13:06:40.655318	2025-11-26 13:06:40.655318
149	d427ec2c-7e50-4470-b0c1-dc10ddbe86a0	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 13:10:48.223229	2025-11-26 13:10:47.818751	2025-11-26 13:10:47.818751
150	bc1ba10e-c7a7-4f55-9953-dd9c95d623ad	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 13:23:21.671317	2025-11-26 13:23:21.259483	2025-11-26 13:23:21.259483
151	be54e5e4-cf36-49f4-8f83-017a38b52ba9	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 13:44:55.581652	2025-11-26 13:44:55.124417	2025-11-26 13:44:55.124417
152	062f4fc6-8e4b-4c9c-8785-384d30341478	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 13:55:21.543313	2025-11-26 13:55:21.081803	2025-11-26 13:55:21.081803
153	614919ad-e0ac-4975-a003-0a03e4383e60	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 14:29:57.498333	2025-11-26 14:29:57.095978	2025-11-26 14:29:57.095978
154	c9610919-0038-46e3-a3b7-56ae743e5269	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 14:33:39.345993	2025-11-26 14:33:38.845379	2025-11-26 14:33:38.845379
155	62008831-b970-4c31-80df-e56d40f3bd64	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 14:38:20.079653	2025-11-26 14:38:19.580705	2025-11-26 14:38:19.580705
156	bf85c053-a9d2-43b2-9493-129a7c2db1f1	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 14:41:57.690784	2025-11-26 14:41:57.194204	2025-11-26 14:41:57.194204
157	fb542994-3560-46d7-b5a5-935f529b9f7e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 14:42:22.739886	2025-11-26 14:42:22.273116	2025-11-26 14:42:22.273116
158	7ef0891a-e29a-4a92-96fa-fcc1af688fc3	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 15:10:07.643534	2025-11-26 15:10:07.161133	2025-11-26 15:10:07.161133
159	8db261e8-d475-4fb5-9633-5f2e857e76f8	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 15:14:37.710162	2025-11-26 15:14:37.187638	2025-11-26 15:14:37.187638
160	8ddfc1dd-f96c-4491-8253-cbea813bd06d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 15:17:39.149445	2025-11-26 15:17:38.625383	2025-11-26 15:17:38.625383
161	e1f44f0a-fe45-4f38-9cf5-5d56185d0fc1	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 15:22:01.319742	2025-11-26 15:22:00.779837	2025-11-26 15:22:00.779837
162	f938feab-8153-4f2b-8056-f6b73a5401ec	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 15:30:10.054841	2025-11-26 15:30:09.580869	2025-11-26 15:30:09.580869
163	ed419092-4767-475e-b995-884b4c7c7be1	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 15:39:17.828027	2025-11-26 15:39:17.315721	2025-11-26 15:39:17.315721
164	063e6cfc-e056-4abc-b278-fcae6c8c1134	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 15:45:44.560126	2025-11-26 15:45:44.016702	2025-11-26 15:45:44.016702
165	a9845882-08fb-45b5-b0e9-314bfe7cdffa	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 15:55:39.41592	2025-11-26 15:55:38.876946	2025-11-26 15:55:38.876946
166	a323486d-23a4-4cf7-8325-ed0cacc9065d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-26 16:04:21.208174	2025-11-26 16:04:20.691861	2025-11-26 16:04:20.691861
167	d55035eb-13d4-43e9-85af-f67acea4fcbb	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 00:00:29.769739	2025-11-27 00:00:30.348439	2025-11-27 00:00:30.348439
168	bafabfd8-9ff1-4ca3-955c-a62908b1dee4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 00:45:05.646605	2025-11-27 00:45:06.032394	2025-11-27 00:45:06.032394
169	b3dfa46a-8555-49fd-85f2-f8c2d5688bed	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 00:46:54.054436	2025-11-27 00:46:54.494749	2025-11-27 00:46:54.494749
170	1a9f4618-8c84-492b-8b25-fdaf619de85e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 01:21:52.595104	2025-11-27 01:21:53.001672	2025-11-27 01:21:53.001672
171	3f3b68f5-4af3-4c06-983e-cfbc80d6dd59	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 02:07:34.50523	2025-11-27 02:07:34.487416	2025-11-27 02:07:34.487416
172	6f5ba5ac-c27e-4e2f-b7fa-e9f1e1bfedf4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 02:17:55.978139	2025-11-27 02:17:55.933106	2025-11-27 02:17:55.933106
173	c3f4072e-1297-48ad-80eb-e8fe03622777	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 02:18:27.264369	2025-11-27 02:18:27.174802	2025-11-27 02:18:27.174802
174	74dd71d6-f0b7-4537-8f15-b53faf1defe0	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 02:19:59.400444	2025-11-27 02:19:59.336759	2025-11-27 02:19:59.336759
175	959e9130-badd-4b66-9133-00c2d892747c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 02:36:27.945032	2025-11-27 02:36:27.866873	2025-11-27 02:36:27.866873
176	b617f12e-6306-4fba-b74a-68b4a9189f5b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 02:39:35.02806	2025-11-27 02:39:34.975853	2025-11-27 02:39:34.975853
177	7d5b1a95-64b0-48de-a1c5-41500845322b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 14:08:56.883476	2025-11-27 14:08:55.425986	2025-11-27 14:08:55.425986
178	f2746aac-d94c-47fb-96f8-465ecf836d5c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 14:36:53.684688	2025-11-27 14:36:51.872288	2025-11-27 14:36:51.872288
179	392ce8e8-e427-41a7-9ca8-346ea7de210a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 14:47:43.215913	2025-11-27 14:47:41.323391	2025-11-27 14:47:41.323391
180	91e678d6-b309-4bf7-9d2f-159317f438aa	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 14:50:20.659289	2025-11-27 14:50:18.852786	2025-11-27 14:50:18.852786
181	36569c72-87f1-4da3-b47b-c8d593933abc	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 15:23:15.454386	2025-11-27 15:23:13.653492	2025-11-27 15:23:13.653492
182	4f800466-cd15-408b-a788-e69a7a539c9e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 17:44:07.457772	2025-11-27 17:44:05.531882	2025-11-27 17:44:05.531882
183	4fba6c30-55fc-4a1f-83c2-a50459de1091	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 18:06:04.387751	2025-11-27 18:06:02.369962	2025-11-27 18:06:02.369962
184	652b45ee-b5d3-40e4-ada8-91a1e73d33b7	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 18:24:21.564478	2025-11-27 18:24:19.483121	2025-11-27 18:24:19.483121
185	177b607c-e5b5-4692-8e8c-cae0a6101e29	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 18:32:26.333893	2025-11-27 18:32:24.249762	2025-11-27 18:32:24.249762
186	56072b7e-2bc2-45f5-a6c7-b805dfe4a76b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 18:42:44.264391	2025-11-27 18:42:42.164072	2025-11-27 18:42:42.164072
187	3bbde59d-7d47-4af5-a85d-ab7f033da174	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 18:51:58.026112	2025-11-27 18:51:55.930598	2025-11-27 18:51:55.930598
188	dc4da1e3-f540-4570-92dc-0558dbfce11d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 18:59:38.459114	2025-11-27 18:59:36.522641	2025-11-27 18:59:36.522641
189	e5c74c10-1c6d-4925-bfec-9e31700397ee	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 19:04:33.582534	2025-11-27 19:04:31.486823	2025-11-27 19:04:31.486823
190	cb6c2af0-404c-4145-8dc4-bd49a0739bd8	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 19:11:27.361366	2025-11-27 19:11:25.292711	2025-11-27 19:11:25.292711
191	48c94a3e-c095-4b4b-ab8f-d1649ede9277	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 19:13:16.747004	2025-11-27 19:13:14.678538	2025-11-27 19:13:14.678538
192	3715800a-bec7-4495-8e81-cf77ff436dd9	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 19:14:31.589894	2025-11-27 19:14:29.495553	2025-11-27 19:14:29.495553
193	2cd6fe3f-bb8d-4cdf-8049-9de5a79893e9	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-27 19:22:56.229832	2025-11-27 19:22:54.095741	2025-11-27 19:22:54.095741
194	25bd0337-c47a-4bcb-a5ee-cba0f893be92	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 09:52:25.215858	2025-11-28 09:52:25.370349	2025-11-28 09:52:25.370349
195	16fb470f-b6dc-46cb-ad51-39bc54af3647	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 13:59:18.113046	2025-11-28 13:59:17.980537	2025-11-28 13:59:17.980537
196	4885246e-8a77-477c-b3c2-d746d0bdd5a1	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 15:23:34.294233	2025-11-28 15:23:34.077027	2025-11-28 15:23:34.077027
197	73c88573-13aa-4803-9811-3d6194c19740	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 15:40:07.429271	2025-11-28 15:40:07.121886	2025-11-28 15:40:07.121886
198	be4cd520-1bb2-4e4a-9f89-fdc8532d8b54	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 15:43:05.724475	2025-11-28 15:43:05.47846	2025-11-28 15:43:05.47846
199	d0117969-d793-4f5e-b48a-3a9071c06508	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 17:18:20.919613	2025-11-28 17:18:20.318293	2025-11-28 17:18:20.318293
200	1cd30ebb-9edb-4089-a978-1f65bd83ce1d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 17:28:21.142916	2025-11-28 17:28:20.521053	2025-11-28 17:28:20.521053
201	aff5c1f5-9989-4b23-a160-16f7210831ab	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 17:40:51.043927	2025-11-28 17:40:51.44617	2025-11-28 17:40:51.44617
202	51263206-be64-4f17-970e-5cdfce89d86b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 17:42:59.373065	2025-11-28 17:42:58.748021	2025-11-28 17:42:58.748021
203	440e8f07-68e7-4dda-96e2-81de5e7e79ad	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 17:48:11.845828	2025-11-28 17:48:11.209579	2025-11-28 17:48:11.209579
204	63b54bd6-e01e-43e6-877f-ab2910e4140d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 17:58:47.990795	2025-11-28 17:58:47.348392	2025-11-28 17:58:47.348392
205	70d22a30-7156-47d5-9e22-4956bc13be53	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 18:01:57.143518	2025-11-28 18:01:56.481246	2025-11-28 18:01:56.481246
206	61f453ec-4fa9-4881-ac3f-95f24edb5ee3	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 18:07:05.745889	2025-11-28 18:07:05.191114	2025-11-28 18:07:05.191114
207	5836b832-3bd5-4a7d-9980-6afc632ae26e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 18:12:53.765058	2025-11-28 18:12:53.123253	2025-11-28 18:12:53.123253
208	6460f12b-5884-4b8f-8753-b4787c9091ca	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 18:15:43.792072	2025-11-28 18:15:43.133977	2025-11-28 18:15:43.133977
209	5a7d321d-3ad7-4ea2-a9c3-fabc3802b82b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 18:17:31.082831	2025-11-28 18:17:30.412516	2025-11-28 18:17:30.412516
210	6a057f0f-77d8-485d-b508-ce563c891fa4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 18:26:39.868125	2025-11-28 18:26:39.204799	2025-11-28 18:26:39.204799
211	b4a6b133-69ad-477e-b61b-1075c0fee6a7	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 18:32:53.64077	2025-11-28 18:32:52.974065	2025-11-28 18:32:52.974065
212	6e1a9e34-c2b8-4f3a-a0be-713869ca0e42	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-28 18:37:53.740515	2025-11-28 18:37:53.040167	2025-11-28 18:37:53.040167
213	fb06a8f6-aa80-4bb7-b039-8560bc29e400	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 08:53:59.416982	2025-11-29 08:53:58.834432	2025-11-29 08:53:58.834432
214	cb5c3b8a-b367-4735-8cdd-f17bd635bf9f	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 08:57:37.340106	2025-11-29 08:57:36.700894	2025-11-29 08:57:36.700894
215	699bbf42-c579-4886-aef9-c1eb6766e06b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:10:11.95433	2025-11-29 09:10:11.226617	2025-11-29 09:10:11.226617
216	654b7304-7c67-4b14-9d5c-64bb78077b87	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:11:30.826878	2025-11-29 09:11:30.064862	2025-11-29 09:11:30.064862
217	1b2b3161-8853-4c35-bf6b-84648d6399e2	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:12:49.468841	2025-11-29 09:12:48.722847	2025-11-29 09:12:48.722847
218	79ac4763-dc1b-4d21-b492-90b2744bc245	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:14:21.159003	2025-11-29 09:14:20.403151	2025-11-29 09:14:20.403151
219	fadb4a73-a7f5-4647-8508-1aa4163fa9e5	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:21:46.865543	2025-11-29 09:21:46.090989	2025-11-29 09:21:46.090989
220	73568955-5389-4102-b177-c7840a7752b4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:24:59.058004	2025-11-29 09:24:58.311838	2025-11-29 09:24:58.311838
221	bbefdf2e-a305-4bc7-8661-0a54b75b5f93	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:27:43.252186	2025-11-29 09:27:42.472223	2025-11-29 09:27:42.472223
222	5c219bbc-0909-4038-85ea-59153dcfed70	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:28:26.277018	2025-11-29 09:28:25.503675	2025-11-29 09:28:25.503675
223	c6e948f0-2dbb-4419-a0af-3bf40ce06854	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:31:40.642996	2025-11-29 09:31:39.840782	2025-11-29 09:31:39.840782
224	7c6df9e7-7668-4adc-98a5-f0e739674ecd	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:35:04.560678	2025-11-29 09:35:03.757694	2025-11-29 09:35:03.757694
225	f84ac773-a2ba-4d8f-8331-93291131dc59	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:35:21.794084	2025-11-29 09:35:20.989828	2025-11-29 09:35:20.989828
226	c9d3ddc0-6227-43dd-807a-34c6007709d4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:37:16.684066	2025-11-29 09:37:15.949584	2025-11-29 09:37:15.949584
227	3c5a7d8b-334f-45dd-a698-27da7762d9ab	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 09:38:51.567162	2025-11-29 09:38:50.795171	2025-11-29 09:38:50.795171
228	dfee0210-917e-42bd-af7d-7a648fa7c5a4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 10:13:44.148784	2025-11-29 10:13:43.377413	2025-11-29 10:13:43.377413
229	206a8e79-f4b3-4dfb-be96-c28bfd2f819a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 11:22:42.528606	2025-11-29 11:22:42.015411	2025-11-29 11:22:42.015411
230	f8d0d406-9746-4439-ba0a-fb6f09c669df	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 13:45:29.290999	2025-11-29 13:45:28.715264	2025-11-29 13:45:28.715264
231	81b128d9-3c37-412b-a347-de41880420f5	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 14:27:24.927626	2025-11-29 14:27:24.23223	2025-11-29 14:27:24.23223
232	bcc96b46-9718-4b7a-bf7b-a5ba1c28e1fc	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 14:43:24.131127	2025-11-29 14:43:23.392305	2025-11-29 14:43:23.392305
233	a4012314-0a83-47e7-b943-6925f42b981d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 15:21:41.151772	2025-11-29 15:21:40.408634	2025-11-29 15:21:40.408634
234	99cf346b-9ebb-4d95-958f-25320743d0c3	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 19:28:52.642281	2025-11-29 19:28:52.724198	2025-11-29 19:28:52.724198
235	c33b21f5-ca8c-4350-8d47-1a2a682f0115	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 20:13:28.900462	2025-11-29 20:13:28.92192	2025-11-29 20:13:28.92192
236	470157d7-fb1d-406a-ae08-c903cc1e4752	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 20:40:20.012521	2025-11-29 20:40:20.044289	2025-11-29 20:40:20.044289
237	6f0feed6-9022-4626-92d5-df075d865578	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 20:51:01.456797	2025-11-29 20:51:01.467261	2025-11-29 20:51:01.467261
238	e88f5ff3-bd8f-4bd1-9bb7-86bb780f69ad	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 20:56:29.457805	2025-11-29 20:56:29.537924	2025-11-29 20:56:29.537924
239	656e419b-4459-49fd-a6eb-7e5aeba5639e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-29 23:01:28.54327	2025-11-29 23:01:28.466811	2025-11-29 23:01:28.466811
240	dab10606-b948-4430-bf83-ecccf86d71a2	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 09:50:40.579698	2025-11-30 09:50:39.80814	2025-11-30 09:50:39.80814
241	6319f4e6-1479-4f39-ab93-be0e1f4b215b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 09:58:25.422895	2025-11-30 09:58:24.652352	2025-11-30 09:58:24.652352
242	79ad5560-e9c5-4e93-9aaa-f5638db2e3b5	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 10:25:51.943797	2025-11-30 10:25:53.547967	2025-11-30 10:25:53.547967
243	b9d46cfd-f9e4-4422-b5a5-bbfa313d15af	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 10:55:00.669489	2025-11-30 10:54:59.868696	2025-11-30 10:54:59.868696
244	68dc9e7f-621d-4b31-9c38-72b220059c76	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 12:07:13.252724	2025-11-30 12:07:12.402117	2025-11-30 12:07:12.402117
245	2e72b905-909c-4e32-8576-3feb44e72f08	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 12:23:37.233605	2025-11-30 12:23:36.332375	2025-11-30 12:23:36.332375
246	dfd3c599-7119-4026-94f1-13f7cf33ba5a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 12:28:40.320591	2025-11-30 12:28:39.406504	2025-11-30 12:28:39.406504
247	79203eb8-fb4c-45e8-a6f4-e8ed9bfb6f73	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 12:57:48.00354	2025-11-30 12:57:47.070479	2025-11-30 12:57:47.070479
248	527a7b52-bb05-4fde-8eaa-9ba5441c318b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 14:49:17.941208	2025-11-30 14:49:16.916891	2025-11-30 14:49:16.916891
249	345f788b-7a21-4671-8687-fb14d14aaf6e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 15:19:04.165289	2025-11-30 15:19:03.101022	2025-11-30 15:19:03.101022
250	3ffaab3b-d95e-4be6-a829-d58a4cfec6e5	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 17:24:27.529789	2025-11-30 17:24:26.343445	2025-11-30 17:24:26.343445
251	ac5b0432-dd7c-438f-a6c4-840bcdd1712b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 17:51:14.062187	2025-11-30 17:51:12.850378	2025-11-30 17:51:12.850378
252	6f957d23-2864-4eb8-8629-b12eda3f377a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 19:05:15.199654	2025-11-30 19:05:14.080188	2025-11-30 19:05:14.080188
253	74f1349a-f457-455f-88c2-3bb990758f54	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 22:05:43.135071	2025-11-30 22:05:41.683666	2025-11-30 22:05:41.683666
254	ef7eaa0f-2365-4231-884e-2988c2061fa2	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-11-30 22:23:48.255433	2025-11-30 22:23:46.791498	2025-11-30 22:23:46.791498
255	776759a3-2f7d-4f6b-aa25-3719fba9addd	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 08:31:52.061535	2025-12-01 08:31:51.911574	2025-12-01 08:31:51.911574
256	b09f0088-87d2-48eb-aebf-7a021cf85812	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 08:51:28.791232	2025-12-01 08:51:28.410254	2025-12-01 08:51:28.410254
257	9439701c-1ece-4c41-b69e-e412001454bf	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 09:13:01.247669	2025-12-01 09:13:00.864382	2025-12-01 09:13:00.864382
258	b9183d55-e558-4955-a516-654996ee4c5a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 09:54:48.486428	2025-12-01 09:54:48.026551	2025-12-01 09:54:48.026551
259	ed34f302-847c-49f9-b825-2e25a1d6e863	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 10:18:47.325491	2025-12-01 10:18:46.956002	2025-12-01 10:18:46.956002
260	cc50c1d2-d39a-49ff-b729-1a7f1fbf0f6f	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 10:25:18.823133	2025-12-01 10:25:18.546733	2025-12-01 10:25:18.546733
261	d65ad14d-df17-45d4-b31d-601add7c4cd8	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 10:34:03.352799	2025-12-01 10:34:03.014012	2025-12-01 10:34:03.014012
262	68decb70-4b3b-40f4-bdc5-b5210d6c18a0	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 10:59:00.010724	2025-12-01 10:58:59.672557	2025-12-01 10:58:59.672557
263	3d944ce3-77cd-4da4-a846-09eabac72f7a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 11:45:39.575586	2025-12-01 11:45:39.152933	2025-12-01 11:45:39.152933
264	10554e53-f89e-4493-9598-ccf65d6099f1	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 11:55:48.40439	2025-12-01 11:55:47.986539	2025-12-01 11:55:47.986539
265	dbc8324e-f4aa-49f0-b94a-68fd845e4a4d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 11:58:36.256678	2025-12-01 11:58:35.831599	2025-12-01 11:58:35.831599
266	f9750e95-b730-48aa-998e-a327b0ae6859	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 12:11:31.134005	2025-12-01 12:11:30.854375	2025-12-01 12:11:30.854375
267	469f7e40-f9c8-4ee9-b4bc-b97b73db6e3e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 12:39:01.905188	2025-12-01 12:39:01.433137	2025-12-01 12:39:01.433137
268	fcaa5951-d85c-4269-bedc-ea259f4f2dae	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 14:15:38.946177	2025-12-01 14:15:38.378199	2025-12-01 14:15:38.378199
269	08fc1bb1-b004-42ae-9980-e1aff600abba	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 14:43:34.470232	2025-12-01 14:43:33.921739	2025-12-01 14:43:33.921739
270	5184dc40-7987-4af1-b07f-d9faecd025ed	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 17:35:08.041069	2025-12-01 17:35:07.290688	2025-12-01 17:35:07.290688
271	925dc8de-3d20-4055-b411-ba574095467b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 19:19:32.925753	2025-12-01 19:19:32.25607	2025-12-01 19:19:32.25607
272	35472504-720d-4b9c-97fb-8020a8ace739	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 19:55:57.800589	2025-12-01 19:55:56.96991	2025-12-01 19:55:56.96991
273	8bc861c4-afe7-4d60-92fb-d5063e8972a3	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-01 22:00:04.762188	2025-12-01 22:00:03.762829	2025-12-01 22:00:03.762829
274	cdae0f9d-f59a-4ddb-936e-1e69948ee11c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 09:03:42.850824	2025-12-02 09:03:49.139844	2025-12-02 09:03:49.139844
275	c725fdc1-2978-4f6e-8ea2-7b5a35236db0	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 10:37:33.959905	2025-12-02 10:37:31.99394	2025-12-02 10:37:31.99394
276	cdcca08b-8630-41cf-9224-ee80ba1489b0	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 12:25:50.982332	2025-12-02 12:25:48.785708	2025-12-02 12:25:48.785708
277	eeccb9a3-3318-425a-a965-c6bffa685610	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 15:40:51.992996	2025-12-02 15:40:49.659054	2025-12-02 15:40:49.659054
278	69bda33d-3363-4c5a-993f-3a5b1df52169	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 16:05:12.749678	2025-12-02 16:05:10.329685	2025-12-02 16:05:10.329685
279	cb937c06-2ded-43b9-aef2-99838e67308f	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 17:00:29.850363	2025-12-02 17:00:27.324353	2025-12-02 17:00:27.324353
280	6c8f2f62-69da-4d8d-91bd-d5ab6ef7961f	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 21:02:50.354165	2025-12-02 21:02:47.588861	2025-12-02 21:02:47.588861
281	b622310c-940d-4f14-b656-3bccd0b6b2fb	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 21:20:54.721993	2025-12-02 21:20:51.948743	2025-12-02 21:20:51.948743
282	e2971fde-96e4-4e4d-aa18-a01e1a30139a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 22:16:21.097377	2025-12-02 22:16:18.242653	2025-12-02 22:16:18.242653
283	38ecb94a-acb0-41c8-ac16-6cf2d880654a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 22:58:16.480552	2025-12-02 22:58:16.075186	2025-12-02 22:58:16.075186
284	2455d7b2-02ad-42fb-b675-fc85d2abb5a4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-02 23:11:39.395947	2025-12-02 23:11:38.968868	2025-12-02 23:11:38.968868
285	faa87f37-9324-4163-9036-9ce8da64a856	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 08:37:25.533352	2025-12-03 08:37:24.683682	2025-12-03 08:37:24.683682
286	e943af31-7276-4f91-9af1-004f2de604f0	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 08:49:28.343814	2025-12-03 08:49:27.391393	2025-12-03 08:49:27.391393
287	5d1ae1d7-8608-4f8d-9c34-0a3f908cf928	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 09:09:12.722992	2025-12-03 09:09:11.741517	2025-12-03 09:09:11.741517
288	7002e929-3787-46ca-9d6f-1d1c4bac67ba	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 10:12:59.82771	2025-12-03 10:12:58.799623	2025-12-03 10:12:58.799623
289	f07b7f81-79df-406b-9e04-b5825eb8bf7c	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 12:19:49.091761	2025-12-03 12:19:47.967609	2025-12-03 12:19:47.967609
290	d3d594f9-5ee0-426c-b619-a789c062681b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 13:42:31.572326	2025-12-03 13:42:30.341992	2025-12-03 13:42:30.341992
291	2da8faa6-9fd0-45c6-8dad-999cace9fc79	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 15:16:27.842001	2025-12-03 15:16:26.4754	2025-12-03 15:16:26.4754
292	913305fa-2e30-4395-842c-b508723973d8	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 15:31:38.353887	2025-12-03 15:31:37.056813	2025-12-03 15:31:37.056813
293	374ebd01-d8c3-49f3-aee4-e22a43f9f480	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 19:39:19.05726	2025-12-03 19:39:17.509724	2025-12-03 19:39:17.509724
294	42024b2a-aa92-4cc2-a9e4-6b4e641f4b8a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 22:16:45.363304	2025-12-03 22:16:45.435046	2025-12-03 22:16:45.435046
295	8c8f9e5d-c7ea-4e53-ae96-45efa0961dd3	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-03 23:06:08.064464	2025-12-03 23:06:08.127371	2025-12-03 23:06:08.127371
296	f325c6e0-1e48-4c38-9df4-3c3877682c1f	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 11:16:29.113634	2025-12-04 11:16:28.889722	2025-12-04 11:16:28.889722
297	b81701b2-3d53-4957-9a4c-583171402c64	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 12:46:07.946738	2025-12-04 12:46:07.664461	2025-12-04 12:46:07.664461
298	7410cf1f-ad09-48bd-89e1-a83b57c05e28	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 12:51:58.826266	2025-12-04 12:51:58.48097	2025-12-04 12:51:58.48097
299	83ecd64b-1d36-4aed-9c98-252c71f5dfeb	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 13:15:55.829862	2025-12-04 13:15:55.419152	2025-12-04 13:15:55.419152
300	8832bb4c-9de2-49cc-9015-34221a9b7c65	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 13:24:55.236931	2025-12-04 13:24:54.815415	2025-12-04 13:24:54.815415
301	a1373da2-99f5-4df6-9f60-1af0509f17f7	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 13:32:59.035311	2025-12-04 13:32:58.713211	2025-12-04 13:32:58.713211
302	5ddbfc04-17ca-44cc-b307-a02dbb33c7b4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 14:41:36.543463	2025-12-04 14:41:36.213119	2025-12-04 14:41:36.213119
303	f230087d-36bf-41b6-b550-4e93bf2923a6	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 16:38:49.701394	2025-12-04 16:38:49.273971	2025-12-04 16:38:49.273971
304	b4468de0-0d6d-4779-826d-d703e34ee43e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 16:59:40.004579	2025-12-04 16:59:39.501686	2025-12-04 16:59:39.501686
305	bcdd9a16-f030-41af-ab6b-019ca426388e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 17:16:01.788904	2025-12-04 17:16:01.134209	2025-12-04 17:16:01.134209
306	0ad84cb5-4bb1-40cb-ab0f-63f1aa3957f9	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 17:21:08.01556	2025-12-04 17:21:07.402413	2025-12-04 17:21:07.402413
307	76217ceb-03ba-4f6a-a979-85d876d3f88a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 17:33:15.919195	2025-12-04 17:33:15.305145	2025-12-04 17:33:15.305145
308	237e719f-a662-45a6-9bcf-7e2baea8cfc0	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 18:21:41.000511	2025-12-04 18:21:40.352408	2025-12-04 18:21:40.352408
309	167a155c-e930-4b95-b931-a0595ac7c07d	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 18:27:35.52733	2025-12-04 18:27:34.800294	2025-12-04 18:27:34.800294
310	958ac859-ab38-4997-8446-0d4259c2102a	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 18:50:57.994508	2025-12-04 18:50:57.243978	2025-12-04 18:50:57.243978
311	2b1f8f02-f525-4d33-bf39-4eb7761ccd03	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 18:56:21.556191	2025-12-04 18:56:20.898106	2025-12-04 18:56:20.898106
312	5c220540-66db-4bfb-800d-2ac20ad723d3	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 18:57:37.177164	2025-12-04 18:57:36.426491	2025-12-04 18:57:36.426491
313	f2e83d0a-e2f5-4e5e-8510-b132aeec3a53	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 19:05:02.374569	2025-12-04 19:05:01.616941	2025-12-04 19:05:01.616941
314	adc6d4a3-26eb-4d48-8f96-6c8e6bf3ae5e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 19:16:19.616299	2025-12-04 19:16:18.939976	2025-12-04 19:16:18.939976
315	60a4d77b-bd28-4aa2-a54a-4374c501cdfa	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 19:28:02.287611	2025-12-04 19:28:01.541074	2025-12-04 19:28:01.541074
316	7598f138-cc31-43c5-9058-8f6a82d46586	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 19:42:35.893048	2025-12-04 19:42:35.167701	2025-12-04 19:42:35.167701
317	481582ce-38d8-4b1f-9120-f84b849251dc	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 20:03:17.911434	2025-12-04 20:03:17.161395	2025-12-04 20:03:17.161395
318	8c6fd7b1-4f9b-4967-b2b3-4b1bac690822	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 20:17:33.166036	2025-12-04 20:17:32.335887	2025-12-04 20:17:32.335887
319	33e3804b-d95a-45c8-98dd-9f2ecf020057	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 20:43:13.138225	2025-12-04 20:43:12.486552	2025-12-04 20:43:12.486552
320	d458dddd-c235-4ed4-882f-fb3dea8bb8b8	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 20:54:40.948909	2025-12-04 20:54:40.255802	2025-12-04 20:54:40.255802
321	e5d2e42c-30a9-4497-afaf-137fb5f750cf	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 21:30:19.213501	2025-12-04 21:30:18.606972	2025-12-04 21:30:18.606972
322	2c17ac8c-92bf-4d0a-9c29-1cd32df8c308	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 21:43:28.715681	2025-12-04 21:43:28.408234	2025-12-04 21:43:28.408234
323	829000f0-fd32-4ec1-beef-93c663c63702	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 22:04:26.543494	2025-12-04 22:04:25.61335	2025-12-04 22:04:25.61335
324	8a429b13-d610-436e-8309-d27e5b66bb2b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 22:11:06.068374	2025-12-04 22:11:05.194694	2025-12-04 22:11:05.194694
325	1daff54f-310e-402f-8a66-3e7b985b4fa1	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 22:21:51.194261	2025-12-04 22:21:50.452514	2025-12-04 22:21:50.452514
326	32be8630-d1df-48bd-91e7-9f1048411474	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 22:31:17.172265	2025-12-04 22:31:16.237968	2025-12-04 22:31:16.237968
327	f5341170-3048-4716-b659-97d395ab6dba	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 22:40:36.818547	2025-12-04 22:40:35.84879	2025-12-04 22:40:35.84879
328	7c864beb-4040-4315-875c-021bfdbb77b5	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-04 23:06:34.33029	2025-12-04 23:06:33.327954	2025-12-04 23:06:33.327954
329	b5b0a659-ebb5-4ecf-aad9-49bda0d33de5	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 09:30:51.425229	2025-12-05 09:30:51.215986	2025-12-05 09:30:51.215986
330	66edfa43-70b0-4ae6-bf4e-5a1cb3a94b0e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 09:43:40.583495	2025-12-05 09:43:40.191317	2025-12-05 09:43:40.191317
331	37b3667f-f6f5-41c9-bc53-cf0610cae09f	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 10:38:30.40374	2025-12-05 10:38:29.885172	2025-12-05 10:38:29.885172
332	be762392-5f12-4c67-9f90-c2566b3e31ec	192.168.1.6	android	{"os": "android", "is_web": false, "locale": "en_US", "is_debug": true, "os_version": "BP22.250325.006", "number_of_processors": 4}	2025-12-05 04:54:01.667499	2025-12-05 12:54:02.741374	2025-12-05 12:54:02.741374
333	9b0b0beb-42ac-4757-8689-1962ef8e55f8	192.168.1.6	android	{"os": "android", "is_web": false, "locale": "en_US", "is_debug": true, "os_version": "BP22.250325.006", "number_of_processors": 4}	2025-12-05 04:59:35.592824	2025-12-05 12:59:36.79904	2025-12-05 12:59:36.79904
334	f1422e2c-7521-4c4e-be4e-0c0302319635	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 16:45:45.484193	2025-12-05 16:45:44.74305	2025-12-05 16:45:44.74305
335	fcf99bbe-4b63-431b-aff1-b7e91acf40b0	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 17:09:16.730884	2025-12-05 17:09:15.941377	2025-12-05 17:09:15.941377
336	29ce7dbd-fc3d-40f8-852b-16dbead2aa20	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 17:36:56.047072	2025-12-05 17:36:55.138104	2025-12-05 17:36:55.138104
337	e9946799-b60a-45fe-80ce-5a32c5182bd3	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 17:46:15.943064	2025-12-05 17:46:15.074097	2025-12-05 17:46:15.074097
338	0d80eb6f-1351-491d-adaf-66377befbbfc	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 17:53:35.916329	2025-12-05 17:53:34.97369	2025-12-05 17:53:34.97369
339	c3bc9a48-ba08-4ed9-8ec3-5022aafe2cd8	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 18:04:00.364495	2025-12-05 18:03:59.439634	2025-12-05 18:03:59.439634
340	8e37d1be-6e10-4518-a61d-6a255b370013	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 18:08:18.242574	2025-12-05 18:08:17.282446	2025-12-05 18:08:17.282446
341	2ec46f47-9492-493d-8308-87b95b6278b6	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 18:21:24.668476	2025-12-05 18:21:23.696916	2025-12-05 18:21:23.696916
342	f679231a-4f2b-4370-9482-bf7389517a18	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 18:32:08.237929	2025-12-05 18:32:07.280832	2025-12-05 18:32:07.280832
343	f3a6ec62-90e2-4d6b-8e9c-ccea2bb4af3f	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 18:37:47.933024	2025-12-05 18:37:47.145123	2025-12-05 18:37:47.145123
344	06b940d3-fd1d-45de-b250-538d2f6871ec	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 18:49:46.481261	2025-12-05 18:49:45.511664	2025-12-05 18:49:45.511664
345	ff1a80b0-69c0-41d1-bb8f-964d3366f283	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 19:04:07.360958	2025-12-05 19:04:06.371478	2025-12-05 19:04:06.371478
346	e19a3409-0f01-4bfe-8a01-dc365ff05ab4	192.168.1.6	android	{"os": "android", "is_web": false, "locale": "en_US", "is_debug": true, "os_version": "BP22.250325.006", "number_of_processors": 4}	2025-12-05 12:51:59.61357	2025-12-05 20:52:06.718911	2025-12-05 20:52:06.718911
347	916bf41b-7fbb-472b-a7bf-3d11701429a3	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 22:04:02.913708	2025-12-05 22:04:01.831482	2025-12-05 22:04:01.831482
348	c8080d64-ef09-4fd8-9edf-e5bafe126d5f	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-05 23:58:59.357239	2025-12-05 23:58:58.282895	2025-12-05 23:58:58.282895
349	ff9b23f0-f061-4f97-93ef-38f1338f899b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-06 00:16:47.304128	2025-12-06 00:16:45.989656	2025-12-06 00:16:45.989656
350	091ccbf2-a6d2-4c7e-85bc-b173753210c7	192.168.1.6	android	{"os": "android", "is_web": false, "locale": "en_US", "is_debug": true, "os_version": "BP22.250325.006", "number_of_processors": 4}	2025-12-05 17:28:13.319174	2025-12-06 01:28:21.2012	2025-12-06 01:28:21.2012
351	1857e774-18d8-4b4c-b42e-d0a483407e65	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-06 14:47:46.190752	2025-12-06 14:47:45.290654	2025-12-06 14:47:45.290654
352	90f02907-b15c-4afe-ad3c-6973d2ded413	192.168.1.6	android	{"os": "android", "is_web": false, "locale": "en_US", "is_debug": true, "os_version": "BP22.250325.006", "number_of_processors": 4}	2025-12-06 11:36:57.863966	2025-12-06 19:36:58.678119	2025-12-06 19:36:58.678119
353	440c0e35-0318-4725-8a5d-ca8776e84907	192.168.1.6	android	{"os": "android", "is_web": false, "locale": "en_US", "is_debug": true, "os_version": "BP22.250325.006", "number_of_processors": 4}	2025-12-07 03:14:07.294484	2025-12-07 11:14:07.890752	2025-12-07 11:14:07.890752
354	b398df79-9ba2-47ca-914c-15f818c0c9dc	192.168.1.6	android	{"os": "android", "is_web": false, "locale": "en_US", "is_debug": true, "os_version": "BP22.250325.006", "number_of_processors": 4}	2025-12-07 06:06:16.397316	2025-12-07 14:06:20.79535	2025-12-07 14:06:20.79535
355	66b3a1b6-2898-447d-9ef9-2437ee42ec17	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-07 15:03:48.971599	2025-12-07 15:03:47.416339	2025-12-07 15:03:47.416339
356	fb04d5bd-cbd2-415b-8dea-f9abc8e16541	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-07 15:16:36.146148	2025-12-07 15:16:34.568249	2025-12-07 15:16:34.568249
357	a0a7c99c-e18f-4c85-88df-12fad369dfa1	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-07 15:57:35.093631	2025-12-07 15:57:33.713802	2025-12-07 15:57:33.713802
358	88e1f312-d330-4636-bc1a-a9bbf534d091	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-07 17:23:19.627771	2025-12-07 17:23:17.99631	2025-12-07 17:23:17.99631
359	e77c2a67-59ad-414c-8577-2c7ab26e92a7	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-07 17:36:30.447205	2025-12-07 17:36:28.836043	2025-12-07 17:36:28.836043
360	04f7a7f7-add1-49f5-ac2a-f5f02fb9c0da	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-07 18:26:10.522767	2025-12-07 18:26:08.988145	2025-12-07 18:26:08.988145
361	2e855d1a-20d5-47c0-bd20-3b1902743bb4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-07 20:08:11.56154	2025-12-07 20:08:09.653605	2025-12-07 20:08:09.653605
362	b982702f-f947-4715-bf8b-3da0d7c370ea	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-07 21:04:04.912757	2025-12-07 21:04:05.399331	2025-12-07 21:04:05.399331
363	76a0ba4b-565c-491e-87e4-f3221feb8c98	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-07 21:53:02.107655	2025-12-07 21:53:02.353075	2025-12-07 21:53:02.353075
364	3d05c9cc-09eb-42c1-a52d-8f1122a99deb	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-07 23:29:03.776418	2025-12-07 23:29:04.117257	2025-12-07 23:29:04.117257
365	cb203913-d5a8-455a-8fd2-6fa5d509b8fa	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-08 12:44:15.463786	2025-12-08 12:44:16.311579	2025-12-08 12:44:16.311579
366	0303f8aa-c4c9-4c81-abfd-716af4c83cb6	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-08 19:48:13.794772	2025-12-08 19:48:14.384991	2025-12-08 19:48:14.384991
367	bab22c35-22e0-4af6-ae92-21f64172d8b9	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-09 11:24:43.279675	2025-12-09 11:24:43.636546	2025-12-09 11:24:43.636546
368	0e37b92f-b3b5-461a-844b-79d44c1cb2c1	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-10 18:57:27.902476	2025-12-10 18:57:27.31123	2025-12-10 18:57:27.31123
369	1a6f607a-cf1c-420f-acfb-3074e4d81964	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-10 19:37:03.504125	2025-12-10 19:37:02.777548	2025-12-10 19:37:02.777548
370	d6ccceeb-666b-452c-abd6-e4286dd08ded	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-10 19:53:28.021638	2025-12-10 19:53:27.325222	2025-12-10 19:53:27.325222
371	87fc4bdc-578d-45a1-a99d-ad055b7ee49b	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-10 22:29:02.526936	2025-12-10 22:29:01.570082	2025-12-10 22:29:01.570082
372	38ef21cb-c393-4970-a750-b79f78a6a8ec	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-10 22:37:44.481886	2025-12-10 22:37:43.524498	2025-12-10 22:37:43.524498
373	2413293a-e6b5-4bdc-956a-04f656bb6cef	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-10 22:42:23.524179	2025-12-10 22:42:22.56567	2025-12-10 22:42:22.56567
375	d428c2c8-7c60-4d6c-b90b-5a52b07cdd70	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-11 20:17:09.532403	2025-12-11 20:17:09.144779	2025-12-11 20:17:09.144779
376	7c61cdbc-704f-4150-a252-d7da7d24997e	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-12 11:08:38.177187	2025-12-12 11:08:37.442559	2025-12-12 11:08:37.442559
374	d196c61e-33ab-4205-a365-d6b96b29cfe0	192.168.1.6	windows	{"os": "windows", "is_web": false, "locale": "zh_CN", "is_debug": true, "os_version": "\\"Windows 10 Pro\\" 10.0 (Build 19045)", "number_of_processors": 16}	2025-12-11 16:52:35.913278	2025-12-11 16:52:36.770472	2025-12-12 15:52:29.763843
377	56797a6f-acf7-4adb-b103-c9b459993112	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-12 15:52:49.334541	2025-12-12 15:52:47.851325	2025-12-12 15:52:47.851325
378	0faf59fd-6689-47dd-a4f9-add7614be8f4	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-13 16:17:55.189291	2025-12-13 16:17:55.706059	2025-12-13 16:17:55.706059
379	b031d19a-b8d4-4209-881d-53cd0305d878	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-13 17:17:21.826166	2025-12-13 17:17:22.134576	2025-12-13 17:17:22.134576
380	641f3b5e-f787-4a34-ab42-ddbb505c8efd	192.168.1.7	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "GLK-AL00 3.0.0.168(C00E160R1P3)", "number_of_processors": 8}	2025-12-13 21:13:43.052769	2025-12-13 21:13:43.210998	2025-12-13 21:13:43.210998
381	b8b7c04e-49f6-4fe3-9304-68a08e221400	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-12-14 12:10:50.473543	2025-12-14 12:10:49.671188	2025-12-14 12:10:49.671188
\.


--
-- Data for Name: favorite_contacts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favorite_contacts (id, user_id, contact_id, created_at) FROM stdin;
\.


--
-- Data for Name: favorite_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favorite_groups (id, user_id, group_id, created_at) FROM stdin;
\.


--
-- Data for Name: favorites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favorites (id, user_id, message_id, content, message_type, file_name, sender_id, sender_name, created_at, server_id, sync_status) FROM stdin;
77	151	3580	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765367589_1762490101_3_k4vl6CdQ.jpg	image	\N	151	寮犲皬鑾?2025-12-10 20:00:25.145108	\N	synced
78	149	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765368903_VirtualBox_win11_08_11_2025_17_26_33.png	image	\N	151	寮犲皬鑾?2025-12-10 20:15:22.342241	\N	synced
79	149	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765369392_ic_launcher.png	image	\N	151	寮犲皬鑾?2025-12-10 20:23:22.149125	\N	synced
80	149	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765369885_1.jpeg	image	\N	151	寮犲皬鑾?2025-12-10 20:31:48.557345	\N	synced
\.


--
-- Data for Name: file_assistant_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.file_assistant_messages (id, user_id, content, message_type, file_name, quoted_message_id, quoted_message_content, status, created_at, server_id) FROM stdin;
\.


--
-- Data for Name: group_members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_members (id, group_id, user_id, nickname, remark, role, joined_at, is_muted, approval_status, do_not_disturb) FROM stdin;
121	23	103	\N	\N	owner	2025-11-24 19:23:07.594289	f	approved	f
123	23	104	\N	\N	member	2025-11-24 22:06:28.895463	f	approved	f
122	23	102	\N	\N	member	2025-11-24 19:23:07.614398	f	approved	f
124	24	112	\N	\N	owner	2025-11-25 14:27:47.606821	f	approved	f
125	24	102	\N	\N	member	2025-11-25 14:27:47.60855	f	approved	f
126	25	107	\N	\N	owner	2025-11-26 08:02:29.84972	f	approved	f
127	25	114	\N	\N	member	2025-11-26 08:02:29.850555	f	approved	f
205	57	114	ttttt	\N	member	2025-11-30 13:01:12.044095	f	approved	f
206	58	122	\N	\N	owner	2025-11-30 14:54:43.897002	f	approved	f
129	26	103	\N	\N	member	2025-11-26 11:03:31.407531	f	approved	f
128	26	113	\N	\N	owner	2025-11-26 11:03:31.406152	f	approved	f
130	26	114	\N	\N	member	2025-11-26 12:43:40.79702	f	approved	f
131	27	113	\N	\N	owner	2025-11-27 00:07:23.592911	f	approved	f
132	27	104	\N	\N	member	2025-11-27 00:07:23.595693	f	approved	f
133	27	103	\N	\N	member	2025-11-27 00:07:23.596648	f	approved	f
134	27	114	\N	\N	member	2025-11-27 00:07:23.597535	f	approved	f
135	28	118	\N	\N	owner	2025-11-27 01:22:59.644533	f	approved	f
136	28	109	\N	\N	member	2025-11-27 01:22:59.646112	f	approved	f
137	29	106	\N	\N	owner	2025-11-27 02:08:56.731117	f	approved	f
138	29	114	\N	\N	member	2025-11-27 02:08:56.732693	f	approved	f
139	30	106	\N	\N	owner	2025-11-27 02:20:50.768234	f	approved	f
140	30	114	\N	\N	member	2025-11-27 02:20:50.769224	f	approved	f
141	31	106	\N	\N	owner	2025-11-27 02:24:05.099472	f	approved	f
142	31	114	\N	\N	member	2025-11-27 02:24:05.100423	f	approved	f
143	32	114	\N	\N	owner	2025-11-27 02:42:09.837501	f	approved	f
144	32	109	\N	\N	member	2025-11-27 02:42:09.857385	f	approved	f
145	32	121	\N	\N	member	2025-11-27 02:42:09.859558	f	approved	f
146	32	113	\N	\N	member	2025-11-27 02:42:09.861569	f	approved	f
147	32	103	\N	\N	member	2025-11-27 02:42:09.863549	f	approved	f
148	33	103	\N	\N	owner	2025-11-27 18:47:10.804777	f	approved	f
149	33	127	\N	\N	member	2025-11-27 18:47:10.806173	f	approved	f
150	34	103	\N	\N	owner	2025-11-27 18:52:46.909515	f	approved	f
151	34	127	\N	\N	member	2025-11-27 18:52:46.910953	f	approved	f
152	35	103	\N	\N	owner	2025-11-27 18:57:42.29682	f	approved	f
153	35	127	\N	\N	member	2025-11-27 18:57:42.297685	f	approved	f
154	36	103	\N	\N	owner	2025-11-27 19:00:40.15245	f	approved	f
155	36	127	\N	\N	member	2025-11-27 19:00:40.154445	f	approved	f
156	37	103	\N	\N	owner	2025-11-27 19:05:13.082442	f	approved	f
157	37	127	\N	\N	member	2025-11-27 19:05:13.084377	f	approved	f
158	38	103	\N	\N	owner	2025-11-27 19:10:34.433955	f	approved	f
159	38	127	\N	\N	member	2025-11-27 19:10:34.434973	f	approved	f
160	39	103	\N	\N	owner	2025-11-27 19:23:29.371541	f	approved	f
161	39	127	\N	\N	member	2025-11-27 19:23:29.372468	f	approved	f
162	40	105	\N	\N	owner	2025-11-27 19:36:08.997424	f	approved	f
163	40	127	\N	\N	member	2025-11-27 19:36:08.998471	f	approved	f
164	41	114	\N	\N	owner	2025-11-28 18:44:11.937004	f	approved	f
165	41	129	\N	\N	member	2025-11-28 18:44:11.93866	f	approved	f
166	41	121	\N	\N	member	2025-11-28 18:44:11.939264	f	approved	f
167	42	106	\N	\N	owner	2025-11-29 11:33:27.101676	f	approved	f
168	42	107	\N	\N	member	2025-11-29 11:33:27.104436	f	approved	f
169	43	106	\N	\N	owner	2025-11-29 11:45:33.933325	f	approved	f
170	43	107	\N	\N	member	2025-11-29 11:45:33.935017	f	approved	f
171	44	107	\N	\N	owner	2025-11-29 11:49:43.870639	f	approved	f
172	44	106	\N	\N	member	2025-11-29 11:49:43.872328	f	approved	f
173	45	107	\N	\N	owner	2025-11-29 11:53:31.07869	f	approved	f
174	45	106	\N	\N	member	2025-11-29 11:53:31.082253	f	approved	f
175	46	106	\N	\N	owner	2025-11-29 12:02:11.229129	f	approved	f
176	46	107	\N	\N	member	2025-11-29 12:02:11.230755	f	approved	f
177	47	107	\N	\N	owner	2025-11-29 12:02:31.59915	f	approved	f
178	47	106	\N	\N	member	2025-11-29 12:02:31.60134	f	approved	f
179	48	106	\N	\N	owner	2025-11-29 12:03:59.98705	f	approved	f
180	48	107	\N	\N	member	2025-11-29 12:03:59.988676	f	approved	f
181	49	107	\N	\N	owner	2025-11-29 12:08:08.713246	f	approved	f
182	49	106	\N	\N	member	2025-11-29 12:08:08.714735	f	approved	f
183	50	106	\N	\N	owner	2025-11-29 12:08:30.594247	f	approved	f
184	50	107	\N	\N	member	2025-11-29 12:08:30.595322	f	approved	f
185	51	106	\N	\N	owner	2025-11-29 12:21:45.572796	f	approved	f
186	51	107	\N	\N	member	2025-11-29 12:21:45.57378	f	approved	f
187	52	106	\N	\N	owner	2025-11-29 12:26:38.857724	f	approved	f
188	52	107	\N	\N	member	2025-11-29 12:26:38.859417	f	approved	f
189	53	106	\N	\N	owner	2025-11-29 12:27:37.361275	f	approved	f
190	53	107	\N	\N	member	2025-11-29 12:27:37.362272	f	approved	f
191	54	107	\N	\N	owner	2025-11-29 12:27:57.543141	f	approved	f
192	54	106	\N	\N	member	2025-11-29 12:27:57.544098	f	approved	f
193	55	137	\N	\N	owner	2025-11-29 21:59:58.189806	f	approved	f
197	55	102	\N	\N	member	2025-11-30 09:29:28.780664	f	approved	f
198	55	114	\N	\N	member	2025-11-30 09:34:25.032973	f	approved	f
199	56	137	\N	\N	owner	2025-11-30 10:05:06.867545	f	approved	f
200	56	102	\N	\N	member	2025-11-30 10:05:06.869313	f	approved	f
203	56	114	\N	\N	member	2025-11-30 10:11:15.27155	f	approved	f
204	57	122	\N	\N	owner	2025-11-30 13:01:12.042401	f	approved	f
207	58	119	pppp	\N	member	2025-11-30 14:54:43.899199	f	approved	f
208	59	122	\N	\N	owner	2025-11-30 15:03:18.584037	f	approved	f
209	59	119	\N	\N	member	2025-11-30 15:03:18.584995	f	approved	f
210	60	122	\N	\N	owner	2025-11-30 15:07:59.241291	f	approved	f
211	60	120	\N	\N	member	2025-11-30 15:07:59.242383	f	approved	f
213	61	119	\N	\N	member	2025-11-30 15:19:42.725156	f	approved	f
214	62	122	\N	\N	owner	2025-11-30 16:04:09.676761	f	approved	f
223	62	120	\N	\N	member	2025-11-30 17:09:24.962027	f	approved	f
212	61	122	娴嬭瘯27-8	\N	owner	2025-11-30 15:19:42.723504	f	approved	f
240	61	120	\N	\N	member	2025-11-30 20:49:34.494809	f	approved	f
239	61	112	test-nick-3	\N	member	2025-11-30 18:49:21.923634	f	approved	f
241	63	122	\N	\N	owner	2025-11-30 20:51:44.619366	f	approved	f
242	63	112	\N	\N	member	2025-11-30 20:51:44.620374	f	approved	f
243	63	120	\N	\N	member	2025-11-30 20:51:44.621283	f	approved	f
244	64	122	\N	\N	owner	2025-11-30 20:52:16.1528	f	approved	f
245	64	112	\N	\N	member	2025-11-30 20:52:16.15746	f	approved	f
246	64	120	\N	\N	member	2025-11-30 20:52:16.158441	f	approved	f
247	65	122	\N	\N	owner	2025-11-30 20:55:01.964083	f	approved	f
248	65	112	\N	\N	member	2025-11-30 20:55:01.96513	f	approved	f
250	66	122	\N	\N	owner	2025-11-30 21:00:45.268958	f	approved	t
251	66	112	\N	\N	member	2025-11-30 21:00:45.270595	f	approved	f
256	66	120	\N	\N	member	2025-11-30 21:35:47.683033	f	approved	f
257	66	114	\N	\N	member	2025-11-30 21:40:37.2694	f	approved	f
258	67	112	\N	\N	owner	2025-11-30 21:54:07.896719	f	approved	f
259	67	114	\N	\N	member	2025-11-30 21:54:07.900617	f	approved	f
260	67	122	\N	\N	member	2025-11-30 21:54:07.9027	f	approved	f
261	67	113	\N	\N	member	2025-11-30 22:06:11.329574	f	approved	f
262	67	137	\N	\N	member	2025-11-30 22:06:48.744429	f	approved	f
263	67	102	\N	\N	member	2025-11-30 22:18:04.854884	f	approved	f
264	67	121	\N	\N	member	2025-11-30 22:18:31.675161	f	approved	f
268	68	113	\N	\N	member	2025-12-01 09:03:02.440434	f	pending	f
267	68	114	\N	\N	member	2025-12-01 08:59:50.478072	f	approved	f
269	69	113	\N	\N	owner	2025-12-01 14:36:25.454791	f	approved	f
270	69	138	\N	\N	member	2025-12-01 14:36:25.456605	f	approved	f
275	69	112	\N	\N	member	2025-12-01 15:11:12.415315	f	approved	f
272	70	112	\N	\N	owner	2025-12-01 14:56:00.482148	f	approved	f
277	71	113	\N	\N	owner	2025-12-01 15:21:19.268071	f	approved	f
279	72	112	\N	\N	owner	2025-12-01 15:22:26.826547	f	approved	f
265	68	112	\N	\N	owner	2025-12-01 08:59:50.475309	f	approved	f
282	73	113	\N	\N	owner	2025-12-01 15:25:21.990277	f	approved	f
283	73	112	\N	\N	member	2025-12-01 15:25:21.992009	f	approved	f
284	74	113	\N	\N	owner	2025-12-01 15:32:07.561943	f	approved	f
285	74	112	\N	\N	member	2025-12-01 15:32:07.563823	f	approved	f
286	75	113	\N	\N	owner	2025-12-01 15:35:38.71709	f	approved	f
287	75	112	\N	\N	member	2025-12-01 15:35:38.719298	f	approved	f
288	76	113	\N	\N	owner	2025-12-01 15:39:24.89522	f	approved	f
289	76	112	\N	\N	member	2025-12-01 15:39:24.897249	f	approved	f
290	77	113	\N	\N	owner	2025-12-01 15:43:05.670159	f	approved	f
291	77	112	\N	\N	member	2025-12-01 15:43:05.671979	f	approved	f
292	78	113	\N	\N	owner	2025-12-01 15:47:16.316509	f	approved	f
293	78	112	\N	\N	member	2025-12-01 15:47:16.318691	f	approved	f
294	79	113	\N	\N	owner	2025-12-01 15:50:18.700504	f	approved	f
296	79	114	\N	\N	member	2025-12-01 15:50:33.808711	f	approved	f
297	80	112	\N	\N	owner	2025-12-01 15:52:36.66427	f	approved	f
299	81	113	\N	\N	owner	2025-12-01 16:02:44.115281	f	approved	f
300	81	112	\N	\N	member	2025-12-01 16:02:44.117017	f	approved	f
333	92	142	88888	\N	owner	2025-12-01 22:21:48.721966	f	approved	f
304	83	113	鎴戞槸娴嬭瘯22	\N	owner	2025-12-01 16:17:42.586958	f	approved	f
308	84	113	\N	\N	owner	2025-12-01 16:32:08.981565	f	approved	f
316	83	114	\N	\N	member	2025-12-01 17:27:12.628525	f	approved	f
301	82	112	\N	\N	owner	2025-12-01 16:03:42.930997	f	approved	f
311	85	112	\N	\N	owner	2025-12-01 16:41:42.822575	f	approved	f
313	86	113	\N	\N	owner	2025-12-01 16:42:20.739548	f	approved	f
317	87	114	\N	\N	owner	2025-12-01 17:40:41.640812	f	approved	f
305	83	112	鎴戞槸娴嬭瘯21-22222	\N	member	2025-12-01 16:17:42.588831	f	approved	f
319	87	113	\N	\N	member	2025-12-01 17:40:41.643663	f	approved	f
320	87	122	\N	\N	member	2025-12-01 17:41:24.999576	f	approved	f
337	92	144	\N	\N	member	2025-12-02 19:54:56.715482	f	approved	f
318	87	112	\N	\N	member	2025-12-01 17:40:41.642612	f	approved	f
321	88	114	\N	\N	owner	2025-12-01 17:45:43.881529	f	approved	f
323	88	113	\N	\N	member	2025-12-01 17:45:43.890571	f	approved	f
324	88	122	\N	\N	member	2025-12-01 17:46:19.502792	f	pending	f
322	88	112	\N	\N	member	2025-12-01 17:45:43.882642	f	approved	f
325	89	112	\N	\N	owner	2025-12-01 18:30:21.074383	f	approved	f
326	89	114	\N	\N	member	2025-12-01 18:30:21.075505	f	approved	f
338	93	142	\N	\N	owner	2025-12-02 22:41:46.777356	f	approved	f
328	89	138	\N	\N	member	2025-12-01 18:33:46.74483	f	pending	f
339	93	143	\N	\N	member	2025-12-02 22:41:46.778974	f	approved	f
340	93	144	\N	\N	member	2025-12-02 22:41:46.779924	f	approved	f
329	90	113	\N	\N	owner	2025-12-01 21:28:16.666131	f	approved	f
341	94	142	\N	\N	owner	2025-12-02 23:34:02.64037	f	approved	f
342	94	143	\N	\N	member	2025-12-02 23:34:02.641927	f	approved	f
331	91	112	\N	\N	owner	2025-12-01 21:30:32.767119	f	approved	f
335	92	143	\N	\N	member	2025-12-01 22:21:48.725301	f	approved	f
343	94	144	\N	\N	member	2025-12-02 23:34:02.642709	f	approved	f
349	97	152	\N	\N	owner	2025-12-03 23:40:33.675592	f	approved	f
350	97	150	\N	\N	member	2025-12-03 23:40:33.676874	f	approved	f
351	98	149	\N	\N	owner	2025-12-04 09:59:55.350014	f	approved	f
352	98	151	\N	\N	member	2025-12-04 09:59:55.351381	f	approved	f
353	99	149	\N	\N	owner	2025-12-04 15:04:16.124502	f	approved	f
345	95	144	ppppp-test	\N	member	2025-12-03 00:07:18.217073	f	approved	f
344	95	142	娴嬭瘯51-test	\N	owner	2025-12-03 00:07:18.197332	f	approved	f
347	96	144	\N	\N	member	2025-12-03 16:00:29.785096	f	approved	f
348	96	146	\N	\N	member	2025-12-03 16:00:45.897903	f	approved	f
346	96	145	鍝堝搱	\N	owner	2025-12-03 16:00:29.783807	f	approved	f
356	100	109	\N	\N	owner	2025-12-05 12:33:32.251388	f	approved	f
357	100	151	\N	\N	member	2025-12-05 12:33:32.253397	f	approved	f
358	101	155	\N	\N	owner	2025-12-05 13:32:54.190549	f	approved	f
359	101	154	\N	\N	member	2025-12-05 13:32:54.192385	f	approved	f
360	101	151	\N	\N	member	2025-12-05 17:38:33.647279	f	approved	f
361	102	149	\N	\N	owner	2025-12-06 00:13:25.679235	f	approved	f
362	102	151	\N	\N	member	2025-12-06 00:13:25.680875	f	approved	f
363	103	149	\N	\N	owner	2025-12-06 00:14:36.523753	f	approved	f
364	103	151	\N	\N	member	2025-12-06 00:14:36.525338	f	approved	f
365	104	149	\N	\N	owner	2025-12-06 00:18:34.979953	f	approved	f
366	104	151	\N	\N	member	2025-12-06 00:18:34.98081	f	approved	f
398	99	150	\N	\N	member	2025-12-06 19:45:06.218264	f	approved	f
354	99	151	\N	\N	member	2025-12-04 15:04:16.125831	f	approved	t
399	137	156	\N	\N	owner	2025-12-07 19:02:12.809172	f	approved	f
400	137	151	\N	\N	member	2025-12-07 19:02:12.810959	f	approved	f
401	138	156	\N	\N	owner	2025-12-07 19:02:21.226277	f	approved	f
402	138	151	\N	\N	member	2025-12-07 19:02:21.227211	f	approved	f
403	139	156	100100	\N	owner	2025-12-08 14:02:20.950925	f	approved	f
404	139	151	\N	\N	member	2025-12-08 14:02:20.954097	f	approved	f
405	140	156	\N	\N	owner	2025-12-08 14:11:57.436034	f	approved	f
406	140	151	\N	\N	member	2025-12-08 14:11:57.437683	f	approved	f
407	141	156	\N	\N	owner	2025-12-08 15:04:25.12456	f	approved	f
408	141	151	\N	\N	member	2025-12-08 15:04:25.144	f	approved	f
409	142	156	\N	\N	owner	2025-12-08 15:13:16.233858	f	approved	f
410	142	151	\N	\N	member	2025-12-08 15:13:16.235179	f	approved	f
411	143	156	1010	\N	owner	2025-12-08 15:21:17.054189	f	approved	t
412	143	151	\N	\N	member	2025-12-08 15:21:17.055815	f	approved	f
413	144	156	1011	\N	owner	2025-12-08 15:26:16.875834	f	approved	t
414	144	151	\N	\N	member	2025-12-08 15:26:16.877431	f	approved	f
416	145	151	\N	\N	member	2025-12-08 15:39:45.451859	f	approved	f
415	145	156	1012	\N	owner	2025-12-08 15:39:45.450157	f	approved	t
418	146	151	\N	\N	member	2025-12-08 18:10:47.150557	f	approved	f
417	146	156	1013	\N	owner	2025-12-08 18:10:47.148896	f	approved	t
419	147	156	1016	\N	owner	2025-12-08 18:41:38.398432	f	approved	t
420	147	151	\N	\N	member	2025-12-08 18:41:38.400661	f	approved	f
422	148	151	\N	\N	member	2025-12-08 18:53:27.652623	f	approved	f
421	148	156	\N	\N	owner	2025-12-08 18:53:27.651	f	approved	f
423	149	156	\N	\N	owner	2025-12-08 18:59:30.504416	f	approved	f
424	149	151	\N	\N	member	2025-12-08 18:59:30.506758	f	approved	f
425	150	156	\N	\N	owner	2025-12-08 19:01:12.138039	f	approved	f
426	150	151	\N	\N	member	2025-12-08 19:01:12.139088	f	approved	f
427	151	156	2222	\N	owner	2025-12-08 19:02:29.39025	f	approved	f
428	151	151	\N	\N	member	2025-12-08 19:02:29.391983	f	approved	f
429	152	156	\N	\N	owner	2025-12-08 19:07:04.708324	f	approved	f
430	152	151	\N	\N	member	2025-12-08 19:07:04.709498	f	approved	f
431	153	156	\N	\N	owner	2025-12-08 19:09:53.205026	f	approved	f
432	153	151	\N	\N	member	2025-12-08 19:09:53.206396	f	approved	f
433	154	156	\N	\N	owner	2025-12-08 19:12:16.45819	f	approved	f
434	154	151	\N	\N	member	2025-12-08 19:12:16.459361	f	approved	f
435	155	156	\N	\N	owner	2025-12-08 19:13:40.721978	f	approved	f
436	155	151	\N	\N	member	2025-12-08 19:13:40.723556	f	approved	f
437	156	156	\N	\N	owner	2025-12-08 19:19:43.454081	f	approved	f
438	156	151	\N	\N	member	2025-12-08 19:19:43.455749	f	approved	f
440	157	151	\N	\N	member	2025-12-08 19:34:03.320005	t	approved	f
441	157	149	\N	\N	member	2025-12-08 20:08:14.843227	t	approved	f
442	157	106	\N	\N	member	2025-12-08 20:31:30.343107	t	approved	f
439	157	156	222	\N	owner	2025-12-08 19:34:03.318448	f	approved	t
447	158	151	\N	\N	owner	2025-12-09 11:53:07.279793	f	approved	f
448	158	157	\N	\N	member	2025-12-09 11:53:07.284109	f	approved	f
449	158	150	\N	\N	member	2025-12-09 12:11:19.108744	f	approved	f
450	158	149	\N	\N	member	2025-12-09 12:16:30.798963	f	approved	f
452	158	152	\N	\N	member	2025-12-09 12:23:58.826557	f	approved	f
453	159	158	\N	\N	owner	2025-12-14 11:32:45.575318	f	approved	f
454	159	151	\N	\N	member	2025-12-14 11:32:45.578981	f	approved	f
455	159	150	\N	\N	member	2025-12-14 11:33:32.319644	f	approved	f
\.


--
-- Data for Name: group_message_reads; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_message_reads (id, group_message_id, user_id, read_at) FROM stdin;
\.


--
-- Data for Name: group_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_messages (id, group_id, sender_id, sender_name, content, message_type, file_name, quoted_message_id, quoted_message_content, status, created_at, sender_avatar, mentioned_user_ids, mentions, deleted_by_users, call_type, channel_name, sender_nickname, sender_full_name, server_id, voice_duration) FROM stdin;
1995	137	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍1"	system	\N	\N	\N	normal	2025-12-07 19:02:12.813667	\N	\N	\N		\N	\N	\N	\N	\N	\N
1996	137	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍1"	system	\N	\N	\N	normal	2025-12-07 19:02:12.815796	\N	\N	\N		\N	\N	\N	\N	\N	\N
1997	138	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍2"	system	\N	\N	\N	normal	2025-12-07 19:02:21.229287	\N	\N	\N		\N	\N	\N	\N	\N	\N
1998	138	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍2"	system	\N	\N	\N	normal	2025-12-07 19:02:21.231243	\N	\N	\N		\N	\N	\N	\N	\N	\N
1999	137	156	娴嬭瘯63	11	text	\N	\N	\N	normal	2025-12-07 19:02:58.985814	\N	\N	\N		\N	\N	\N	娴嬭瘯63	\N	\N
2000	137	156	娴嬭瘯63	22	text	\N	\N	\N	normal	2025-12-07 19:13:43.318577	\N	\N	\N		\N	\N	\N	娴嬭瘯63	\N	\N
2001	138	156	娴嬭瘯63	11	text	\N	\N	\N	normal	2025-12-07 19:13:47.438636	\N	\N	\N		\N	\N	\N	娴嬭瘯63	\N	\N
2002	137	156	娴嬭瘯63	111	text	\N	\N	\N	normal	2025-12-07 19:20:22.571949	\N	\N	\N		\N	\N	\N	娴嬭瘯63	\N	\N
2003	138	156	娴嬭瘯63	222	text	\N	\N	\N	normal	2025-12-07 19:31:18.637041	\N	\N	\N		\N	\N	\N	娴嬭瘯63	\N	\N
2004	137	156	娴嬭瘯63	333	text	\N	\N	\N	normal	2025-12-07 19:34:38.306698	\N	\N	\N		\N	\N	\N	娴嬭瘯63	\N	\N
2005	137	156	娴嬭瘯63	111	text	\N	\N	\N	normal	2025-12-07 19:42:38.731421	\N	\N	\N		\N	\N	\N	娴嬭瘯63	\N	\N
2006	137	151	寮犲皬鑾?222	text	\N	\N	\N	normal	2025-12-07 19:42:49.002575	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N		\N	\N	\N	寮犲皬鑾?\N	\N
2008	137	151	寮犲皬鑾?閫氳瘽鏃堕暱 00:04	call_ended_video	\N	\N	\N	normal	2025-12-07 19:45:00.976245	\N	\N	\N		video	group_call_156_1765107896	\N	\N	\N	\N
2009	139	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍100"	system	\N	\N	\N	normal	2025-12-08 14:02:20.957009	\N	\N	\N		\N	\N	\N	\N	\N	\N
2010	139	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍100"	system	\N	\N	\N	normal	2025-12-08 14:02:20.966351	\N	\N	\N		\N	\N	\N	\N	\N	\N
2011	140	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍102"	system	\N	\N	\N	normal	2025-12-08 14:11:57.440259	\N	\N	\N		\N	\N	\N	\N	\N	\N
2012	140	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍102"	system	\N	\N	\N	normal	2025-12-08 14:11:57.442832	\N	\N	\N		\N	\N	\N	\N	\N	\N
2013	141	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍10086"	system	\N	\N	\N	normal	2025-12-08 15:04:25.165468	\N	\N	\N		\N	\N	\N	\N	\N	\N
2014	141	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍10086"	system	\N	\N	\N	normal	2025-12-08 15:04:25.184383	\N	\N	\N		\N	\N	\N	\N	\N	\N
2015	142	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍1009"	system	\N	\N	\N	normal	2025-12-08 15:13:16.237936	\N	\N	\N		\N	\N	\N	\N	\N	\N
2016	142	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍1009"	system	\N	\N	\N	normal	2025-12-08 15:13:16.241377	\N	\N	\N		\N	\N	\N	\N	\N	\N
2017	143	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍1010"	system	\N	\N	\N	normal	2025-12-08 15:21:17.058446	\N	\N	\N		\N	\N	\N	\N	\N	\N
2018	143	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍1010"	system	\N	\N	\N	normal	2025-12-08 15:21:17.061188	\N	\N	\N		\N	\N	\N	\N	\N	\N
2019	144	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍10011"	system	\N	\N	\N	normal	2025-12-08 15:26:16.880124	\N	\N	\N		\N	\N	\N	\N	\N	\N
2020	144	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍10011"	system	\N	\N	\N	normal	2025-12-08 15:26:16.883299	\N	\N	\N		\N	\N	\N	\N	\N	\N
2021	145	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍1012"	system	\N	\N	\N	normal	2025-12-08 15:39:45.454593	\N	\N	\N		\N	\N	\N	\N	\N	\N
2022	145	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍1012"	system	\N	\N	\N	normal	2025-12-08 15:39:45.45783	\N	\N	\N		\N	\N	\N	\N	\N	\N
2023	146	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍1013"	system	\N	\N	\N	normal	2025-12-08 18:10:47.153155	\N	\N	\N		\N	\N	\N	\N	\N	\N
2024	146	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍1013"	system	\N	\N	\N	normal	2025-12-08 18:10:47.155777	\N	\N	\N		\N	\N	\N	\N	\N	\N
2025	147	156	test63	鍒涘缓鏂扮兢缁?缇ょ粍1016"	system	\N	\N	\N	normal	2025-12-08 18:41:38.404325	\N	\N	\N		\N	\N	\N	\N	\N	\N
2026	147	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍1016"	system	\N	\N	\N	normal	2025-12-08 18:41:38.408633	\N	\N	\N		\N	\N	\N	\N	\N	\N
2027	140	156	娴嬭瘯63	1	text	\N	\N	\N	normal	2025-12-08 18:49:59.380918	\N	\N	\N		\N	\N	\N	娴嬭瘯63	\N	\N
2028	140	156	娴嬭瘯63	123	text	\N	\N	\N	normal	2025-12-08 18:50:05.674792	\N	\N	\N		\N	\N	\N	娴嬭瘯63	\N	\N
2029	140	156	娴嬭瘯63	444	text	\N	\N	\N	normal	2025-12-08 18:51:00.735866	\N	\N	\N		\N	\N	\N	娴嬭瘯63	\N	\N
2030	148	156	test63	鍒涘缓鏂扮兢缁?1014"	system	\N	\N	\N	normal	2025-12-08 18:53:27.655169	\N	\N	\N		\N	\N	\N	\N	\N	\N
2031	148	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?1014"	system	\N	\N	\N	normal	2025-12-08 18:53:27.658952	\N	\N	\N		\N	\N	\N	\N	\N	\N
2032	149	156	test63	鍒涘缓鏂扮兢缁?1015"	system	\N	\N	\N	normal	2025-12-08 18:59:30.510783	\N	\N	\N		\N	\N	\N	\N	\N	\N
2033	149	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?1015"	system	\N	\N	\N	normal	2025-12-08 18:59:30.51505	\N	\N	\N		\N	\N	\N	\N	\N	\N
2034	150	156	test63	鍒涘缓鏂扮兢缁?1017"	system	\N	\N	\N	normal	2025-12-08 19:01:12.141472	\N	\N	\N		\N	\N	\N	\N	\N	\N
2035	150	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?1017"	system	\N	\N	\N	normal	2025-12-08 19:01:12.145222	\N	\N	\N		\N	\N	\N	\N	\N	\N
2036	151	156	test63	鍒涘缓鏂扮兢缁?1018"	system	\N	\N	\N	normal	2025-12-08 19:02:29.394586	\N	\N	\N		\N	\N	\N	\N	\N	\N
2037	151	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?1018"	system	\N	\N	\N	normal	2025-12-08 19:02:29.398185	\N	\N	\N		\N	\N	\N	\N	\N	\N
2038	152	156	test63	鍒涘缓鏂扮兢缁?1019"	system	\N	\N	\N	normal	2025-12-08 19:07:04.712077	\N	\N	\N		\N	\N	\N	\N	\N	\N
2039	152	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?1019"	system	\N	\N	\N	normal	2025-12-08 19:07:04.715332	\N	\N	\N		\N	\N	\N	\N	\N	\N
2040	153	156	test63	鍒涘缓鏂扮兢缁?1020"	system	\N	\N	\N	normal	2025-12-08 19:09:53.209722	\N	\N	\N		\N	\N	\N	\N	\N	\N
2041	153	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?1020"	system	\N	\N	\N	normal	2025-12-08 19:09:53.213793	\N	\N	\N		\N	\N	\N	\N	\N	\N
2042	154	156	test63	鍒涘缓鏂扮兢缁?1021"	system	\N	\N	\N	normal	2025-12-08 19:12:16.462435	\N	\N	\N		\N	\N	\N	\N	\N	\N
2043	154	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?1021"	system	\N	\N	\N	normal	2025-12-08 19:12:16.465656	\N	\N	\N		\N	\N	\N	\N	\N	\N
2044	155	156	test63	鍒涘缓鏂扮兢缁?1022"	system	\N	\N	\N	normal	2025-12-08 19:13:40.726488	\N	\N	\N		\N	\N	\N	\N	\N	\N
2045	155	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?1022"	system	\N	\N	\N	normal	2025-12-08 19:13:40.729605	\N	\N	\N		\N	\N	\N	\N	\N	\N
2046	156	156	test63	鍒涘缓鏂扮兢缁?1023"	system	\N	\N	\N	normal	2025-12-08 19:19:43.45865	\N	\N	\N		\N	\N	\N	\N	\N	\N
2047	156	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?1023"	system	\N	\N	\N	normal	2025-12-08 19:19:43.461583	\N	\N	\N		\N	\N	\N	\N	\N	\N
2048	157	156	test63	鍒涘缓鏂扮兢缁?1024"	system	\N	\N	\N	normal	2025-12-08 19:34:03.322466	\N	\N	\N		\N	\N	\N	\N	\N	\N
2049	157	156	test63	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?1024"	system	\N	\N	\N	normal	2025-12-08 19:34:03.325371	\N	\N	\N		\N	\N	\N	\N	\N	\N
2056	157	156	娴嬭瘯63	鎮ㄥ凡琚Щ闄ょ兢缁?system	\N	\N	\N	normal	2025-12-08 20:31:40.50254	\N	\N	\N		\N	\N	\N	\N	\N	\N
2057	157	156	娴嬭瘯63	鎮ㄥ凡琚Щ闄ょ兢缁?system	\N	\N	\N	normal	2025-12-08 20:37:21.79453	\N	\N	\N		\N	\N	\N	\N	\N	\N
2058	157	156	娴嬭瘯63	鎮ㄥ凡琚Щ闄ょ兢缁?system	\N	\N	\N	normal	2025-12-08 20:37:51.333715	\N	\N	\N		\N	\N	\N	\N	\N	\N
2059	157	156	娴嬭瘯63	鎮ㄥ凡琚Щ闄ょ兢缁?system	\N	\N	\N	normal	2025-12-08 20:39:47.808257	\N	\N	\N		\N	\N	\N	\N	\N	\N
2060	157	106	娴嬭瘯05	444	text	\N	\N	\N	normal	2025-12-08 20:42:40.112553	\N	\N	\N		\N	\N	\N	娴嬭瘯05	\N	\N
2061	157	156	娴嬭瘯63	鎮ㄥ凡琚Щ闄ょ兢缁?system	\N	\N	\N	normal	2025-12-08 21:11:56.533323	\N	\N	\N		\N	\N	\N	\N	\N	\N
2062	157	156	娴嬭瘯63	鍏ㄤ綋绂佽█宸插紑鍚?system	\N	\N	\N	normal	2025-12-08 21:27:27.693228	\N	\N	\N		\N	\N	\N	\N	\N	\N
2063	157	156	娴嬭瘯63	鍏ㄤ綋绂佽█宸插叧闂?system	\N	\N	\N	normal	2025-12-08 21:35:39.106217	\N	\N	\N		\N	\N	\N	\N	\N	\N
2064	157	156	娴嬭瘯63	鍏ㄤ綋绂佽█宸插紑鍚?system	\N	\N	\N	normal	2025-12-08 21:39:01.19391	\N	\N	\N		\N	\N	\N	\N	\N	\N
2065	157	156	娴嬭瘯63	鎮ㄥ凡琚Щ闄ょ兢缁?system	\N	\N	\N	normal	2025-12-08 21:39:55.550157	\N	\N	\N		\N	\N	\N	\N	\N	\N
2066	158	151	test62	鍒涘缓鏂扮兢缁?缇ょ粍浜岀淮鐮?"	system	\N	\N	\N	normal	2025-12-09 11:53:07.289727	\N	\N	\N		\N	\N	\N	\N	\N	\N
2067	158	151	test62	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?缇ょ粍浜岀淮鐮?"	system	\N	\N	\N	normal	2025-12-09 11:53:07.296779	\N	\N	\N		\N	\N	\N	\N	\N	\N
2071	158	152	绯荤粺	鎮ㄥ凡鍔犲叆缇ょ粍"缇ょ粍浜岀淮鐮?"	system	\N	\N	\N	normal	2025-12-09 12:23:58.833351	\N	\N	\N		\N	\N	\N	\N	\N	\N
2072	158	152	娴嬭瘯65	223	text	\N	\N	\N	normal	2025-12-09 12:24:11.748053	\N	\N	\N		\N	\N	\N	娴嬭瘯65	\N	\N
2073	154	151	寮犲皬鑾?11	text	\N	\N	\N	normal	2025-12-12 18:33:11.095997	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N		\N	\N	\N	寮犲皬鑾?\N	\N
2074	150	151	寮犲皬鑾?11	text	\N	\N	\N	normal	2025-12-12 18:33:14.27953	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N		\N	\N	\N	寮犲皬鑾?\N	\N
2075	159	158	test73	鍒涘缓鏂扮兢缁?2222222"	system	\N	\N	\N	normal	2025-12-14 11:32:45.581422	\N	\N	\N		\N	\N	\N	\N	\N	\N
2076	159	158	test73	鎮ㄥ凡琚個璇峰姞鍏ョ兢缁?2222222"	system	\N	\N	\N	normal	2025-12-14 11:32:45.584848	\N	\N	\N		\N	\N	\N	\N	\N	\N
2077	159	150	绯荤粺	鎮ㄥ凡鍔犲叆缇ょ粍"2222222"	system	\N	\N	\N	normal	2025-12-14 11:33:32.322965	\N	\N	\N		\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.groups (id, name, announcement, avatar, owner_id, created_at, updated_at, deleted_at, all_muted, invite_confirmation, admin_only_edit_name, member_view_permission) FROM stdin;
23	111	\N	\N	103	2025-11-24 19:23:07.556208	2025-11-24 19:23:07.556208	\N	f	f	f	t
24	缇ょ粍01	\N	\N	112	2025-11-25 14:27:47.605044	2025-11-25 14:27:47.605044	\N	f	f	f	t
25	缇ゆ祴璇?2	\N	\N	107	2025-11-26 08:02:29.848503	2025-11-26 08:02:29.848503	\N	f	f	f	t
64	缇ょ粍2126	\N	\N	122	2025-11-30 20:52:16.151024	2025-11-30 20:52:16.151024	\N	f	f	f	t
85	缇ょ粍666	\N	\N	112	2025-12-01 16:41:42.821451	2025-12-01 16:42:05.186759	\N	f	f	f	t
86	qunzu777	\N	\N	113	2025-12-01 16:42:20.737529	2025-12-01 16:42:36.991907	\N	f	f	f	t
26	缇ょ粍娴嬭瘯3	\N	\N	113	2025-11-26 11:03:31.404564	2025-11-26 12:43:40.793218	\N	f	f	f	t
27	test group8	\N	\N	113	2025-11-27 00:07:23.589795	2025-11-27 00:07:23.589795	\N	f	f	f	t
28	缇ょ粍111	\N	\N	118	2025-11-27 01:22:59.642737	2025-11-27 01:22:59.642737	\N	f	f	f	t
29	yyyy	\N	\N	106	2025-11-27 02:08:56.726371	2025-11-27 02:08:56.726371	\N	f	f	f	t
30	hhhhhh	\N	\N	106	2025-11-27 02:20:50.767098	2025-11-27 02:20:50.767098	\N	f	f	f	t
31	nnnn	\N	\N	106	2025-11-27 02:24:05.098231	2025-11-27 02:24:05.098231	\N	f	f	f	t
32	ffddgh	\N	\N	114	2025-11-27 02:42:09.816653	2025-11-27 02:42:09.816653	\N	f	f	f	t
33	缇ょ粍001	\N	\N	103	2025-11-27 18:47:10.803241	2025-11-27 18:47:10.803241	\N	f	f	f	t
34	缇ょ粍002	\N	\N	103	2025-11-27 18:52:46.908053	2025-11-27 18:52:46.908053	\N	f	f	f	t
35	缇ょ粍003	\N	\N	103	2025-11-27 18:57:42.295743	2025-11-27 18:57:42.295743	\N	f	f	f	t
36	缇ょ粍004	\N	\N	103	2025-11-27 19:00:40.149257	2025-11-27 19:00:40.149257	\N	f	f	f	t
37	缇ょ粍005	\N	\N	103	2025-11-27 19:05:13.081565	2025-11-27 19:05:13.081565	\N	f	f	f	t
38	缇ょ粍006	\N	\N	103	2025-11-27 19:10:34.432812	2025-11-27 19:10:34.432812	\N	f	f	f	t
39	缇ょ粍007	\N	\N	103	2025-11-27 19:23:29.370595	2025-11-27 19:23:29.370595	\N	f	f	f	t
40	缇ょ粍009	\N	\N	105	2025-11-27 19:36:08.996191	2025-11-27 19:36:08.996191	\N	f	f	f	t
41	缇ょ粍222	\N	\N	114	2025-11-28 18:44:11.934845	2025-11-28 18:44:11.934845	\N	f	f	f	t
42	娴嬭瘯56	\N	\N	106	2025-11-29 11:33:27.099173	2025-11-29 11:33:27.099173	\N	f	f	f	t
43	缇ょ粍561	\N	\N	106	2025-11-29 11:45:33.931319	2025-11-29 11:45:33.931319	\N	f	f	f	t
44	缇ょ粍563	\N	\N	107	2025-11-29 11:49:43.868646	2025-11-29 11:49:43.868646	\N	f	f	f	t
45	缇ょ粍564	\N	\N	107	2025-11-29 11:53:31.075108	2025-11-29 11:53:31.075108	\N	f	f	f	t
46	缇ょ粍565	\N	\N	106	2025-11-29 12:02:11.227339	2025-11-29 12:02:11.227339	\N	f	f	f	t
47	566	\N	\N	107	2025-11-29 12:02:31.596933	2025-11-29 12:02:31.596933	\N	f	f	f	t
48	567	\N	\N	106	2025-11-29 12:03:59.985099	2025-11-29 12:03:59.985099	\N	f	f	f	t
49	568	\N	\N	107	2025-11-29 12:08:08.711307	2025-11-29 12:08:08.711307	\N	f	f	f	t
50	569	\N	\N	106	2025-11-29 12:08:30.59299	2025-11-29 12:08:30.59299	\N	f	f	f	t
51	570	\N	\N	106	2025-11-29 12:21:45.571856	2025-11-29 12:21:45.571856	\N	f	f	f	t
52	572	\N	\N	106	2025-11-29 12:26:38.855744	2025-11-29 12:26:38.855744	\N	f	f	f	t
53	573	\N	\N	106	2025-11-29 12:27:37.36009	2025-11-29 12:27:37.36009	\N	f	f	f	t
54	574	\N	\N	107	2025-11-29 12:27:57.541953	2025-11-29 12:27:57.541953	\N	f	f	f	t
137	缇ょ粍1	\N	\N	156	2025-12-07 19:02:12.80697	2025-12-07 19:02:12.80697	\N	f	f	f	t
95	缇ょ粍888	\N	\N	142	2025-12-03 00:07:18.192543	2025-12-03 10:14:34.840436	\N	f	f	f	t
65	缇ょ粍2127	\N	\N	122	2025-11-30 20:55:01.962854	2025-11-30 21:31:41.443127	\N	f	f	f	t
138	缇ょ粍2	\N	\N	156	2025-12-07 19:02:21.225097	2025-12-07 19:02:21.225097	\N	f	f	f	t
83	aaaaaa	\N	\N	113	2025-12-01 16:17:42.584982	2025-12-01 17:27:07.486291	\N	f	t	f	t
66	缇ょ粍2128	\N	\N	122	2025-11-30 21:00:45.267195	2025-11-30 21:38:57.379363	\N	f	t	f	t
67	test21鐨勭兢	\N	\N	112	2025-11-30 21:54:07.890128	2025-11-30 22:06:38.256747	\N	f	t	f	t
87	ddddd	\N	\N	114	2025-12-01 17:40:41.638946	2025-12-01 17:40:41.638946	\N	f	f	f	t
96	缇ょ粍5354	\N	\N	145	2025-12-03 16:00:29.782222	2025-12-03 18:31:49.971405	\N	f	f	f	t
88	sssss	\N	\N	114	2025-12-01 17:45:43.880153	2025-12-01 17:45:50.82688	\N	f	t	f	t
69	缇ょ粍娴嬭瘯56	\N	\N	113	2025-12-01 14:36:25.452957	2025-12-01 15:11:12.410468	\N	f	f	f	t
55	0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789	\N	\N	137	2025-11-29 21:59:58.187489	2025-11-30 09:31:20.552349	\N	f	t	f	t
70	缇ょ粍2122	\N	\N	112	2025-12-01 14:56:00.480348	2025-12-01 15:11:58.2569	\N	f	f	f	t
56	缇ょ粍000	\N	\N	137	2025-11-30 10:05:06.86548	2025-11-30 10:10:41.140182	\N	f	t	f	t
57	缇ょ粍190	\N	\N	122	2025-11-30 13:01:12.04043	2025-11-30 13:01:12.04043	\N	f	f	f	t
58	缇ょ粍009	\N	\N	122	2025-11-30 14:54:43.894971	2025-11-30 14:54:43.894971	\N	f	f	f	t
59	缇ょ粍010	\N	\N	122	2025-11-30 15:03:18.582849	2025-11-30 15:03:18.582849	\N	f	f	f	t
60	缇ょ粍011	\N	\N	122	2025-11-30 15:07:59.240053	2025-11-30 15:07:59.240053	\N	f	f	f	t
71	缇ょ粍22-21	\N	\N	113	2025-12-01 15:21:19.266113	2025-12-01 15:21:59.790516	\N	f	f	f	t
72	缇ょ粍21-22	\N	\N	112	2025-12-01 15:22:26.824237	2025-12-01 15:22:26.824237	\N	f	f	f	t
68	缇ょ粍2221	\N	\N	112	2025-12-01 08:59:50.473257	2025-12-01 15:24:03.293954	\N	f	t	f	t
73	goup01	\N	\N	113	2025-12-01 15:25:21.988149	2025-12-01 15:25:21.988149	\N	f	f	f	t
74	qqqqq	\N	\N	113	2025-12-01 15:32:07.559991	2025-12-01 15:32:07.559991	\N	f	f	f	t
75	QAAAA	\N	\N	113	2025-12-01 15:35:38.715175	2025-12-01 15:35:38.715175	\N	f	f	f	t
76	ooooo	\N	\N	113	2025-12-01 15:39:24.893198	2025-12-01 15:39:24.893198	\N	f	f	f	t
77	123123	\N	\N	113	2025-12-01 15:43:05.667473	2025-12-01 15:43:05.667473	\N	f	f	f	t
78	qaz	\N	\N	113	2025-12-01 15:47:16.314096	2025-12-01 15:47:16.314096	\N	f	f	f	t
62	缇ょ粍闀垮悕瀛?\N	\N	122	2025-11-30 16:04:09.675289	2025-11-30 18:29:21.620622	\N	f	f	f	t
79	3we	\N	\N	113	2025-12-01 15:50:18.698079	2025-12-01 15:51:47.592587	\N	f	f	f	t
80	group02	\N	\N	112	2025-12-01 15:52:36.662061	2025-12-01 15:52:36.662061	\N	f	f	f	t
81	OYURTU	\N	\N	113	2025-12-01 16:02:44.113406	2025-12-01 16:02:44.113406	\N	f	f	f	t
89	zzzzzz	\N	\N	112	2025-12-01 18:30:21.072413	2025-12-01 18:30:43.142557	\N	f	t	f	t
90	yrdhh	\N	\N	113	2025-12-01 21:28:16.664338	2025-12-01 21:28:16.664338	\N	f	f	f	t
61	缇ょ粍024	\N	\N	122	2025-11-30 15:19:42.721477	2025-11-30 20:49:34.488963	\N	f	f	f	t
63	缇ょ粍2125	\N	\N	122	2025-11-30 20:51:44.617472	2025-11-30 20:51:44.617472	\N	f	f	f	t
91	asdcasd	\N	\N	112	2025-12-01 21:30:32.765148	2025-12-01 21:30:32.765148	\N	f	f	f	t
82	Tret	\N	\N	112	2025-12-01 16:03:42.929699	2025-12-01 16:33:23.363559	\N	f	f	f	t
84	QQQEDWD	\N	\N	113	2025-12-01 16:32:08.979611	2025-12-01 16:33:41.397712	\N	f	f	f	t
98	缇ょ粍6260	\N	\N	149	2025-12-04 09:59:55.3485	2025-12-04 09:59:55.3485	\N	f	f	f	t
99	娴嬭瘯澶村儚	\N	\N	149	2025-12-04 15:04:16.123146	2025-12-04 15:04:16.123146	\N	f	f	f	t
139	缇ょ粍100	鍟婂晩鍟婂晩鍟婂晩鍟婂晩鍟婂晩鍟婂晩	\N	156	2025-12-08 14:02:20.946811	2025-12-08 14:02:20.946811	\N	f	f	f	t
92	缇ょ粍555	\N	\N	142	2025-12-01 22:21:48.72008	2025-12-02 19:54:38.380104	\N	f	t	f	t
93	缇ょ粍666	\N	\N	142	2025-12-02 22:41:46.773188	2025-12-02 22:41:46.773188	\N	f	f	f	t
94	缇ょ粍777	\N	\N	142	2025-12-02 23:34:02.63862	2025-12-02 23:34:02.63862	\N	f	f	f	t
97	ddddd	\N	\N	152	2025-12-03 23:40:33.674284	2025-12-05 11:08:02.69613	\N	f	f	f	t
140	缇ょ粍102	\N	\N	156	2025-12-08 14:11:57.433894	2025-12-08 14:11:57.433894	\N	f	f	f	t
100	1111111	\N	\N	109	2025-12-05 12:33:32.249346	2025-12-05 12:33:32.249346	\N	f	f	f	t
101	缇ょ粍906	\N	\N	155	2025-12-05 13:32:54.188572	2025-12-05 17:38:33.640927	\N	f	f	f	t
102	1111222	\N	\N	149	2025-12-06 00:13:25.676995	2025-12-06 00:13:25.676995	\N	f	f	f	t
103	ZZZ	\N	\N	149	2025-12-06 00:14:36.521999	2025-12-06 00:14:36.521999	\N	f	f	f	t
104	寮?\N	\N	149	2025-12-06 00:18:34.979058	2025-12-06 00:18:34.979058	\N	f	f	f	t
141	缇ょ粍10086	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765177457841933200_寰俊鍥剧墖_20251119085733_149_26.jpg	156	2025-12-08 15:04:25.103551	2025-12-08 15:04:25.103551	\N	f	f	f	t
142	缇ょ粍1009	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765177990744131700_ic_launcher.png	156	2025-12-08 15:13:16.232293	2025-12-08 15:13:16.232293	\N	f	f	f	t
143	缇ょ粍1010	111111	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765178470811222300_1762490101_3_k4vl6CdQ.jpg	156	2025-12-08 15:21:17.051863	2025-12-08 15:21:17.051863	\N	f	f	f	t
144	缇ょ粍10011	10111011	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765178770765131500_1762175910_5_daVpZIcT.jpg	156	2025-12-08 15:26:16.873479	2025-12-08 15:26:16.873479	\N	f	f	f	t
145	缇ょ粍1012	10121012	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765179579842204300_ic_launcher.png	156	2025-12-08 15:39:45.447974	2025-12-08 18:09:41.407189	\N	f	f	f	t
146	缇ょ粍1013	10131013	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765190436830214500_2.jpeg	156	2025-12-08 18:10:47.147084	2025-12-08 18:40:44.950144	\N	f	f	f	t
147	缇ょ粍1016	1016	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765190492855251200_ic_launcher.png	156	2025-12-08 18:41:38.395959	2025-12-08 18:41:38.395959	\N	f	f	f	t
148	1014	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765191462665777800_JPEG_20251203_221922_5447539638496536625.jpg	156	2025-12-08 18:53:27.649592	2025-12-08 18:57:51.730079	\N	f	f	f	t
149	1015	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765191564729190400_2.jpeg	156	2025-12-08 18:59:30.501819	2025-12-08 18:59:30.501819	\N	f	f	f	t
150	1017	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765191666901769800_1.jpeg	156	2025-12-08 19:01:12.136708	2025-12-08 19:01:12.136708	\N	f	f	f	t
151	1018	1111	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765191743596390000_ic_launcher.png	156	2025-12-08 19:02:29.388134	2025-12-08 19:02:29.388134	\N	f	f	f	t
152	1019	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765192019178583200_ic_launcher.png	156	2025-12-08 19:07:04.707009	2025-12-08 19:07:04.707009	\N	f	f	f	t
153	1020	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765192187809800900_ic_launcher.png	156	2025-12-08 19:09:53.203493	2025-12-08 19:09:53.203493	\N	f	f	f	t
154	1021	\N	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765192330794006200_ic_launcher.png	156	2025-12-08 19:12:16.456847	2025-12-08 19:12:16.456847	\N	f	f	f	t
155	1022	\N	\N	156	2025-12-08 19:13:40.719704	2025-12-08 19:13:40.719704	\N	f	f	f	t
156	1023	\N	\N	156	2025-12-08 19:19:43.451642	2025-12-08 19:19:43.451642	\N	f	f	f	t
157	1024	111	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/user/156/1765201215152843900_2.jpeg	156	2025-12-08 19:34:03.315357	2025-12-08 21:40:26.063243	\N	t	f	f	t
158	缇ょ粍浜岀淮鐮?	\N	\N	151	2025-12-09 11:53:07.274658	2025-12-09 11:53:07.274658	\N	f	f	f	t
159	2222222	\N	\N	158	2025-12-14 11:32:45.571141	2025-12-14 11:32:45.571141	\N	f	f	f	t
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, sender_id, receiver_id, content, message_type, is_read, created_at, read_at, sender_name, receiver_name, file_name, quoted_message_id, quoted_message_content, status, deleted_by_users, sender_avatar, receiver_avatar, call_type, server_id, voice_duration) FROM stdin;
3523	156	151	瀵规柟宸插彇娑?call_cancelled	t	2025-12-07 11:37:22.114172	2025-12-07 19:37:22.438342	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3460	149	151	111	text	t	2025-12-07 10:27:03.679283	2025-12-07 18:27:09.048998	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3461	149	151	22	text	t	2025-12-07 10:27:05.632854	2025-12-07 18:27:09.048998	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3462	149	151	333	text	t	2025-12-07 10:27:07.035033	2025-12-07 18:27:09.048998	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3463	151	149	44	text	t	2025-12-07 10:27:13.249713	2025-12-07 18:27:13.41161	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3561	156	102	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	f	2025-12-08 20:18:37.298411	\N	娴嬭瘯63	娴嬭瘯01-1	\N	\N	\N	normal				\N	\N	\N
3464	151	149	55	text	t	2025-12-07 10:27:14.88996	2025-12-07 18:27:15.025198	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3465	151	149	66	text	t	2025-12-07 10:27:17.187237	2025-12-07 18:27:17.360509	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3563	156	104	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	f	2025-12-08 20:18:39.660997	\N	娴嬭瘯63	娴嬭瘯03	\N	\N	\N	normal				\N	\N	\N
3466	149	151	4444444444444	quoted	t	2025-12-07 10:27:26.894262	2025-12-07 18:27:26.95068	娴嬭瘯60	寮犲皬鑾?\N	3463	44	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3467	149	151	2222222222222222222	text	t	2025-12-07 10:32:48.797821	2025-12-07 18:32:48.93912	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3468	149	151	666666666666	quoted	t	2025-12-07 10:32:56.966444	2025-12-07 18:32:57.099877	娴嬭瘯60	寮犲皬鑾?\N	3465	66	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3469	149	151	111	text	t	2025-12-07 10:33:10.766687	2025-12-07 18:33:10.887125	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3470	149	151	222	text	t	2025-12-07 10:33:12.662349	2025-12-07 18:33:12.726125	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3471	149	151	333	text	t	2025-12-07 10:33:13.93979	2025-12-07 18:33:14.119519	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3472	151	149	444	text	t	2025-12-07 10:33:18.84515	2025-12-07 18:33:18.993425	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3473	151	149	555	text	t	2025-12-07 10:33:20.522246	2025-12-07 18:33:20.66395	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3474	151	149	666	text	t	2025-12-07 10:33:22.385035	2025-12-07 18:33:22.52321	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3475	149	151	4444444444444	quoted	t	2025-12-07 10:33:29.435113	2025-12-07 18:33:29.576495	娴嬭瘯60	寮犲皬鑾?\N	3472	444	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3476	149	151	111	text	t	2025-12-07 10:39:12.440526	2025-12-07 18:39:16.813571	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3477	149	151	222	text	t	2025-12-07 10:39:13.713138	2025-12-07 18:39:16.813571	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3478	149	151	333	text	t	2025-12-07 10:39:14.598158	2025-12-07 18:39:16.813571	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3479	151	149	444	text	t	2025-12-07 10:39:22.77825	2025-12-07 18:39:22.928629	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3480	151	149	555	text	t	2025-12-07 10:39:26.291749	2025-12-07 18:39:26.456209	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3481	149	151	4444444444444	quoted	t	2025-12-07 10:39:38.702207	2025-12-07 18:39:38.844134	娴嬭瘯60	寮犲皬鑾?\N	3479	444	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3482	149	151	555	text	t	2025-12-07 10:46:18.746184	2025-12-07 18:46:23.478725	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3483	149	151	666	text	t	2025-12-07 10:46:21.156608	2025-12-07 18:46:23.478725	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3484	151	149	77	text	t	2025-12-07 10:46:29.408956	2025-12-07 18:46:29.560414	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3524	156	151	00:06	call_ended	t	2025-12-07 11:40:10.309422	2025-12-07 19:42:25.534968	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	voice	\N	\N
3485	151	149	88	text	t	2025-12-07 10:46:31.278938	2025-12-07 18:46:31.439354	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3525	156	151	111	text	t	2025-12-07 11:42:22.572882	2025-12-07 19:42:25.534968	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3486	149	151	777777777777	quoted	t	2025-12-07 10:46:42.523844	2025-12-07 18:46:42.701139	娴嬭瘯60	寮犲皬鑾?\N	3484	77	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3526	151	156	222	text	t	2025-12-07 11:42:32.940639	2025-12-07 19:42:33.149767	寮犲皬鑾?娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3487	149	151	11	text	t	2025-12-07 10:51:54.731695	2025-12-07 18:51:57.821349	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3488	149	151	22	text	t	2025-12-07 10:51:55.74095	2025-12-07 18:51:57.821349	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3489	151	149	33	text	t	2025-12-07 10:52:03.365772	2025-12-07 18:52:03.561864	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3490	151	149	44	text	t	2025-12-07 10:52:05.110886	2025-12-07 18:52:05.290957	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3491	149	151	222222222222222222	quoted	t	2025-12-07 10:57:31.921238	2025-12-07 18:57:35.978346	娴嬭瘯60	寮犲皬鑾?\N	3488	22	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3492	149	151	111111111111111	quoted	t	2025-12-07 10:57:46.550306	2025-12-07 18:57:46.668746	娴嬭瘯60	寮犲皬鑾?\N	3487	11	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3493	149	151	4444444444444444	quoted	t	2025-12-07 10:57:53.345119	2025-12-07 18:57:53.692729	娴嬭瘯60	寮犲皬鑾?\N	3490	44	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3494	151	149	22222	quoted	t	2025-12-07 10:58:08.10056	2025-12-07 18:58:08.335003	寮犲皬鑾?娴嬭瘯60	\N	29	22	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3495	151	149	33333	quoted	t	2025-12-07 10:58:24.671802	2025-12-07 18:58:24.811421	寮犲皬鑾?娴嬭瘯60	\N	30	33	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3498	151	156	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-07 19:01:48.886558	2025-12-07 19:01:51.268774	寮犲皬鑾?娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3499	156	151	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-07 19:01:48.888202	2025-12-07 19:02:38.069905	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3500	156	151	333	text	t	2025-12-07 11:01:52.782016	2025-12-07 19:02:38.069905	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3501	156	151	444	text	t	2025-12-07 11:01:54.046795	2025-12-07 19:02:38.069905	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3496	150	151	111	text	t	2025-12-07 11:00:57.132578	2025-12-07 19:02:40.452583	娴嬭瘯61	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3497	150	151	222	text	t	2025-12-07 11:00:58.088498	2025-12-07 19:02:40.452583	娴嬭瘯61	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3503	150	151	3333	text	t	2025-12-07 11:04:29.213695	2025-12-07 19:20:07.133787	娴嬭瘯61	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3504	150	151	444	text	t	2025-12-07 11:10:20.873771	2025-12-07 19:20:07.133787	娴嬭瘯61	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3506	150	151	8888	text	t	2025-12-07 11:11:12.735423	2025-12-07 19:20:07.133787	娴嬭瘯61	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3505	149	151	55555	text	t	2025-12-07 11:10:52.956202	2025-12-07 19:20:10.021568	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3614	159	158	99999	text	t	2025-12-14 05:27:43.700472	2025-12-14 13:27:43.976916	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3502	156	151	111	text	t	2025-12-07 11:03:06.579124	2025-12-07 19:19:59.864084	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3507	156	151	9999	text	t	2025-12-07 11:11:34.100453	2025-12-07 19:19:59.864084	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3508	156	151	000	text	t	2025-12-07 11:14:03.648392	2025-12-07 19:19:59.864084	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3509	156	151	111	text	t	2025-12-07 11:18:49.12191	2025-12-07 19:19:59.864084	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3510	156	151	22	text	t	2025-12-07 11:19:13.781417	2025-12-07 19:19:59.864084	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3527	156	151	00:10	call_ended_video	t	2025-12-07 11:45:23.074898	2025-12-07 19:48:18.366643	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	video	\N	\N
3528	156	151	00:04	call_ended_video	t	2025-12-07 11:46:08.80321	2025-12-07 19:48:18.366643	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	video	\N	\N
3529	156	151	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765108084_寰俊鍥剧墖_20251204153623_232_26.jpg	image	t	2025-12-07 11:48:08.996929	2025-12-07 19:48:18.366643	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3511	156	151	333	text	t	2025-12-07 11:20:27.696702	2025-12-07 19:27:28.536326	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3512	156	151	444	text	t	2025-12-07 11:21:21.706506	2025-12-07 19:27:28.536326	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3513	156	151	55	text	t	2025-12-07 11:22:45.670889	2025-12-07 19:27:28.536326	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3514	156	151	666	text	t	2025-12-07 11:26:22.423358	2025-12-07 19:27:28.536326	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3530	156	151	00:03	call_ended_video	t	2025-12-07 11:55:29.098591	2025-12-07 19:55:29.372975	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	video	\N	\N
3515	156	151	777	text	t	2025-12-07 11:31:25.636487	2025-12-07 19:35:17.101423	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3516	156	151	888	text	t	2025-12-07 11:34:44.127639	2025-12-07 19:35:17.101423	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3517	151	156	1	text	t	2025-12-07 11:35:24.165233	2025-12-07 19:35:24.318171	寮犲皬鑾?娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3531	156	151	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765109836_寰俊鍥剧墖_20251204153623_232_26.jpg	image	t	2025-12-07 12:17:21.049981	2025-12-07 20:17:25.239548	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3518	151	156	1	text	t	2025-12-07 11:35:25.844434	2025-12-07 19:35:25.979095	寮犲皬鑾?娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3519	151	156	2	text	t	2025-12-07 11:35:29.83237	2025-12-07 19:35:29.971587	寮犲皬鑾?娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3532	156	151	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/user/156/1765110080649997600_2637-161442811_tiny.mp4	video	t	2025-12-07 12:21:52.327071	2025-12-07 20:21:52.463578	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3520	151	156	2	text	t	2025-12-07 11:35:31.754061	2025-12-07 19:35:31.921669	寮犲皬鑾?娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3533	150	151	11	text	t	2025-12-07 13:04:52.528302	2025-12-07 21:04:52.680971	娴嬭瘯61	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3521	151	156	2	text	t	2025-12-07 11:35:35.602524	2025-12-07 19:35:35.738844	寮犲皬鑾?娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3522	156	151	00:35	call_ended	t	2025-12-07 11:36:33.355048	2025-12-07 19:36:33.485913	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	voice	\N	\N
3534	151	150	yyyt	text	t	2025-12-07 13:13:26.369705	2025-12-07 21:13:26.559235	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3535	151	150	1111	text	t	2025-12-07 14:07:30.713817	2025-12-07 22:07:30.858815	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3536	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765116644996389100_voice_1765116639961.m4a	voice	t	2025-12-07 14:10:49.874684	2025-12-07 22:10:50.011802	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3537	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765116794073696100_voice_1765116789848.m4a	voice	t	2025-12-07 14:13:17.552286	2025-12-07 22:13:17.690461	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3538	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765116864639249000_voice_1765116860657.m4a	voice	t	2025-12-07 14:14:28.330936	2025-12-07 22:14:28.491648	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3539	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765117221560282600_voice_1765117216819.m4a	voice	t	2025-12-07 14:20:24.783089	2025-12-07 22:20:24.950429	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3540	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765117690536374300_voice_1765117686892.m4a	voice	t	2025-12-07 14:28:13.739572	2025-12-07 22:28:13.898673	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3615	159	158	1111	text	t	2025-12-14 05:29:41.774224	2025-12-14 13:30:13.310538	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	normal				\N	\N	\N
3541	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765117828240937900_voice_1765117824313.m4a	voice	t	2025-12-07 14:30:38.114626	2025-12-07 22:30:38.252503	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3542	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765117880552037900_voice_1765117876771.m4a	voice	t	2025-12-07 14:31:25.246666	2025-12-07 22:31:25.383065	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3543	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765119635962792600_voice_1765119632958.m4a	voice	t	2025-12-07 15:00:41.082398	2025-12-07 23:00:41.247955	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3616	159	158	2222	text	t	2025-12-14 05:30:18.575894	2025-12-14 13:30:18.724831	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3544	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765119717077859100_voice_1765119713407.m4a	voice	t	2025-12-07 15:02:00.194661	2025-12-07 23:02:00.347079	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3545	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765120582923918200_voice_1765120579269.m4a	voice	t	2025-12-07 15:16:25.971312	2025-12-07 23:16:26.075792	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	3
3546	150	151	11	text	t	2025-12-08 04:45:19.482915	2025-12-08 12:45:25.421374	娴嬭瘯61	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3547	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765169628890034600_voice_1765169623083.m4a	voice	t	2025-12-08 04:53:52.104213	2025-12-08 12:53:52.474812	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	4
3617	159	158	333	text	t	2025-12-14 05:31:47.812883	2025-12-14 13:33:56.58711	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3548	151	150	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765169670594476000_voice_1765169666888.m4a	voice	t	2025-12-08 04:54:33.672321	2025-12-08 12:54:33.862613	寮犲皬鑾?娴嬭瘯61	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	3
3549	149	151	33	text	t	2025-12-08 04:55:19.199394	2025-12-08 12:55:21.58036	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3618	159	158	22222	text	t	2025-12-14 05:33:52.37471	2025-12-14 13:33:56.58711	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3550	151	149	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765169728303793000_voice_1765169724307.m4a	voice	t	2025-12-08 04:55:31.040322	2025-12-08 12:55:31.42845	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	3
3551	149	151	33	text	t	2025-12-08 05:07:55.369788	2025-12-08 13:07:57.875684	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3552	151	149	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765170483753573100_voice_1765170480038.m4a	voice	t	2025-12-08 05:08:06.835221	2025-12-08 13:08:07.100417	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	2
3619	159	158	444	text	t	2025-12-14 05:34:21.038545	2025-12-14 13:34:21.198351	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3553	156	151	11	text	t	2025-12-08 05:08:45.638241	2025-12-08 13:08:48.931522	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3554	151	156	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765170533894201400_voice_1765170530396.m4a	voice	t	2025-12-08 05:08:57.125859	2025-12-08 13:08:57.477592	寮犲皬鑾?娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	2
3555	156	151	11	text	t	2025-12-08 05:14:17.805055	2025-12-08 13:14:21.190198	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3620	158	159	5555	text	t	2025-12-14 05:36:11.140112	2025-12-14 13:36:11.307032	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	娴嬭瘯74	\N	\N	\N	recalled				\N	\N	\N
3556	156	151	00:02	call_ended	t	2025-12-08 05:14:32.983596	2025-12-08 13:14:33.051494	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	voice	\N	\N
3557	151	156	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/voice/user/151/1765170923275879000_voice_1765170919681.m4a	voice	t	2025-12-08 05:15:26.148542	2025-12-08 13:15:26.422897	寮犲皬鑾?娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	2
3621	149	151	22	text	t	2025-12-14 09:12:31.879015	2025-12-14 17:12:35.866096	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3559	149	156	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-08 19:54:52.829639	2025-12-08 20:01:01.206818	娴嬭瘯60	娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg		\N	\N	\N
3558	156	151	11	text	t	2025-12-08 10:51:09.480535	2025-12-09 10:00:24.645452	娴嬭瘯63	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3560	156	149	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-08 19:54:52.833383	2025-12-09 11:00:28.538192	娴嬭瘯63	娴嬭瘯60	\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3564	104	156	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	f	2025-12-08 20:18:39.663064	\N	娴嬭瘯03	娴嬭瘯63	\N	\N	\N	normal				\N	\N	\N
3565	156	105	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	f	2025-12-08 20:18:41.838542	\N	娴嬭瘯63	娴嬭瘯04	\N	\N	\N	normal				\N	\N	\N
3566	105	156	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	f	2025-12-08 20:18:41.840095	\N	娴嬭瘯04	娴嬭瘯63	\N	\N	\N	normal				\N	\N	\N
3569	156	103	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	f	2025-12-08 20:18:46.621822	\N	娴嬭瘯63	娴嬭瘯2	\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129327_JPEG_20251126_115527_5144140681260080541.jpg	\N	\N	\N
3570	103	156	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-08 20:18:46.62811	2025-12-08 20:24:18.072084	娴嬭瘯2	娴嬭瘯63	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129327_JPEG_20251126_115527_5144140681260080541.jpg		\N	\N	\N
3562	102	156	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-08 20:18:37.333357	2025-12-08 20:33:15.032179	娴嬭瘯01-1	娴嬭瘯63	\N	\N	\N	normal				\N	\N	\N
3568	106	156	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-08 20:18:44.263178	2025-12-08 21:13:16.89014	娴嬭瘯05	娴嬭瘯63	\N	\N	\N	normal				\N	\N	\N
3567	156	106	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-08 20:18:44.260689	2025-12-08 21:39:18.015133	娴嬭瘯63	娴嬭瘯05	\N	\N	\N	normal				\N	\N	\N
3571	151	137	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-09 10:01:09.185924	2025-12-09 10:01:12.269191	寮犲皬鑾?娴嬭瘯1007	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764419801_ic_launcher.png	\N	\N	\N
3572	137	151	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-09 10:01:09.192964	2025-12-09 10:01:18.767134	娴嬭瘯1007	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764419801_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3573	157	151	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-09 11:31:00.133691	2025-12-09 11:31:19.812742	ceshi70	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3574	151	157	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-09 11:31:00.136748	2025-12-09 12:00:23.747451	寮犲皬鑾?ceshi70	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3575	151	149	00:04	call_ended	t	2025-12-10 10:59:12.659098	2025-12-10 18:59:12.77394	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	voice	\N	\N
3576	151	149	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765365070_寰俊鍥剧墖_20251204153623_232_26.jpg	image	t	2025-12-10 11:11:11.601026	2025-12-10 19:11:18.028083	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3577	151	149	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765366234_ic_launcher.png	image	t	2025-12-10 11:30:34.938209	2025-12-10 19:30:39.532644	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3578	151	149	11	text	t	2025-12-10 11:44:09.764645	2025-12-10 19:44:20.090728	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3579	151	149	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765367056_ic_launcher.png	image	t	2025-12-10 11:44:17.677844	2025-12-10 19:44:20.090728	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3580	151	149	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765367589_1762490101_3_k4vl6CdQ.jpg	image	t	2025-12-10 11:53:09.724584	2025-12-10 19:53:56.622685	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3581	151	149	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765368903_VirtualBox_win11_08_11_2025_17_26_33.png	image	t	2025-12-10 12:15:05.578521	2025-12-10 20:15:05.79972	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3582	151	149	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765369392_ic_launcher.png	image	t	2025-12-10 12:23:12.756361	2025-12-10 20:23:12.941173	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3583	151	149	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1765369885_1.jpeg	image	t	2025-12-10 12:31:26.604656	2025-12-10 20:31:26.718829	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3584	151	149	111	text	t	2025-12-12 10:33:04.269552	2025-12-13 18:04:56.226661	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3586	151	158	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	f	2025-12-14 11:31:23.428616	\N	寮犲皬鑾?ceshi73cdshi73	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3585	158	151	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-14 11:31:23.422633	2025-12-14 11:32:18.630969	ceshi73cdshi73	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3587	158	151	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-14 11:31:25.085372	2025-12-14 11:32:18.630969	ceshi73cdshi73	寮犲皬鑾?\N	\N	\N	normal			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3593	158	159	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-14 11:55:55.953641	2025-12-14 11:56:01.893046	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	娴嬭瘯74	\N	\N	\N	normal				\N	\N	\N
3592	159	158	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-14 11:55:55.952099	2025-12-14 11:59:41.083666	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	normal				\N	\N	\N
3588	151	158	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	f	2025-12-14 11:31:25.0904	\N	寮犲皬鑾?ceshi73cdshi73	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg		\N	\N	\N
3622	151	149	33	text	t	2025-12-14 09:13:10.543205	2025-12-14 17:13:10.707949	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3589	158	150	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-14 11:46:43.231457	2025-12-14 11:46:52.710779	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	娴嬭瘯61	\N	\N	\N	normal				\N	\N	\N
3623	149	151	44	text	t	2025-12-14 09:13:15.966353	2025-12-14 17:13:16.141402	娴嬭瘯60	寮犲皬鑾?\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	\N	\N	\N
3590	150	158	璇锋眰娣诲姞濂藉弸銆愬凡閫氳繃銆?text	t	2025-12-14 11:46:43.234613	2025-12-14 11:56:35.074322	娴嬭瘯61	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	normal				\N	\N	\N
3591	150	158	1111	text	t	2025-12-14 03:46:56.656828	2025-12-14 11:56:35.074322	娴嬭瘯61	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	normal				\N	\N	\N
3594	159	158	111	text	t	2025-12-14 03:56:08.22383	2025-12-14 11:59:41.083666	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	normal				\N	\N	\N
3624	151	149	55	text	t	2025-12-14 09:13:20.980423	2025-12-14 17:13:21.135412	寮犲皬鑾?娴嬭瘯60	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	\N	\N	\N
3597	159	158	444	text	t	2025-12-14 04:11:50.493158	2025-12-14 12:11:50.81287	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	normal				\N	\N	\N
3598	158	159	555	text	t	2025-12-14 04:12:23.870528	2025-12-14 12:12:24.018903	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	娴嬭瘯74	\N	\N	\N	normal				\N	\N	\N
3595	159	158	222	text	t	2025-12-14 03:59:41.012521	2025-12-14 11:59:41.083666	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	normal				\N	\N	\N
3596	158	159	333	text	t	2025-12-14 04:00:19.130101	2025-12-14 12:00:21.804588	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	娴嬭瘯74	\N	\N	\N	normal				\N	\N	\N
3599	158	159	66666	text	t	2025-12-14 04:38:31.839524	2025-12-14 12:38:32.139146	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	娴嬭瘯74	\N	\N	\N	normal				\N	\N	\N
3600	159	158	77777	text	t	2025-12-14 04:41:13.935566	2025-12-14 12:41:18.726784	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	normal				\N	\N	\N
3601	158	159	8888	text	t	2025-12-14 05:01:35.979869	2025-12-14 13:01:36.259282	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	娴嬭瘯74	\N	\N	\N	recalled				\N	\N	\N
3602	159	158	999	text	t	2025-12-14 05:02:56.425047	2025-12-14 13:02:56.628602	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3603	159	158	00000	text	t	2025-12-14 05:03:21.746106	2025-12-14 13:03:21.957485	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3604	159	158	999	text	t	2025-12-14 05:11:52.159951	2025-12-14 13:11:52.389503	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3605	159	158	11111	text	t	2025-12-14 05:13:04.922707	2025-12-14 13:13:05.09243	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3606	159	158	2222	text	t	2025-12-14 05:13:26.097689	2025-12-14 13:13:26.297709	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3607	159	158	444	text	t	2025-12-14 05:17:22.646854	2025-12-14 13:17:22.920256	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3608	159	158	5555	text	t	2025-12-14 05:19:40.046942	2025-12-14 13:19:40.32759	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	normal				\N	\N	\N
3609	159	158	666	text	t	2025-12-14 05:20:14.696633	2025-12-14 13:20:14.881233	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3610	159	158	66666	text	t	2025-12-14 05:23:15.291572	2025-12-14 13:23:20.802856	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3611	159	158	88888	text	t	2025-12-14 05:23:48.817766	2025-12-14 13:23:49.029545	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3612	159	158	999	text	t	2025-12-14 05:24:35.669789	2025-12-14 13:24:35.793617	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
3613	159	158	3333	text	t	2025-12-14 05:24:59.470094	2025-12-14 13:24:59.65647	娴嬭瘯74	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	\N	\N	\N	recalled				\N	\N	\N
\.


--
-- Data for Name: server_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.server_settings (id, key, value, description, updated_at) FROM stdin;
\.


--
-- Data for Name: user_relations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_relations (id, user_id, friend_id, created_at, approval_status, is_blocked, is_deleted, blocked_by_user_id, deleted_by_user_id) FROM stdin;
156	106	107	2025-11-29 11:32:18.736574	approved	f	f	\N	\N
157	132	102	2025-11-29 13:48:03.027555	pending	f	f	\N	\N
136	106	119	2025-11-27 02:27:39.315372	approved	t	f	119	\N
226	152	151	2025-12-04 13:29:48.556709	approved	t	f	152	\N
160	107	135	2025-11-29 15:02:10.209943	pending	f	f	\N	\N
158	135	102	2025-11-29 14:56:09.756753	approved	f	f	\N	\N
161	137	102	2025-11-29 15:44:26.55094	approved	f	f	\N	\N
227	109	151	2025-12-05 12:32:16.273587	approved	f	f	\N	\N
228	155	154	2025-12-05 13:32:29.476716	approved	f	f	\N	\N
163	102	114	2025-11-30 09:33:42.494699	approved	f	f	\N	\N
164	114	102	2025-11-30 10:29:48.452796	approved	f	f	\N	\N
229	155	151	2025-12-05 16:46:55.828475	approved	f	f	\N	\N
230	151	150	2025-12-06 19:44:21.32483	approved	f	f	\N	\N
166	113	114	2025-11-30 11:30:12.612444	approved	f	f	\N	\N
127	107	114	2025-11-26 07:57:48.987097	approved	f	f	\N	\N
126	106	114	2025-11-26 07:50:43.137135	approved	f	f	\N	\N
125	105	114	2025-11-26 07:50:11.61794	approved	f	f	\N	\N
124	104	114	2025-11-26 07:46:28.257045	approved	f	f	\N	\N
123	103	114	2025-11-26 07:39:06.583251	approved	f	f	\N	\N
128	114	108	2025-11-26 08:05:40.624679	pending	f	f	\N	\N
165	137	114	2025-11-30 10:30:42.472435	approved	t	f	137	\N
129	114	109	2025-11-26 08:18:32.491231	approved	f	f	\N	\N
130	103	113	2025-11-26 10:37:02.805426	approved	f	f	\N	\N
131	113	104	2025-11-26 10:52:16.870739	approved	f	f	\N	\N
132	109	102	2025-11-27 00:51:45.715457	rejected	f	f	\N	\N
233	102	156	2025-12-08 20:16:42.511547	approved	f	f	\N	\N
133	110	102	2025-11-27 00:52:44.901691	rejected	f	f	\N	\N
201	142	143	2025-12-01 22:21:22.048773	approved	f	f	\N	\N
235	104	156	2025-12-08 20:17:37.418142	approved	f	f	\N	\N
134	102	115	2025-11-27 00:53:41.087956	approved	f	f	\N	\N
236	105	156	2025-12-08 20:18:04.661525	approved	f	f	\N	\N
135	118	109	2025-11-27 01:22:41.716247	approved	f	f	\N	\N
234	103	156	2025-12-08 20:17:12.575435	approved	f	f	\N	\N
231	156	151	2025-12-07 19:01:41.896926	approved	t	f	156	\N
138	121	120	2025-11-27 02:30:38.8799	pending	f	f	\N	\N
204	144	142	2025-12-02 19:20:07.854093	approved	f	f	\N	\N
203	144	143	2025-12-02 19:20:01.409951	approved	f	f	\N	\N
140	121	114	2025-11-27 02:41:29.653459	approved	f	f	\N	\N
141	126	125	2025-11-27 14:49:17.035834	approved	f	f	\N	\N
181	120	119	2025-11-30 14:18:50.123874	approved	f	f	\N	\N
142	102	127	2025-11-27 18:25:10.56662	rejected	f	f	\N	\N
205	145	144	2025-12-03 15:21:14.071811	approved	f	f	\N	\N
232	156	149	2025-12-08 19:54:39.863118	approved	f	f	\N	\N
143	127	102	2025-11-27 18:25:48.099488	rejected	f	f	\N	\N
139	122	120	2025-11-27 02:32:44.038465	approved	f	f	\N	\N
206	145	146	2025-12-03 15:32:29.084665	approved	f	f	\N	\N
237	106	156	2025-12-08 20:18:32.95299	approved	t	f	156	\N
207	146	147	2025-12-03 20:30:16.740677	approved	f	f	\N	\N
238	137	151	2025-12-09 10:01:02.59705	approved	f	f	\N	\N
185	122	112	2025-11-30 15:51:59.776142	approved	f	f	\N	\N
145	103	127	2025-11-27 18:45:55.708968	approved	f	f	\N	\N
239	151	157	2025-12-09 11:30:48.364008	approved	f	f	\N	\N
187	113	112	2025-12-01 08:58:27.952371	approved	f	f	\N	\N
146	127	104	2025-11-27 19:24:48.962289	approved	f	f	\N	\N
188	113	138	2025-12-01 14:34:44.14693	approved	f	f	\N	\N
240	151	158	2025-12-14 11:31:05.049912	approved	f	f	\N	\N
189	112	114	2025-12-01 17:39:36.599066	approved	f	f	\N	\N
190	119	114	2025-12-01 17:48:19.322995	pending	f	f	\N	\N
148	127	105	2025-11-27 19:35:18.287913	approved	f	f	\N	\N
149	103	102	2025-11-28 13:49:47.615214	pending	f	f	\N	\N
211	148	149	2025-12-03 22:41:13.253787	approved	f	f	\N	\N
150	129	128	2025-11-28 14:02:24.923537	approved	f	f	\N	\N
151	114	129	2025-11-28 15:25:17.139775	approved	f	f	\N	\N
241	150	158	2025-12-14 11:46:20.369628	approved	f	f	\N	\N
152	113	129	2025-11-28 15:27:28.401013	approved	f	f	\N	\N
153	113	128	2025-11-28 15:43:58.168493	approved	f	f	\N	\N
213	150	149	2025-12-03 22:44:25.28567	approved	f	f	\N	\N
154	130	128	2025-11-28 15:45:15.8701	approved	f	f	\N	\N
192	119	112	2025-12-01 19:15:08.795345	approved	f	f	\N	\N
155	131	128	2025-11-28 15:46:20.851148	approved	f	f	\N	\N
242	158	159	2025-12-14 11:55:47.287627	approved	f	f	\N	\N
194	121	112	2025-12-01 19:24:15.308201	approved	f	f	\N	\N
195	139	112	2025-12-01 19:27:01.774763	approved	f	f	\N	\N
216	148	150	2025-12-03 22:54:32.489855	approved	f	f	\N	\N
196	140	112	2025-12-01 19:32:05.346136	approved	t	f	112	\N
223	152	150	2025-12-03 23:25:50.920633	approved	f	f	\N	\N
225	149	151	2025-12-03 23:50:05.260962	approved	f	f	\N	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, password, phone, email, avatar, created_at, updated_at, auth_code, full_name, gender, work_signature, status, landline, short_number, department, "position", region, invite_code, invited_by_code) FROM stdin;
118	test13	$2a$10$2moaBpw2Hp4r6DFHvGUhwuZPzlzpepRs..KSBdSncr3X8UJOOqnvO	\N	\N		2025-11-27 01:06:24.844315	2025-11-27 01:25:19.384106	\N	娴嬭瘯13	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
110	test09	$2a$10$1rrVDyQSoXiISY1ElZOQRO5dRCPPzFDiwtwp6ra0xI2UYzrd0zHMK	\N	\N		2025-11-25 13:02:50.353647	2025-11-27 02:17:53.067781	\N	娴嬭瘯09	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
102	test01	$2a$10$y.M5Avb0FHVgydjPs.8jL.rWFpTQpnm71kLBzHn37o8sB..HFtLf.				2025-11-24 15:13:50.435812	2025-12-08 20:16:47.491344	\N	娴嬭瘯01-1	male	\N	offline						666666	\N
130	test803	$2a$10$6NzvRNvZAvuvaRGmq5aC1.qwimqYmLOC9t1w0ks4TlvXgNi0MO.G.	\N	\N		2025-11-28 15:44:50.582194	2025-11-28 15:45:32.310323	\N	娴嬭瘯803	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
109	test08	$2a$10$F2bLFd0ymS2Z49VUu4ORnuPhwYYD6F557ux1Armlug.RgE0D5g/l6	\N	\N		2025-11-25 12:47:11.273864	2025-12-05 13:27:37.464114	\N	娴嬭瘯08	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
128	test800	$2a$10$S/7mEZZ4INlEjO4xfVgvnOF61VQRHOfb4JhSCxjDndOrTwrz8rv7W	\N	\N		2025-11-28 14:00:14.979405	2025-11-29 08:55:56.576997	\N	娴嬭瘯800	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
105	test04	$2a$10$Fm3Q5vPVgXwYZwVI4iqG7.QUSXtXQ2FxUlehsmypbh6NzvtP3dEiO	\N	\N		2025-11-24 22:21:53.621795	2025-12-08 20:18:11.098592	\N	娴嬭瘯04	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
117	test12	$2a$10$lk2FX8wUA.2c795GsjcJuOFeH8tXIPk6sqVfQW0zIetGEk1pFVerq	\N	\N		2025-11-27 01:00:03.46034	2025-11-27 02:20:27.87653	\N	娴嬭瘯12	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
127	test35	$2a$10$1va7Pp0QeefWntb7JLOMhenwZl2g3tdUFhgt3FfutmTVc3F0JR.w.	\N	\N		2025-11-27 15:24:46.61842	2025-11-28 15:24:12.215969	\N	娴嬭瘯35	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
119	test24	$2a$10$pHozcdcXYEs8x9m426wJOu4qPTwd2JRLrLA5d.IAQ.YOQAtRf5rFC	\N	\N		2025-11-27 02:27:19.465455	2025-12-01 19:14:28.983658	\N	娴嬭瘯24	\N	\N	online	\N	\N	\N	\N	\N	\N	\N
129	test801	$2a$10$vQ8ityAIX92rRTRJ.0S3iepuT.7LAg2vQ64Ib.hDDUtIU2ZQnDkQi	\N	\N		2025-11-28 14:01:53.298041	2025-11-28 18:12:43.562706	\N	娴嬭瘯801	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
120	test25	$2a$10$Dxd3A9uEb9dpjo1eyY0mbeWaLZeWaHC8/hZ.UHi9CEejP4JalEPc.	\N	\N		2025-11-27 02:28:30.547305	2025-12-01 19:23:54.509423	\N	娴嬭瘯25	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
123	test101	$2a$10$cPb6eh3G4jPH1xX/FD.lRed0QSqdSUslMbAl2BuGXENx20m8EaZ06	\N	\N		2025-11-27 09:35:22.57967	2025-11-27 14:34:52.478079	\N	娴嬭瘯101	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
133	test1002	$2a$10$QRmEOrVSPJAOHhuV3t4Yl.j0jX5EWmSvwn9HQGLnagMydzJypIo6y	\N	\N		2025-11-29 14:16:00.849698	2025-11-29 14:16:29.266797	\N	娴嬭瘯1002	\N	\N	offline	\N	\N	\N	\N	\N	98oCmo	666666
124	test32	$2a$10$6UHHu6.hS.RfPF8w81vfL.ymKVp5S37mrfPVdIYV9ed5HF6g66k3u	\N	\N		2025-11-27 14:37:35.48391	2025-11-27 14:39:20.381119	\N	娴嬭瘯32	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
131	test804	$2a$10$KUu/L5Xi4cYvjWH5qje6R.yU79BPySO6YZl0VEAAwhB0OtH.zRTsi	\N	\N		2025-11-28 15:46:02.124319	2025-11-28 15:47:12.547361	\N	娴嬭瘯804	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
115	test10	$2a$10$w2C8UUAVVkl8pQSnE0Ffaut.ZCTS99o7dqhiPFoP1cl788295NW4m	\N	\N		2025-11-27 00:53:26.379921	2025-11-27 00:59:48.098491	\N	娴嬭瘯10	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
135	test1004	$2a$10$BN.TQW3wXcj1mt0mYvCDGu7ZUcerYFx8xbqSrAJM6Ga1kd3xhdRqa			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764401653_JPEG_20251129_153413_3544307309155669124.jpg	2025-11-29 14:51:57.669465	2025-11-29 15:42:27.742858	\N	nicke_test1004	male	\N	offline						Fdx0xt	666666
111	test20	$2a$10$.G9/nBcXlJcoNIM6m61Ohu5BRWvvX0zZsH5vr4og9zVJDLM46OwNG	\N	\N		2025-11-25 13:19:01.898295	2025-11-25 13:37:12.280903	\N	娴嬭瘯20	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
114	test23	$2a$10$GpkCQkQ4ra.Pv73rwAiYTuB/sz6Q5b2Vl34GBseFrAj1/jnQg2r4u			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764478797_JPEG_20251130_125957_5525954661892720756.jpg	2025-11-25 17:56:40.890524	2025-12-01 19:01:05.852382	\N	娴嬭瘯23	male	\N	offline						\N	\N
108	test07	$2a$10$yJCg/1THxS0reCHZuSmw0u4I15gQbBSrf50uTxeukvUWkUE2N4KIK	\N	\N		2025-11-25 12:33:05.712664	2025-11-26 08:10:41.957336	\N	娴嬭瘯07	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
116	test11	$2a$10$awiN20jEuiaXCeApn.BaUupwLlKZU/3/G2nv4IF9AJ5KZRnpokprq	\N	\N		2025-11-27 00:59:23.491943	2025-11-27 01:20:26.319321	\N	娴嬭瘯11	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
107	test06	$2a$10$.KpWdHmmFNCIj/pMEH5BwuxShNCcz6TjXiEUiO8Eja1g/X23elPCu			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764400705_JPEG_20251129_151826_6100304245017200604.jpg	2025-11-25 11:58:13.736898	2025-11-29 15:20:02.208599	\N	娴嬭瘯06	male	\N	offline	\N	\N				\N	\N
137	test1007	$2a$10$xcCM0cPFQIqi6uXavu.qCevHJCGiJ7XoLARZlsbZQ3VEgcOD2zyDC	13662257518	wq0426@163.com	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764419801_ic_launcher.png	2025-11-29 15:43:59.870971	2025-12-09 10:12:42.619402	\N	娴嬭瘯1007	male	\N	offline			333	444	555	dMfdBZ	666666
136	test1005	$2a$10$lEnV7ZYEGBLqh.48esY/3O6uUZ6ztRiX4oN9Uhu1eUzNPtU1jBjpK	\N	\N		2025-11-29 15:43:04.855573	2025-11-29 15:43:04.855573	\N	ceshi1005	\N	\N	offline	\N	\N	\N	\N	\N	q9cMMK	666666
103	test02	$2a$10$PrenWrXII9B6hC6nqFy9vuOytj6uwOMQr1wmSHG3buVhIKsJ7x8me			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129327_JPEG_20251126_115527_5144140681260080541.jpg	2025-11-24 15:17:23.407595	2025-12-08 20:17:19.792067	\N	娴嬭瘯2	male	\N	offline	\N	\N				\N	\N
126	test34	$2a$10$18K8YFboa7b4QcudhvGVl.BAN0JIKLdhSG1XzahyCAJGNEnDl//mC	\N	\N		2025-11-27 14:49:01.486991	2025-11-27 14:50:55.757519	\N	娴嬭瘯34	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
106	test05	$2a$10$kn7TCvq3qQTaf8RaURSgauc6k9QRCE6.JWPwmPMw.1JiPa1ZrAcLm	\N	\N		2025-11-25 09:22:55.250863	2025-12-08 22:58:19.152432	\N	娴嬭瘯05	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
122	test27	$2a$10$4QKnJZh7TDn8Gml9Bx/o8.qOKgnjKbjPT3MtNgCZhb4RbFWB4y2XC	13662257519	aa@qq.com		2025-11-27 02:32:00.097862	2025-12-01 19:25:24.810467	\N	娴嬭瘯27娴嬭瘯27娴嬭瘯27娴嬭瘯27娴嬭瘯27娴嬭瘯27娴嬭瘯27娴嬭瘯27娴嬭瘯27娴嬭瘯27娴嬭瘯27娴嬭瘯27娴嬭瘯27	male	\N	offline	10086	100	666	77	88	\N	\N
125	test33	$2a$10$T.jegh.i6rPbzA29ljooE.pRHaljU3HB7fWWK0Q6P/MalMYP9jlsK	\N	\N		2025-11-27 14:48:18.168656	2025-11-27 14:52:24.988113	\N	娴嬭瘯33	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
104	test03	$2a$10$kByMCMm.Y47JpqWpOV9NG.WE0fuSLy2b5focqkbqSdcnF0lW9zGe.	\N	\N		2025-11-24 17:36:14.534498	2025-12-08 20:17:43.475017	\N	娴嬭瘯03	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
134	test1003	$2a$10$taHTnBOGB6VCraDP7BgDaeMiIutIFdSQPbmDwJKtSE2TmPS1XBCYu	\N	\N		2025-11-29 14:16:46.662357	2025-11-29 14:49:12.363689	\N	娴嬭瘯1003	\N	\N	offline	\N	\N	\N	\N	\N	d4g3rU	666666
132	test1001	$2a$10$KFbj9qrpidkRsvAUY73vZ.g7gnT7UtAAwnEdP1NCMEiMex.nvEmny				2025-11-29 13:37:40.585782	2025-11-29 17:36:42.644854	\N	ces001鍙戦『涓板埌浠樺叕鍙?male	<script>alter('1")</script><script>alter("1')</script><script>alter('1)</script><script>alter("1')</script><script>alter("1')</script><script>alter('1")</script><script>alter("1")</script><script>alter("1")</script><script>alter('1掳)</script><script>alter('1')</script><script>alter('1)</script><script>alter(鈥?鈥?</script><script>alter('1鈥?</script><script>alter('1")</script><script>alter('1")</script><script>alter("1')</script><script>alter('1')</sC>alter('1')</lpt><script>alter('2')</script><scr	offline	\N	\N				\N	\N
113	test22	$2a$10$ATfNIdUDVtWLhSeF6dMvL.m3EQEUFaFDgVb/GK7yNlQFY8.b4XORa			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764556315_JPEG_20251201_103156_2579755215525603268.jpg	2025-11-25 17:55:13.217482	2025-12-01 21:21:24.820491	\N	娴嬭瘯22	male	errt	online						\N	\N
121	test26	$2a$10$WuwhFrvuE6t.eOiIuRHqoOWnILSUDy5uEEPJ6zwPnrgKccqvDorKW	\N	\N		2025-11-27 02:30:26.178233	2025-12-01 19:25:00.6684	\N	娴嬭瘯26	\N	\N	offline	\N	\N	\N	\N	\N	\N	\N
138	test56	$2a$10$LJwd6Qwr5XJFSSo7CRz2YOD9uQTLgogpGiCvo0TDTh9q6VWUddPke	\N	\N		2025-12-01 14:34:20.800592	2025-12-01 14:41:56.008301	\N	娴嬭瘯56	\N	\N	offline	\N	\N	\N	\N	\N	ZzoPOa	666666
155	test907	$2a$10$1McmC1b0MvRJEfFn2p8WGOehv1asqwu0A4cp4cWPFfvn1q/gxK7oS	\N	\N		2025-12-05 13:31:42.744193	2025-12-05 19:06:19.445385	\N	娴嬭瘯907	\N	\N	offline	\N	\N	\N	\N	\N	6rgX4T	666666
141	test31	$2a$10$avSFHQYchtM6AHo/D5nDIOnmMghJiJW2F3qTFVGMsGgNO9VJtYueu	\N	\N		2025-12-01 19:36:09.866007	2025-12-01 21:21:12.900514	\N	娴嬭瘯31	\N	\N	offline	\N	\N	\N	\N	\N	DiV7bV	666666
139	test29	$2a$10$ul5Nx0sS/xMhbaajYCHyku0HWxWweraLfH8U1t.pmafbjr6rwH6L.	\N	\N		2025-12-01 19:26:47.038002	2025-12-01 19:28:11.560924	\N	娴嬭瘯29	\N	\N	offline	\N	\N	\N	\N	\N	Xhj5Up	666666
151	test62	$2a$10$bLTFcRAf0vbfZWdbEilcie4moIh5PbqGz.CMsIhtpMVMrGORwQFJy	15172576575	250634483@qq.com	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764831808_JPEG_20251204_150328_5604717279973525312.jpg	2025-12-03 22:26:08.534211	2025-12-14 17:19:49.114643	\N	寮犲皬鑾?male	\N	offline						3zFajl	666666
154	test906	$2a$10$iwkU6BRotseLnGXLJSw/VesDrgl2fSWSLJyrkzMq/kkFXO1uglnoS	\N	\N		2025-12-05 13:31:08.625624	2025-12-05 20:47:49.065077	\N	dddd	\N	\N	offline	\N	\N	\N	\N	\N	Ysdixy	666666
112	test21	$2a$10$Eaj1zQhgPJEqdQWaLa8P6.NIUf4Drc38eChifjExQSKJsWdDvlYxa			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764559667_JPEG_20251201_112747_572129990650056502.jpg	2025-11-25 13:19:49.620411	2025-12-01 22:17:43.217651	\N	test-21	male	)31e<ids><iduos/>(,l,)31e<iduos><iduos/>(.鈫?)蓹1e<idus><iduos/>(,鈫?)a1e<iduos><id!os/>(.l,)蓹1e<idus><iduos/>(,l,)1e<iduos><iduos/>(,l,)蓹1e<idus><dus/>(,鈫?)1e<iduos><1duos/>(,鈫?)蓹1e<idus><idus/>(,鈫?)1|e<duos><idlos/>(,鈫?)銆嵣?e<idu蓴s><id蓴s/>(,鈫?)鈫撋檈<iduos><iduos/>(,鈫?)蓹1e<idu蓴s><dus/>(,鈫?)1e<idus><iduos/>(,l,)蓹1e<idu蓴s><duos/>(,鈫?)蓹1e<idus><iduos/>(,l,)蓹1e<iduos><idu蓴s/>(,l,)蓹#e<iduos>llll	offline						\N	\N
140	test30	$2a$10$111CJ0Gj3RO6iE5vZZ64K.c2zK/jV63279L10VfvOBrFEizCeSN7y	\N	\N		2025-12-01 19:28:37.14177	2025-12-01 19:35:40.696026	\N	娴嬭瘯30	\N	\N	offline	\N	\N	\N	\N	\N	sOHnzp	666666
144	test53	$2a$10$61Z1Vc2Gknq0LBfDglSuSewOboOxqu7t.hVGmDA2KgomO/z8tgKjW			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771146_1762490101_3_k4vl6CdQ.jpg	2025-12-01 22:20:35.820806	2025-12-03 22:17:36.109562	\N	娴嬭瘯53	female	\N	offline						RQrk8Q	666666
146	test55	$2a$10$u7fIDd/1Q5l8cDjZhKiW2.odrcIZU6G0FR4hx0SqPjwxceHa0WbB2			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764756316_JPEG_20251203_180517_3978478675264976845.jpg	2025-12-03 15:32:07.157365	2025-12-03 20:13:17.566311	\N	娴嬭瘯55	male	\N	online	\N	\N				kSpaJU	666666
145	test54	$2a$10$/xEiZBaOKmzr0qnOvJXE/OL0dr6Lq97w8aYCwQ6PIR7V.z0jYwYje			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764755963_1762175910_5_daVpZIcT.jpg	2025-12-03 15:20:53.35832	2025-12-03 22:17:55.938981	\N	娴嬭瘯54	male	\N	offline						SYf8mE	666666
147	test57	$2a$10$k.HEaeLXlfcU9bg.MMyE3OwQ2aa7ca8pwUPEhapGL0L4Rln8OxPN.				2025-12-03 20:29:57.049939	2025-12-03 20:41:08.337062	\N	娴嬭瘯浜旀煉	male	\N	offline						xFO3qd	666666
143	test52	$2a$10$1uIlzT2ykMQ0G2N8FTXHce.uSQh65OsOIpG5mmBODIMWWjE2K85ra	\N	\N		2025-12-01 22:20:15.563922	2025-12-02 20:31:16.075437	\N	娴嬭瘯52	\N	\N	online	\N	\N	\N	\N	\N	cKkJA8	666666
148	test58	$2a$10$M6SMvjZO45UTPUpwa1C4Pu40u1RkqceA/ksCJ6Rpq1a0IoOX4UomS	\N	\N		2025-12-03 22:13:15.52097	2025-12-03 22:55:01.080332	\N	娴嬭瘯58	\N	\N	offline	\N	\N	\N	\N	\N	P5wn8a	666666
150	test61	$2a$10$VW1OQua1NxPaz76guJ.Qxu/oW12k2HK/rD8Y5H7AfWo1FTMyncBdm	\N	\N		2025-12-03 22:20:45.915263	2025-12-14 11:49:22.54093	\N	娴嬭瘯61	\N	\N	offline	\N	\N	\N	\N	\N	vMcUct	666666
152	test65	$2a$10$/9fWjM9Mrdl1nZnpoJgLqOdPRcQjcGIrFaJDonrBjRXAkcowc8wI6	\N	\N		2025-12-03 22:55:21.865905	2025-12-09 13:17:18.145957	\N	娴嬭瘯65	\N	\N	offline	\N	\N	\N	\N	\N	YS39ch	666666
142	test51	$2a$10$01gVR7v26TpJnIajlA7phO28WS3Y1Mips5a8f0eYw/Nfm4MZOJOzK				2025-12-01 22:19:53.345399	2025-12-03 15:20:33.514749	\N	娴嬭瘯51	male	\N	offline						e5cm9w	666666
153	test905	$2a$10$8nRK0HoM.M9A7PTagDfXQuYCV8.GPgh2WxHM/4eIWnvuQk4YqSPGK	\N	\N		2025-12-05 13:28:04.210463	2025-12-05 13:31:24.04771	\N	娴嬭瘯905	\N	\N	offline	\N	\N	\N	\N	\N	xr5iFp	666666
157	test70	$2a$10$w.35EmDIwWNX8v/9TDfWyOIfqHDfvM80oHEUhQWex4TxwcfB8PNg2	\N	\N		2025-12-09 11:28:48.094001	2025-12-14 11:28:00.688346	\N	ceshi70	\N	\N	offline	\N	\N	\N	\N	\N	asO5ia	666666
156	test63	$2a$10$OPLK8LyU/ckHB6pwvm7f8e5f7FnnkQVK5n2bOIRjSdrgLkFQOjkza	\N	\N		2025-12-07 19:01:27.140263	2025-12-08 22:57:50.831375	\N	娴嬭瘯63	\N	\N	offline	\N	\N	\N	\N	\N	5KP9DP	666666
158	test73	$2a$10$lhu8JSFf993viEM/hnq1zeC7l/gIor927ZBq4LLuZ2dd7tYgkDwWC				2025-12-14 11:29:59.301432	2025-12-14 13:44:25.24696	\N	ceshi73鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝鍝﹀摝	male	\N	offline	\N	\N			鍡棷鍡棷鍡棷鍡棷鍡棷鍡棷鍡棷鍡棷	JerdyW	666666
149	test60	$2a$10$fT4E7TSn6C9lrdKDhrtCHeR5YKI1RG5s1XZ7p5RmLOKsStqbgTBJ2			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764771562_JPEG_20251203_221922_5447539638496536625.jpg	2025-12-03 22:18:23.720252	2025-12-14 17:11:55.727243	\N	娴嬭瘯60	male	\N	online	\N	\N				BAtZ2v	666666
159	test74	$2a$10$v79gWpOMGyrMmF7L97ZCneF0Wg00Tg.2spEQo9H4Dn5X8bMqPLbzW	\N	\N		2025-12-14 11:49:49.574942	2025-12-14 17:12:10.462294	\N	娴嬭瘯74	\N	\N	offline	\N	\N	\N	\N	\N	YpRhwr	666666
\.


--
-- Data for Name: verification_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.verification_codes (id, account, code, type, expires_at, created_at) FROM stdin;
4	13662257518	141096	login	2025-12-08 23:06:06.204874	2025-12-08 23:01:06.207084
5	13662257518	357196	login	2025-12-08 23:13:33.707915	2025-12-08 23:08:33.709466
\.


--
-- Name: app_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.app_versions_id_seq', 4, true);


--
-- Name: device_registrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.device_registrations_id_seq', 381, true);


--
-- Name: favorite_contacts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favorite_contacts_id_seq', 3, true);


--
-- Name: favorite_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favorite_groups_id_seq', 4, true);


--
-- Name: favorites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favorites_id_seq', 80, true);


--
-- Name: file_assistant_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.file_assistant_messages_id_seq', 11, true);


--
-- Name: group_members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_members_id_seq', 455, true);


--
-- Name: group_message_reads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_message_reads_id_seq', 2851, true);


--
-- Name: group_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_messages_id_seq', 2077, true);


--
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.groups_id_seq', 159, true);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 3624, true);


--
-- Name: server_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.server_settings_id_seq', 5, true);


--
-- Name: user_relations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_relations_id_seq', 242, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 159, true);


--
-- Name: verification_codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.verification_codes_id_seq', 5, true);


--
-- Name: app_versions app_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_versions
    ADD CONSTRAINT app_versions_pkey PRIMARY KEY (id);


--
-- Name: app_versions app_versions_version_platform_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_versions
    ADD CONSTRAINT app_versions_version_platform_key UNIQUE (version, platform);


--
-- Name: device_registrations device_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_registrations
    ADD CONSTRAINT device_registrations_pkey PRIMARY KEY (id);


--
-- Name: device_registrations device_registrations_uuid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_registrations
    ADD CONSTRAINT device_registrations_uuid_key UNIQUE (uuid);


--
-- Name: favorite_contacts favorite_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_contacts
    ADD CONSTRAINT favorite_contacts_pkey PRIMARY KEY (id);


--
-- Name: favorite_contacts favorite_contacts_user_id_contact_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_contacts
    ADD CONSTRAINT favorite_contacts_user_id_contact_id_key UNIQUE (user_id, contact_id);


--
-- Name: favorite_groups favorite_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_groups
    ADD CONSTRAINT favorite_groups_pkey PRIMARY KEY (id);


--
-- Name: favorite_groups favorite_groups_user_id_group_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_groups
    ADD CONSTRAINT favorite_groups_user_id_group_id_key UNIQUE (user_id, group_id);


--
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (id);


--
-- Name: file_assistant_messages file_assistant_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assistant_messages
    ADD CONSTRAINT file_assistant_messages_pkey PRIMARY KEY (id);


--
-- Name: group_members group_members_group_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_group_id_user_id_key UNIQUE (group_id, user_id);


--
-- Name: group_members group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_pkey PRIMARY KEY (id);


--
-- Name: group_message_reads group_message_reads_group_message_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_message_reads
    ADD CONSTRAINT group_message_reads_group_message_id_user_id_key UNIQUE (group_message_id, user_id);


--
-- Name: group_message_reads group_message_reads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_message_reads
    ADD CONSTRAINT group_message_reads_pkey PRIMARY KEY (id);


--
-- Name: group_messages group_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: server_settings server_settings_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.server_settings
    ADD CONSTRAINT server_settings_key_key UNIQUE (key);


--
-- Name: server_settings server_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.server_settings
    ADD CONSTRAINT server_settings_pkey PRIMARY KEY (id);


--
-- Name: user_relations user_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_relations
    ADD CONSTRAINT user_relations_pkey PRIMARY KEY (id);


--
-- Name: user_relations user_relations_user_id_friend_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_relations
    ADD CONSTRAINT user_relations_user_id_friend_id_key UNIQUE (user_id, friend_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: verification_codes verification_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.verification_codes
    ADD CONSTRAINT verification_codes_pkey PRIMARY KEY (id);


--
-- Name: idx_app_versions_platform; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_app_versions_platform ON public.app_versions USING btree (platform);


--
-- Name: idx_app_versions_platform_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_app_versions_platform_status ON public.app_versions USING btree (platform, status);


--
-- Name: idx_app_versions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_app_versions_status ON public.app_versions USING btree (status);


--
-- Name: idx_device_installed_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_installed_at ON public.device_registrations USING btree (installed_at);


--
-- Name: idx_device_platform; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_platform ON public.device_registrations USING btree (platform);


--
-- Name: idx_device_uuid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_device_uuid ON public.device_registrations USING btree (uuid);


--
-- Name: idx_favorite_contacts_contact_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorite_contacts_contact_id ON public.favorite_contacts USING btree (contact_id);


--
-- Name: idx_favorite_contacts_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorite_contacts_created_at ON public.favorite_contacts USING btree (created_at DESC);


--
-- Name: idx_favorite_contacts_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorite_contacts_user_id ON public.favorite_contacts USING btree (user_id);


--
-- Name: idx_favorite_groups_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorite_groups_created_at ON public.favorite_groups USING btree (created_at DESC);


--
-- Name: idx_favorite_groups_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorite_groups_group_id ON public.favorite_groups USING btree (group_id);


--
-- Name: idx_favorite_groups_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorite_groups_user_id ON public.favorite_groups USING btree (user_id);


--
-- Name: idx_favorites_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorites_created_at ON public.favorites USING btree (created_at DESC);


--
-- Name: idx_favorites_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorites_user_id ON public.favorites USING btree (user_id);


--
-- Name: idx_file_assistant_messages_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_file_assistant_messages_created_at ON public.file_assistant_messages USING btree (created_at DESC);


--
-- Name: idx_file_assistant_messages_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_file_assistant_messages_status ON public.file_assistant_messages USING btree (status);


--
-- Name: idx_file_assistant_messages_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_file_assistant_messages_user_id ON public.file_assistant_messages USING btree (user_id);


--
-- Name: idx_group_members_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_members_group_id ON public.group_members USING btree (group_id);


--
-- Name: idx_group_members_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_members_user_id ON public.group_members USING btree (user_id);


--
-- Name: idx_group_message_reads_group_message_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_message_reads_group_message_id ON public.group_message_reads USING btree (group_message_id);


--
-- Name: idx_group_message_reads_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_message_reads_user_id ON public.group_message_reads USING btree (user_id);


--
-- Name: idx_group_messages_call_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_messages_call_type ON public.group_messages USING btree (call_type) WHERE (call_type IS NOT NULL);


--
-- Name: idx_group_messages_channel_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_messages_channel_name ON public.group_messages USING btree (channel_name) WHERE (channel_name IS NOT NULL);


--
-- Name: idx_group_messages_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_messages_created_at ON public.group_messages USING btree (created_at);


--
-- Name: idx_group_messages_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_messages_group_id ON public.group_messages USING btree (group_id);


--
-- Name: idx_group_messages_sender_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_messages_sender_id ON public.group_messages USING btree (sender_id);


--
-- Name: idx_groups_owner_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_groups_owner_id ON public.groups USING btree (owner_id);


--
-- Name: idx_messages_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_created_at ON public.messages USING btree (created_at DESC);


--
-- Name: idx_messages_is_read; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_is_read ON public.messages USING btree (is_read) WHERE (is_read = false);


--
-- Name: idx_messages_receiver_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_receiver_id ON public.messages USING btree (receiver_id);


--
-- Name: idx_messages_receiver_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_receiver_name ON public.messages USING btree (receiver_name);


--
-- Name: idx_messages_sender_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_sender_id ON public.messages USING btree (sender_id);


--
-- Name: idx_messages_sender_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_sender_name ON public.messages USING btree (sender_name);


--
-- Name: idx_messages_sender_receiver; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_sender_receiver ON public.messages USING btree (sender_id, receiver_id, created_at DESC);


--
-- Name: idx_messages_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_status ON public.messages USING btree (status);


--
-- Name: idx_user_relations_approval_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_relations_approval_status ON public.user_relations USING btree (approval_status);


--
-- Name: idx_user_relations_friend_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_relations_friend_id ON public.user_relations USING btree (friend_id);


--
-- Name: idx_user_relations_is_blocked; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_relations_is_blocked ON public.user_relations USING btree (is_blocked) WHERE (is_blocked = true);


--
-- Name: idx_user_relations_is_deleted; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_relations_is_deleted ON public.user_relations USING btree (is_deleted) WHERE (is_deleted = true);


--
-- Name: idx_user_relations_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_relations_user_id ON public.user_relations USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email) WHERE (email IS NOT NULL);


--
-- Name: idx_users_invite_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_users_invite_code ON public.users USING btree (invite_code) WHERE (invite_code IS NOT NULL);


--
-- Name: idx_users_invited_by_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_invited_by_code ON public.users USING btree (invited_by_code) WHERE (invited_by_code IS NOT NULL);


--
-- Name: idx_users_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_phone ON public.users USING btree (phone) WHERE (phone IS NOT NULL);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: idx_verification_codes_account; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_verification_codes_account ON public.verification_codes USING btree (account);


--
-- Name: idx_verification_codes_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_verification_codes_expires_at ON public.verification_codes USING btree (expires_at);


--
-- Name: server_settings update_server_settings_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_server_settings_updated_at BEFORE UPDATE ON public.server_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: favorite_contacts favorite_contacts_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_contacts
    ADD CONSTRAINT favorite_contacts_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: favorite_contacts favorite_contacts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_contacts
    ADD CONSTRAINT favorite_contacts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: favorite_groups favorite_groups_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_groups
    ADD CONSTRAINT favorite_groups_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: favorite_groups favorite_groups_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_groups
    ADD CONSTRAINT favorite_groups_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: favorites favorites_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id) ON DELETE CASCADE;


--
-- Name: favorites favorites_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: favorites favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: file_assistant_messages file_assistant_messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assistant_messages
    ADD CONSTRAINT file_assistant_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: group_members group_members_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: group_members group_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: group_message_reads group_message_reads_group_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_message_reads
    ADD CONSTRAINT group_message_reads_group_message_id_fkey FOREIGN KEY (group_message_id) REFERENCES public.group_messages(id) ON DELETE CASCADE;


--
-- Name: group_message_reads group_message_reads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_message_reads
    ADD CONSTRAINT group_message_reads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: group_messages group_messages_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: group_messages group_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: groups groups_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id);


--
-- Name: messages messages_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_relations user_relations_friend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_relations
    ADD CONSTRAINT user_relations_friend_id_fkey FOREIGN KEY (friend_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_relations user_relations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_relations
    ADD CONSTRAINT user_relations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


