--
-- PostgreSQL database dump
--

\restrict Rzzm7wYZLAhzxwfT6ENlmdRQ6PGVeaNxPRa4ld1EidNA83AbaXXAUUrHSxma3Ed

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
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
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
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
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
    sender_nickname character varying(100),
    sender_full_name character varying(100),
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
    deleted_by_users text DEFAULT ''::text
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
    sender_name character varying(50),
    receiver_name character varying(50),
    file_name character varying(255) DEFAULT NULL::character varying,
    quoted_message_id integer,
    quoted_message_content text,
    status character varying(20) DEFAULT 'normal'::character varying,
    deleted_by_users text DEFAULT ''::text,
    sender_avatar text,
    receiver_avatar text,
    call_type character varying(20) DEFAULT NULL::character varying
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: COLUMN messages.sender_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.sender_name IS 'Sender username';


--
-- Name: COLUMN messages.receiver_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.messages.receiver_name IS 'Receiver username';


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
-- Data for Name: device_registrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_registrations (id, uuid, request_ip, platform, system_info, installed_at, created_at, updated_at) FROM stdin;
1	65456255-5196-4d8a-96ee-0653cbf22b03	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 16:32:52.691175	2025-11-24 16:32:52.399671	2025-11-24 16:32:52.399671
2	73c978aa-91c1-4a78-a5b4-2f5fe96bdffb	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 16:59:42.547024	2025-11-24 16:59:42.160502	2025-11-24 16:59:42.160502
3	36f60dbf-5cb8-4f7a-811e-4df7a88fab98	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 17:03:19.046834	2025-11-24 17:03:18.664769	2025-11-24 17:03:18.664769
5	e1f51d0d-049b-4ac5-bb7e-d9b8fa6e597d	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 17:23:18.035138	2025-11-24 17:23:17.616277	2025-11-24 17:23:17.616277
6	6c330562-016b-4e2f-9ec8-4d37a07535a9	192.168.1.17	android	{"os": "android", "is_web": false, "locale": "zh_Hans_CN", "is_debug": true, "os_version": "STF-AL10 9.0.1.179(C00E63R1P9)", "number_of_processors": 8}	2025-11-24 17:25:01.609749	2025-11-24 17:25:01.193762	2025-11-24 17:25:01.193762
4	682fa00e-43d7-4218-b110-e17e7d84b5d3	192.168.1.6	windows	{"os": "windows", "is_web": false, "locale": "zh_CN", "is_debug": true, "os_version": "\\"Windows 10 Pro\\" 10.0 (Build 19045)", "number_of_processors": 16}	2025-11-24 17:03:53.236877	2025-11-24 17:03:54.632007	2025-11-26 13:23:33.647506
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

COPY public.favorites (id, user_id, message_id, content, message_type, file_name, sender_id, sender_name, created_at) FROM stdin;
\.


--
-- Data for Name: file_assistant_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.file_assistant_messages (id, user_id, content, message_type, file_name, quoted_message_id, quoted_message_content, status, created_at) FROM stdin;
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
129	26	103	\N	\N	member	2025-11-26 11:03:31.407531	f	approved	f
128	26	113	\N	\N	owner	2025-11-26 11:03:31.406152	f	approved	f
130	26	114	\N	\N	member	2025-11-26 12:43:40.79702	f	approved	f
\.


--
-- Data for Name: group_message_reads; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_message_reads (id, group_message_id, user_id, read_at) FROM stdin;
\.


--
-- Data for Name: group_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_messages (id, group_id, sender_id, sender_name, content, message_type, file_name, quoted_message_id, quoted_message_content, status, created_at, sender_avatar, mentioned_user_ids, mentions, deleted_by_users) FROM stdin;
733	23	103	测试2	群组已创建	system	\N	\N	\N	normal	2025-11-24 19:23:07.635651		\N	\N	
734	23	102	测试01	111	text	\N	\N	\N	normal	2025-11-24 19:23:19.500715		\N	\N	
735	23	102	测试01	222	text	\N	\N	\N	normal	2025-11-24 19:23:27.014424		\N	\N	
736	23	103	测试2	333	text	\N	\N	\N	normal	2025-11-24 19:23:31.618152		\N	\N	
737	23	103	测试2	444	text	\N	\N	\N	normal	2025-11-24 19:23:37.856743		\N	\N	
738	23	103	测试2	555	text	\N	\N	\N	normal	2025-11-24 19:38:17.805563		\N	\N	
739	23	103	测试2	666	text	\N	\N	\N	normal	2025-11-24 19:46:32.889884		\N	\N	
740	23	102	测试01	3333	text	\N	\N	\N	normal	2025-11-24 19:48:32.560429		\N	\N	
741	23	103	测试2	444	text	\N	\N	\N	normal	2025-11-24 20:40:25.299577		\N	\N	
742	23	103	测试2	555	text	\N	\N	\N	normal	2025-11-24 20:57:29.713493		\N	\N	
743	23	103	测试2	[emotion:1_Smile.png]	text	\N	\N	\N	normal	2025-11-24 20:59:29.390911		\N	\N	
744	23	102	测试01	123456	text	\N	\N	\N	normal	2025-11-24 21:10:27.56401		\N	\N	
745	23	103	测试2	55	text	\N	\N	\N	normal	2025-11-24 21:10:34.24543		\N	\N	
746	23	102	测试01	111	text	\N	\N	\N	normal	2025-11-24 22:05:29.410129		\N	\N	
747	24	112	测试21	群组已创建	system	\N	\N	\N	normal	2025-11-25 14:27:47.611305		\N	\N	
748	24	112	测试21	222	text	\N	\N	\N	normal	2025-11-25 14:58:54.273276		\N	\N	
749	24	112	测试21	333	text	\N	\N	\N	normal	2025-11-25 14:59:53.809909		\N	\N	
750	24	102	测试01	3333	text	\N	\N	\N	normal	2025-11-25 15:12:22.138085		\N	\N	
751	24	102	测试01	4444	text	\N	\N	\N	normal	2025-11-25 15:12:27.363005		\N	\N	
752	24	112	测试21	555	text	\N	\N	\N	normal	2025-11-25 15:27:06.089523		\N	\N	
753	25	107	测试06	群组已创建	system	\N	\N	\N	normal	2025-11-26 08:02:29.852289		\N	\N	
754	25	107	测试06	111	text	\N	\N	\N	normal	2025-11-26 08:02:43.550818		\N	\N	
755	25	107	测试06	222	text	\N	\N	\N	normal	2025-11-26 08:03:15.363561		\N	\N	
756	25	107	测试06	333	text	\N	\N	\N	normal	2025-11-26 08:03:16.498114		\N	\N	
757	25	107	测试06	444	text	\N	\N	\N	normal	2025-11-26 08:03:17.208616		\N	\N	
758	25	107	测试06	555	text	\N	\N	\N	normal	2025-11-26 08:03:18.264466		\N	\N	
759	25	107	测试06	666	text	\N	\N	\N	normal	2025-11-26 08:03:18.975135		\N	\N	
760	25	107	测试06	777	text	\N	\N	\N	normal	2025-11-26 08:03:20.107302		\N	\N	
761	25	107	测试06	888	text	\N	\N	\N	normal	2025-11-26 08:03:20.898584		\N	\N	
762	25	107	测试06	999	text	\N	\N	\N	normal	2025-11-26 08:03:21.728416		\N	\N	
763	25	107	测试06	000	text	\N	\N	\N	normal	2025-11-26 08:03:22.624321		\N	\N	
764	25	107	测试06	111	text	\N	\N	\N	normal	2025-11-26 08:03:24.015655		\N	\N	
765	25	107	测试06	222	text	\N	\N	\N	normal	2025-11-26 08:03:24.812569		\N	\N	
766	25	107	测试06	333	text	\N	\N	\N	normal	2025-11-26 08:03:25.594716		\N	\N	
767	25	107	测试06	444	text	\N	\N	\N	normal	2025-11-26 08:03:26.842507		\N	\N	
768	25	107	测试06	555	text	\N	\N	\N	normal	2025-11-26 08:03:27.761114		\N	\N	
769	25	107	测试06	666	text	\N	\N	\N	normal	2025-11-26 08:03:28.482357		\N	\N	
770	26	113	测试22	群组已创建	system	\N	\N	\N	normal	2025-11-26 11:03:31.409536		\N	\N	
771	26	113	测试22	11	text	\N	\N	\N	normal	2025-11-26 11:04:24.278418		\N	\N	
772	26	113	测试22	22	text	\N	\N	\N	normal	2025-11-26 11:04:57.883292		\N	\N	
773	26	113	测试22	11	text	\N	\N	\N	normal	2025-11-26 11:34:41.051765		\N	\N	
774	26	113	测试22	全体禁言已关闭	system	\N	\N	\N	normal	2025-11-26 11:35:31.790812		\N	\N	
775	26	113	测试22	全体禁言已开启	system	\N	\N	\N	normal	2025-11-26 11:41:20.784102		\N	\N	
776	26	113	测试22	全体禁言已关闭	system	\N	\N	\N	normal	2025-11-26 11:41:33.23408		\N	\N	
777	26	113	测试22	33	text	\N	\N	\N	normal	2025-11-26 12:42:35.080768	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
778	26	113	测试22	44	text	\N	\N	\N	normal	2025-11-26 12:42:36.744637	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
779	26	113	测试22	5	text	\N	\N	\N	normal	2025-11-26 12:43:46.486436	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
780	26	114	测试23	gfdd	text	\N	\N	\N	normal	2025-11-26 12:49:40.723715	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
781	26	113	测试22	11	text	\N	\N	\N	normal	2025-11-26 13:08:25.827485	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
782	26	113	测试22	333	text	\N	\N	\N	normal	2025-11-26 13:11:22.597601	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
783	26	113	测试22	44	text	\N	\N	\N	normal	2025-11-26 13:17:16.741276	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
784	26	113	测试22	55	text	\N	\N	\N	normal	2025-11-26 13:24:25.907743	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
785	26	113	测试22	66	text	\N	\N	\N	normal	2025-11-26 13:27:13.018659	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
786	26	114	测试23	888	text	\N	\N	\N	normal	2025-11-26 13:28:52.052571	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
787	26	113	测试22	999	text	\N	\N	\N	normal	2025-11-26 13:29:45.929195	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
788	26	113	测试22	11	text	\N	\N	\N	normal	2025-11-26 13:45:25.1804	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
789	26	113	测试22	22	text	\N	\N	\N	normal	2025-11-26 13:45:36.784231	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
790	26	113	测试22	33	text	\N	\N	\N	normal	2025-11-26 13:45:40.528921	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
791	26	113	测试22	44	text	\N	\N	\N	normal	2025-11-26 13:45:42.873167	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
792	26	113	测试22	55	text	\N	\N	\N	normal	2025-11-26 13:45:44.81739	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
793	26	113	测试22	66	text	\N	\N	\N	normal	2025-11-26 13:45:46.5844	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
794	26	113	测试22	77	text	\N	\N	\N	normal	2025-11-26 13:45:48.387732	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
795	26	113	测试22	88	text	\N	\N	\N	normal	2025-11-26 13:45:50.074842	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
796	26	113	测试22	99	text	\N	\N	\N	normal	2025-11-26 13:45:51.878091	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
797	26	113	测试22	11	text	\N	\N	\N	normal	2025-11-26 13:45:53.514781	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
798	26	113	测试22	22	text	\N	\N	\N	normal	2025-11-26 13:45:55.406646	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
799	26	113	测试22	33	text	\N	\N	\N	normal	2025-11-26 13:45:56.950207	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
800	26	113	测试22	44	text	\N	\N	\N	normal	2025-11-26 13:45:58.751613	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
801	26	113	测试22	55	text	\N	\N	\N	normal	2025-11-26 13:46:00.549709	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
802	26	113	测试22	66	text	\N	\N	\N	normal	2025-11-26 13:46:02.390738	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
803	26	113	测试22	77	text	\N	\N	\N	normal	2025-11-26 13:46:03.938289	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
804	26	113	测试22	88	text	\N	\N	\N	normal	2025-11-26 13:46:05.719986	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
805	26	113	测试22	99	text	\N	\N	\N	normal	2025-11-26 13:46:07.344627	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
806	26	113	测试22	00	text	\N	\N	\N	normal	2025-11-26 13:46:09.029697	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
807	26	113	测试22	11	text	\N	\N	\N	normal	2025-11-26 13:46:10.526067	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
808	26	113	测试22	22	text	\N	\N	\N	normal	2025-11-26 13:46:13.678397	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
809	26	113	测试22	33	text	\N	\N	\N	normal	2025-11-26 13:46:15.039012	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
810	26	113	测试22	44	text	\N	\N	\N	normal	2025-11-26 13:46:16.495445	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
811	26	113	测试22	55	text	\N	\N	\N	normal	2025-11-26 13:46:17.984549	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
812	26	113	测试22	66	text	\N	\N	\N	normal	2025-11-26 13:46:19.614847	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
813	26	113	测试22	77	text	\N	\N	\N	normal	2025-11-26 13:46:21.045952	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
814	26	113	测试22	88	text	\N	\N	\N	normal	2025-11-26 13:46:22.600989	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
815	26	113	测试22	99	text	\N	\N	\N	normal	2025-11-26 13:46:23.947025	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
816	26	114	测试23	00	text	\N	\N	\N	normal	2025-11-26 13:46:36.377028	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
817	26	114	测试23	11	text	\N	\N	\N	normal	2025-11-26 13:46:38.519683	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
818	26	114	测试23	22	text	\N	\N	\N	normal	2025-11-26 13:46:40.815048	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
819	26	114	测试23	33	text	\N	\N	\N	normal	2025-11-26 13:46:42.714386	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
820	26	114	测试23	44	text	\N	\N	\N	normal	2025-11-26 13:46:44.782637	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
821	26	114	测试23	55	text	\N	\N	\N	normal	2025-11-26 13:46:47.209412	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
822	26	114	测试23	66	text	\N	\N	\N	normal	2025-11-26 13:46:49.417748	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
823	26	114	测试23	77	text	\N	\N	\N	normal	2025-11-26 13:46:51.237514	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
824	26	114	测试23	88	text	\N	\N	\N	normal	2025-11-26 13:46:53.043184	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
825	26	114	测试23	99	text	\N	\N	\N	normal	2025-11-26 13:46:54.984957	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
826	26	114	测试23	00	text	\N	\N	\N	normal	2025-11-26 13:46:56.822441	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
827	26	114	测试23	11	text	\N	\N	\N	normal	2025-11-26 13:46:58.572483	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
828	26	114	测试23	22	text	\N	\N	\N	normal	2025-11-26 13:47:00.241181	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
829	26	114	测试23	44	text	\N	\N	\N	normal	2025-11-26 13:47:02.360447	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
830	26	114	测试23	55	text	\N	\N	\N	normal	2025-11-26 13:47:04.430001	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
831	26	114	测试23	66	text	\N	\N	\N	normal	2025-11-26 13:47:06.172422	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
832	26	114	测试23	77	text	\N	\N	\N	normal	2025-11-26 13:47:08.487261	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
833	26	114	测试23	77	text	\N	\N	\N	normal	2025-11-26 13:47:10.202599	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
834	26	114	测试23	88	text	\N	\N	\N	normal	2025-11-26 13:47:11.739179	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
835	26	114	测试23	88	text	\N	\N	\N	normal	2025-11-26 13:47:13.586649	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
836	26	114	测试23	88	text	\N	\N	\N	normal	2025-11-26 13:47:16.536907	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
837	26	113	测试22	aa	text	\N	\N	\N	normal	2025-11-26 14:18:59.384982	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
838	26	114	测试23	bbb	text	\N	\N	\N	normal	2025-11-26 14:19:05.433868	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
839	26	114	测试23	ddd	text	\N	\N	\N	normal	2025-11-26 14:19:07.179958	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
840	26	113	测试22	aa	text	\N	\N	\N	normal	2025-11-26 14:30:26.381301	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
841	26	113	测试22	bb	text	\N	\N	\N	normal	2025-11-26 14:30:27.745005	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
842	26	114	测试23	esd	text	\N	\N	\N	normal	2025-11-26 14:30:36.110574	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
843	26	114	测试23	bvc	text	\N	\N	\N	normal	2025-11-26 14:30:38.692654	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
844	26	113	测试22	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764139616_ic_launcher.png	image	\N	\N	\N	normal	2025-11-26 14:46:59.265643	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
845	26	113	测试22	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1764139634_2637-161442811_tiny.mp4	video	\N	\N	\N	normal	2025-11-26 14:47:19.882021	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
846	26	113	测试22	11	text	\N	\N	\N	normal	2025-11-26 14:47:20.040599	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
847	26	114	测试23	222	text	\N	\N	\N	normal	2025-11-26 15:25:05.389823	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
848	26	113	测试22	33	text	\N	\N	\N	normal	2025-11-26 15:25:13.061205	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
849	26	113	测试22	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764141920_ic_launcher.png	image	\N	\N	\N	normal	2025-11-26 15:25:22.777081	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
850	26	113	测试22	333	text	\N	\N	\N	normal	2025-11-26 15:51:03.93179	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
851	26	113	测试22	111	text	\N	\N	\N	normal	2025-11-26 16:07:51.536408	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
852	26	113	测试22	22	text	\N	\N	\N	normal	2025-11-26 16:07:58.636518	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
853	26	113	测试22	44	text	\N	\N	\N	normal	2025-11-26 16:08:09.152316	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
854	26	113	测试22	77	text	\N	\N	\N	normal	2025-11-26 16:08:11.39757	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
855	26	114	测试23	yff	text	\N	\N	\N	normal	2025-11-26 16:08:20.422945	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
856	26	114	测试23	hgc	text	\N	\N	\N	normal	2025-11-26 16:08:22.721963	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N	\N	
857	26	113	测试22	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764144515_ic_launcher.png	image	\N	\N	\N	normal	2025-11-26 16:08:37.967704	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N	\N	
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.groups (id, name, announcement, avatar, owner_id, created_at, updated_at, deleted_at, all_muted, invite_confirmation, admin_only_edit_name, member_view_permission) FROM stdin;
23	111	\N	\N	103	2025-11-24 19:23:07.556208	2025-11-24 19:23:07.556208	\N	f	f	f	t
24	群组01	\N	\N	112	2025-11-25 14:27:47.605044	2025-11-25 14:27:47.605044	\N	f	f	f	t
25	群测试02	\N	\N	107	2025-11-26 08:02:29.848503	2025-11-26 08:02:29.848503	\N	f	f	f	t
26	群组测试3	\N	\N	113	2025-11-26 11:03:31.404564	2025-11-26 12:43:40.793218	\N	f	f	f	t
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, sender_id, receiver_id, content, message_type, is_read, created_at, read_at, sender_name, receiver_name, file_name, quoted_message_id, quoted_message_content, status, deleted_by_users, sender_avatar, receiver_avatar, call_type) FROM stdin;
1756	103	102	请求添加好友【已通过】	text	f	2025-11-24 15:20:56.009906	\N	test02	test01	\N	\N	\N	normal				\N
1757	102	103	请求添加好友【已通过】	text	f	2025-11-24 15:20:56.016732	\N	test01	test02	\N	\N	\N	normal				\N
1758	102	103	111	text	f	2025-11-24 15:21:01.800378	\N	test01	test02	\N	\N	\N	normal				\N
1759	103	102	2222	text	f	2025-11-24 15:29:23.97706	\N	test02	test01	\N	\N	\N	normal				\N
1760	102	103	333	text	t	2025-11-24 15:29:27.390818	2025-11-24 15:29:27.473912	test01	test02	\N	\N	\N	normal				\N
1761	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763969375_ic_launcher.png	image	t	2025-11-24 15:29:38.791805	2025-11-24 15:29:38.887998	test01	test02	\N	\N	\N	normal				\N
1762	102	103	44	text	t	2025-11-24 15:29:38.796791	2025-11-24 15:29:39.118573	test01	test02	\N	\N	\N	normal				\N
1763	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1763969392_2637-161442811_tiny.mp4	video	t	2025-11-24 15:29:57.206475	2025-11-24 15:29:57.373893	test01	test02	\N	\N	\N	normal				\N
1764	102	103	555	text	t	2025-11-24 15:29:57.212034	2025-11-24 15:29:57.646549	test01	test02	\N	\N	\N	normal				\N
1765	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/files/1763969411_test_voice_py	file	t	2025-11-24 15:30:13.207027	2025-11-24 15:30:13.38206	test01	test02	test_voice_py	\N	\N	normal				\N
1766	102	103	666	text	t	2025-11-24 15:30:13.259686	2025-11-24 15:30:13.555659	test01	test02	\N	\N	\N	normal				\N
1767	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763969424_paste_1763969422960.png	image	t	2025-11-24 15:30:30.591005	2025-11-24 15:30:30.756506	test01	test02	\N	\N	\N	normal				\N
1768	102	103	888	text	t	2025-11-24 15:30:30.653791	2025-11-24 15:30:31.013935	test01	test02	\N	\N	\N	normal				\N
1769	102	103	[emotion:1_Smile.png]	text	t	2025-11-24 15:30:58.213642	2025-11-24 15:30:58.412877	test01	test02	\N	\N	\N	normal				\N
1770	103	102	😀	text	f	2025-11-24 15:31:07.18073	\N	test02	test01	\N	\N	\N	normal				\N
1771	103	102	999	text	f	2025-11-24 15:31:15.432144	\N	test02	test01	\N	\N	\N	normal				\N
1772	103	102	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763969502_scaled_f590be0a-e5ce-41c8-af14-2ae1310c4c887932569343199737445.jpg	image	f	2025-11-24 15:31:47.50087	\N	test02	test01	\N	\N	\N	normal				\N
1773	103	102	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763969526_JPEG_20251124_153207_1249816683658267111.jpg	image	f	2025-11-24 15:32:08.953384	\N	test02	test01	\N	\N	\N	normal				\N
1774	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1763969611_2637-161442811_tiny.mp4	video	t	2025-11-24 15:33:37.693563	2025-11-24 15:33:37.8626	test01	test02	\N	\N	\N	normal				\N
1775	103	102	334	text	f	2025-11-24 15:39:51.525375	\N	test02	test01	\N	\N	\N	normal				\N
1776	102	103	55	text	t	2025-11-24 15:40:08.475646	2025-11-24 15:40:08.631529	test01	test02	\N	\N	\N	normal				\N
1777	102	103	[emotion:42_NosePick.png]	text	t	2025-11-24 15:40:14.382122	2025-11-24 15:40:14.504165	test01	test02	\N	\N	\N	normal				\N
1778	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763970022_ic_launcher.png	image	t	2025-11-24 15:40:25.174766	2025-11-24 15:40:25.307806	test01	test02	\N	\N	\N	normal				\N
1779	102	103	66	text	t	2025-11-24 15:40:25.179948	2025-11-24 15:40:25.638117	test01	test02	\N	\N	\N	normal				\N
1780	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1763970035_2637-161442811_tiny.mp4	video	t	2025-11-24 15:40:44.189585	2025-11-24 15:40:44.403454	test01	test02	\N	\N	\N	normal				\N
1781	102	103	777	text	t	2025-11-24 15:40:44.195303	2025-11-24 15:40:44.548593	test01	test02	\N	\N	\N	normal				\N
1782	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/files/1763970055_test_voice_py	file	t	2025-11-24 15:40:57.322876	2025-11-24 15:40:57.454947	test01	test02	test_voice_py	\N	\N	normal				\N
1783	102	103	888	text	t	2025-11-24 15:40:57.361159	2025-11-24 15:40:57.67877	test01	test02	\N	\N	\N	normal				\N
1784	103	102	999	text	f	2025-11-24 16:01:21.033761	\N	test02	test01	\N	\N	\N	normal				\N
1785	102	103	000	text	t	2025-11-24 16:01:26.578354	2025-11-24 16:01:26.761454	test01	test02	\N	\N	\N	normal				\N
1786	102	103	[emotion:29_Laugh.png]	text	t	2025-11-24 16:01:31.83709	2025-11-24 16:01:32.040728	test01	test02	\N	\N	\N	normal				\N
1787	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763971305_ic_launcher.png	image	t	2025-11-24 16:01:47.414273	2025-11-24 16:01:47.519639	test01	test02	\N	\N	\N	normal				\N
1788	102	103	11	text	t	2025-11-24 16:01:47.600457	2025-11-24 16:01:47.817559	test01	test02	\N	\N	\N	normal				\N
1789	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1763971315_2637-161442811_tiny.mp4	video	t	2025-11-24 16:02:01.417178	2025-11-24 16:02:01.572053	test01	test02	\N	\N	\N	normal				\N
1790	102	103	222	text	t	2025-11-24 16:02:01.443995	2025-11-24 16:02:01.763547	test01	test02	\N	\N	\N	normal				\N
1791	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/files/1763971333_test_voice_py	file	t	2025-11-24 16:02:15.001842	2025-11-24 16:02:15.149483	test01	test02	test_voice_py	\N	\N	normal				\N
1792	102	103	555	text	t	2025-11-24 16:02:15.186573	2025-11-24 16:02:15.337331	test01	test02	\N	\N	\N	normal				\N
1793	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763971344_paste_1763971342584.png	image	t	2025-11-24 16:02:47.366026	2025-11-24 16:02:47.48701	test01	test02	\N	\N	\N	normal				\N
1794	102	103	66	text	t	2025-11-24 16:02:47.412741	2025-11-24 16:02:47.667039	test01	test02	\N	\N	\N	normal				\N
1795	103	102	77	text	f	2025-11-24 16:03:04.011098	\N	test02	test01	\N	\N	\N	normal				\N
1796	103	102	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763971398_scaled_1ea9e636-8711-4828-adee-5d39962f47655191813218996667729.jpg	image	f	2025-11-24 16:03:23.117268	\N	test02	test01	\N	\N	\N	normal				\N
1797	103	102	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763971422_JPEG_20251124_160342_8938100472596704238.jpg	image	f	2025-11-24 16:03:46.167514	\N	test02	test01	\N	\N	\N	normal				\N
1798	102	103	111	text	f	2025-11-24 16:33:30.673746	\N	test01	test02	\N	\N	\N	normal				\N
1799	102	103	[emotion:28_Sweat.png]	text	f	2025-11-24 16:33:39.922692	\N	test01	test02	\N	\N	\N	normal				\N
1800	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763973233_ic_launcher.png	image	f	2025-11-24 16:33:55.828472	\N	test01	test02	\N	\N	\N	normal				\N
1801	102	103	1111	text	t	2025-11-24 16:58:11.996506	2025-11-24 16:58:12.183152	测试01	测试2	\N	\N	\N	normal				\N
1802	103	102	111	text	f	2025-11-24 17:05:15.81902	\N	测试2	测试01	\N	\N	\N	normal				\N
1803	102	103	333	text	f	2025-11-24 17:05:25.770608	\N	测试01	测试2	\N	\N	\N	normal				\N
1804	103	102	444	text	t	2025-11-24 17:05:30.661474	2025-11-24 17:05:30.83429	测试2	测试01	\N	\N	\N	normal				\N
1805	103	102	555	text	f	2025-11-24 17:25:43.786074	\N	测试2	测试01	\N	\N	\N	normal				\N
1806	102	103	666	text	f	2025-11-24 17:25:54.060367	\N	测试01	测试2	\N	\N	\N	normal				\N
1807	103	102	77	text	t	2025-11-24 17:28:39.819639	2025-11-24 17:28:40.002785	测试2	测试01	\N	\N	\N	normal				\N
1808	104	103	请求添加好友【已驳回】	text	f	2025-11-24 18:57:10.684222	\N	测试03	测试2	\N	\N	\N	normal				\N
1809	104	103	请求添加好友【已驳回】	text	f	2025-11-24 18:59:28.17374	\N	测试03	测试2	\N	\N	\N	normal				\N
1810	103	104	111	text	f	2025-11-24 18:59:36.93846	\N	测试2	测试03	\N	\N	\N	normal				\N
1811	104	103	请求添加好友【已通过】	text	f	2025-11-24 19:04:05.945853	\N	测试03	测试2	\N	\N	\N	normal				\N
1812	103	104	请求添加好友【已通过】	text	f	2025-11-24 19:04:05.947369	\N	测试2	测试03	\N	\N	\N	normal				\N
1813	104	103	1111	text	f	2025-11-24 19:05:35.976882	\N	测试03	测试2	\N	\N	\N	normal				\N
1814	104	103	222	text	f	2025-11-24 19:05:45.27096	\N	测试03	测试2	\N	\N	\N	normal				\N
1815	103	104	333	text	f	2025-11-24 19:05:50.258905	\N	测试2	测试03	\N	\N	\N	normal				\N
1816	103	104	444	text	t	2025-11-24 19:10:02.371765	2025-11-24 19:10:02.475652	测试2	测试03	\N	\N	\N	normal				\N
1817	104	103	555	text	f	2025-11-24 19:10:09.659479	\N	测试03	测试2	\N	\N	\N	normal				\N
1818	104	103	666	text	f	2025-11-24 19:10:16.842969	\N	测试03	测试2	\N	\N	\N	normal				\N
1819	104	103	666	text	f	2025-11-24 19:10:17.399841	\N	测试03	测试2	\N	\N	\N	normal				\N
1820	103	104	777	text	f	2025-11-24 19:10:32.986448	\N	测试2	测试03	\N	\N	\N	normal				\N
1821	103	104	88	text	t	2025-11-24 19:10:41.703854	2025-11-24 19:10:41.842633	测试2	测试03	\N	\N	\N	normal				\N
1822	103	102	11	text	f	2025-11-24 19:22:35.410806	\N	测试2	测试01	\N	\N	\N	normal				\N
1823	102	103	22	text	f	2025-11-24 19:22:44.434077	\N	测试01	测试2	\N	\N	\N	normal				\N
1824	103	102	333	text	f	2025-11-24 19:29:12.359392	\N	测试2	测试01	\N	\N	\N	normal				\N
1825	102	103	😀	text	f	2025-11-24 19:31:27.227196	\N	测试01	测试2	\N	\N	\N	normal				\N
1826	103	104	555	text	f	2025-11-24 19:32:49.189666	\N	测试2	测试03	\N	\N	\N	normal				\N
1827	103	102	5555	text	f	2025-11-24 19:38:35.808875	\N	测试2	测试01	\N	\N	\N	normal				\N
1828	103	102	666	text	f	2025-11-24 19:38:56.030638	\N	测试2	测试01	\N	\N	\N	normal				\N
1829	103	102	777	text	f	2025-11-24 19:46:22.87716	\N	测试2	测试01	\N	\N	\N	normal				\N
1830	102	103	111	text	f	2025-11-24 20:26:12.091085	\N	测试01	测试2	\N	\N	\N	normal				\N
1831	102	103	333	text	f	2025-11-24 20:26:23.884625	\N	测试01	测试2	\N	\N	\N	normal				\N
1832	102	103	555	text	f	2025-11-24 20:26:35.453862	\N	测试01	测试2	\N	\N	\N	normal				\N
1833	103	102	666	text	t	2025-11-24 20:26:43.706494	2025-11-24 20:26:43.823071	测试2	测试01	\N	\N	\N	normal				\N
1834	103	102	777	text	f	2025-11-24 21:28:08.442312	\N	测试2	测试01	\N	\N	\N	normal				\N
1835	103	102	[emotion:29_Laugh.png]	text	f	2025-11-24 21:28:15.452982	\N	测试2	测试01	\N	\N	\N	normal				\N
1836	103	102	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763990903_ic_launcher.png	image	f	2025-11-24 21:28:25.919173	\N	测试2	测试01	\N	\N	\N	normal				\N
1837	103	102	88	text	f	2025-11-24 21:28:26.158038	\N	测试2	测试01	\N	\N	\N	normal				\N
1838	103	102	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1763990915_2637-161442811_tiny.mp4	video	f	2025-11-24 21:28:54.011069	\N	测试2	测试01	\N	\N	\N	normal				\N
1839	103	102	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/files/1763990946_test_voice_py	file	f	2025-11-24 21:29:09.606788	\N	测试2	测试01	test_voice_py	\N	\N	normal				\N
1840	102	103	111	text	f	2025-11-24 21:29:39.224277	\N	测试01	测试2	\N	\N	\N	normal				\N
1841	102	103	😁	text	f	2025-11-24 21:30:33.951968	\N	测试01	测试2	\N	\N	\N	normal				\N
1842	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1763991055_scaled_236d8877-6d39-436d-8918-8006426e82027980875032891819964.jpg	image	f	2025-11-24 21:31:00.049862	\N	测试01	测试2	\N	\N	\N	normal				\N
1843	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1763991139_1763990915_2637-161442811_tiny.mp4	video	f	2025-11-24 21:32:39.870368	\N	测试01	测试2	\N	\N	\N	normal				\N
1844	102	103	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/files/1763991169_1763990946_test_voice_py	file	f	2025-11-24 21:32:53.406274	\N	测试01	测试2	1763990946_test_voice_py	\N	\N	normal				\N
1845	103	102	00:16	call_ended	t	2025-11-24 21:33:25.776685	2025-11-24 21:33:25.95598	测试2	测试01	\N	\N	\N	normal				voice
1847	102	103	00:05	call_ended	f	2025-11-24 21:33:45.80217	\N	测试01	测试2	\N	\N	\N	normal				voice
1846	103	102	00:05	call_ended	t	2025-11-24 21:33:45.656376	2025-11-24 21:33:45.99822	测试2	测试01	\N	\N	\N	normal				voice
1848	103	102	00:05	call_ended	t	2025-11-24 21:34:06.606783	2025-11-24 21:34:06.697272	测试2	测试01	\N	\N	\N	normal				voice
1849	103	102	111	text	f	2025-11-24 21:56:07.501601	\N	测试2	测试01	\N	\N	\N	normal				\N
1850	104	102	测试03 请求添加您为好友	system	f	2025-11-24 21:56:27.589274	\N	测试03	测试01	\N	\N	\N	normal				\N
1851	102	104	请求添加好友【已驳回】	text	f	2025-11-24 21:57:21.204635	\N	测试01	测试03	\N	\N	\N	normal				\N
1852	104	102	测试03 请求添加您为好友	system	f	2025-11-24 22:02:27.636549	\N	测试03	测试01	\N	\N	\N	normal				\N
1853	104	102	00:09	call_ended	t	2025-11-24 22:02:49.207834	2025-11-24 22:02:49.394183	测试03	测试01	\N	\N	\N	normal				voice
1854	102	104	请求添加好友【已通过】	text	f	2025-11-24 22:06:11.085767	\N	测试01	测试03	\N	\N	\N	normal				\N
1855	104	102	请求添加好友【已通过】	text	f	2025-11-24 22:06:11.087895	\N	测试03	测试01	\N	\N	\N	normal				\N
1856	103	102	00:51	call_ended	t	2025-11-24 22:12:24.751771	2025-11-24 22:12:24.925238	测试2	测试01	\N	\N	\N	normal				voice
1857	103	102	00:11	call_ended	t	2025-11-24 22:20:52.45966	2025-11-24 22:20:52.603004	测试2	测试01	\N	\N	\N	normal				voice
1858	103	102	00:03	call_ended	t	2025-11-24 22:21:24.475064	2025-11-24 22:21:24.538795	测试2	测试01	\N	\N	\N	normal				voice
1859	105	102	测试04 请求添加您为好友	system	f	2025-11-24 22:22:26.117356	\N	测试04	测试01	\N	\N	\N	normal				\N
1860	102	105	请求添加好友【已通过】	text	f	2025-11-24 22:22:46.499346	\N	测试01	测试04	\N	\N	\N	normal				\N
1861	105	102	请求添加好友【已通过】	text	f	2025-11-24 22:22:46.502484	\N	测试04	测试01	\N	\N	\N	normal				\N
1862	105	102	00:02	call_ended	t	2025-11-24 22:23:56.084594	2025-11-24 22:23:56.23454	测试04	测试01	\N	\N	\N	normal				voice
1863	105	102	00:02	call_ended	t	2025-11-24 22:31:38.478474	2025-11-24 22:31:38.654021	测试04	测试01	\N	\N	\N	normal				voice
1864	105	102	111	text	f	2025-11-25 08:19:19.882386	\N	测试04	测试01	\N	\N	\N	normal				\N
1865	105	102	111	text	f	2025-11-25 08:34:47.738113	\N	测试04	测试01	\N	\N	\N	normal				\N
1866	102	105	2222	text	f	2025-11-25 08:56:47.429347	\N	测试01	测试04	\N	\N	\N	normal				\N
1867	102	105	111	text	f	2025-11-25 09:10:52.189658	\N	测试01	测试04	\N	\N	\N	normal				\N
1868	105	102	对方已拒绝	call_rejected	f	2025-11-25 09:15:13.567219	\N	测试04	测试01	\N	\N	\N	normal				\N
1869	105	102	11	text	t	2025-11-25 11:13:56.966287	2025-11-25 11:13:57.169017	测试04	测试01	\N	\N	\N	normal				\N
1870	102	105	22	text	f	2025-11-25 11:14:16.085094	\N	测试01	测试04	\N	\N	\N	normal				\N
1871	102	105	22	text	f	2025-11-25 11:14:16.707171	\N	测试01	测试04	\N	\N	\N	normal				\N
1872	105	102	33	text	t	2025-11-25 11:14:19.856665	2025-11-25 11:14:19.995614	测试04	测试01	\N	\N	\N	normal				\N
1873	106	102	测试05 请求添加您为好友	system	f	2025-11-25 11:14:41.565684	\N	测试05	测试01	\N	\N	\N	normal				\N
1874	102	106	请求添加好友【已驳回】	text	f	2025-11-25 11:15:04.796636	\N	测试01	测试05	\N	\N	\N	normal				\N
1875	106	102	111	text	f	2025-11-25 11:20:12.154115	\N	测试05	测试01	\N	\N	\N	normal				\N
1876	106	102	测试05 请求添加您为好友	system	f	2025-11-25 11:27:53.805621	\N	测试05	测试01	\N	\N	\N	normal				\N
1877	106	102	111	text	f	2025-11-25 11:29:29.046026	\N	测试05	测试01	\N	\N	\N	normal				\N
1878	107	102	测试06 请求添加您为好友,待审核	system	f	2025-11-25 12:00:14.384184	\N	测试06	测试01	\N	\N	\N	normal				\N
1879	107	102	测试06 请求添加您为好友,待审核	system	f	2025-11-25 12:07:32.284718	\N	测试06	测试01	\N	\N	\N	normal				\N
1880	107	102	请求添加好友【已拒绝】	text	f	2025-11-25 12:07:46.73071	\N	测试06	测试01	\N	\N	\N	normal				\N
1881	107	102	测试06 请求添加您为好友,待审核	system	f	2025-11-25 12:11:19.086946	\N	测试06	测试01	\N	\N	\N	normal				\N
1882	102	107	请求添加好友【已驳回】	text	f	2025-11-25 12:11:27.28312	\N	测试01	测试06	\N	\N	\N	normal				\N
1883	102	107	请求添加好友【已驳回】	text	f	2025-11-25 12:23:04.632949	\N	测试01	测试06	\N	\N	\N	normal				\N
1884	102	107	请求添加好友【已驳回】	text	f	2025-11-25 12:25:22.495078	\N	测试01	测试06	\N	\N	\N	normal				\N
1885	102	107	请求添加好友【已驳回】	text	f	2025-11-25 12:29:40.196891	\N	测试01	测试06	\N	\N	\N	normal				\N
1886	102	107	请求添加好友【已驳回】	text	f	2025-11-25 12:30:31.013846	\N	测试01	测试06	\N	\N	\N	normal				\N
1887	102	108	请求添加好友【已驳回】	text	f	2025-11-25 12:33:46.119294	\N	测试01	测试07	\N	\N	\N	normal				\N
1888	102	108	请求添加好友【已驳回】	text	f	2025-11-25 12:36:49.452974	\N	测试01	测试07	\N	\N	\N	normal				\N
1889	102	108	请求添加好友【已驳回】	text	f	2025-11-25 12:44:12.958758	\N	测试01	测试07	\N	\N	\N	normal				\N
1890	102	110	请求添加好友【已驳回】	text	f	2025-11-25 13:03:25.347484	\N	测试01	测试09	\N	\N	\N	normal				\N
1891	110	102	111	text	f	2025-11-25 13:03:32.838038	\N	测试09	测试01	\N	\N	\N	normal				\N
1892	110	102	222	text	f	2025-11-25 13:12:20.139711	\N	测试09	测试01	\N	\N	\N	normal				\N
1893	102	110	请求添加好友【已驳回】	text	f	2025-11-25 13:17:04.482964	\N	测试01	测试09	\N	\N	\N	normal				\N
1894	102	110	请求添加好友【已通过】	text	f	2025-11-25 13:17:49.376504	\N	测试01	测试09	\N	\N	\N	normal				\N
1895	110	102	请求添加好友【已通过】	text	f	2025-11-25 13:17:49.378057	\N	测试09	测试01	\N	\N	\N	normal				\N
1896	110	102	777	text	f	2025-11-25 13:17:57.716987	\N	测试09	测试01	\N	\N	\N	normal				\N
1897	111	112	请求添加好友【已驳回】	text	f	2025-11-25 13:23:06.719324	\N	测试20	测试21	\N	\N	\N	normal				\N
1898	111	112	请求添加好友【已通过】	text	f	2025-11-25 13:24:13.848335	\N	测试20	测试21	\N	\N	\N	normal				\N
1899	112	111	请求添加好友【已通过】	text	f	2025-11-25 13:24:13.850079	\N	测试21	测试20	\N	\N	\N	normal				\N
1900	112	111	111	text	f	2025-11-25 13:24:21.74996	\N	测试21	测试20	\N	\N	\N	normal				\N
1901	102	112	请求添加好友【已通过】	text	f	2025-11-25 13:39:44.05865	\N	测试01	测试21	\N	\N	\N	normal				\N
1902	112	102	请求添加好友【已通过】	text	f	2025-11-25 13:39:44.062264	\N	测试21	测试01	\N	\N	\N	normal				\N
1903	112	102	11	text	f	2025-11-25 14:14:30.505131	\N	测试21	测试01	\N	\N	\N	normal				\N
1904	112	102	333	text	f	2025-11-25 15:00:19.1173	\N	测试21	测试01	\N	\N	\N	normal				\N
1905	112	102	444	text	f	2025-11-25 15:00:31.04974	\N	测试21	测试01	\N	\N	\N	normal				\N
1906	112	102	666	text	f	2025-11-25 15:26:41.417799	\N	测试21	测试01	\N	\N	\N	normal				\N
1907	112	102	777	text	f	2025-11-25 15:26:47.980479	\N	测试21	测试01	\N	\N	\N	normal				\N
1908	112	102	88	text	f	2025-11-25 15:27:21.068688	\N	测试21	测试01	\N	\N	\N	normal				\N
1909	102	112	999	text	f	2025-11-25 15:32:25.553126	\N	测试01	测试21	\N	\N	\N	normal				\N
1910	113	113	请求添加好友【已驳回】	text	f	2025-11-25 18:07:00.77581	\N	测试22	测试22	\N	\N	\N	normal				\N
1911	113	113	请求添加好友【已驳回】	text	f	2025-11-25 18:15:58.027404	\N	测试22	测试22	\N	\N	\N	normal				\N
1912	114	113	请求添加好友【已驳回】	text	f	2025-11-25 18:24:47.215059	\N	测试23	测试22	\N	\N	\N	normal				\N
1913	114	113	请求添加好友【已通过】	text	f	2025-11-25 18:25:23.627795	\N	测试23	测试22	\N	\N	\N	normal				\N
1914	113	114	请求添加好友【已通过】	text	f	2025-11-25 18:25:23.62983	\N	测试22	测试23	\N	\N	\N	normal				\N
1915	114	113	1	text	f	2025-11-25 18:25:45.67401	\N	测试23	测试22	\N	\N	\N	normal				\N
1916	114	113	2	text	f	2025-11-25 18:25:55.152569	\N	测试23	测试22	\N	\N	\N	normal				\N
1917	114	113	3	text	f	2025-11-25 18:28:55.079605	\N	测试23	测试22	\N	\N	\N	normal				\N
1918	114	113	4	text	f	2025-11-25 18:29:02.072258	\N	测试23	测试22	\N	\N	\N	normal				\N
1919	113	114	5	text	t	2025-11-25 18:29:12.566669	2025-11-25 18:29:13.754836	测试22	测试23	\N	\N	\N	normal				\N
1920	113	114	6	text	t	2025-11-25 18:29:18.281247	2025-11-25 18:29:19.494776	测试22	测试23	\N	\N	\N	normal				\N
1921	113	114	[emotion:1_Smile.png]	text	t	2025-11-25 18:29:24.966488	2025-11-25 18:29:26.120461	测试22	测试23	\N	\N	\N	normal				\N
1922	113	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764066577_ic_launcher.png	image	t	2025-11-25 18:29:39.895337	2025-11-25 18:29:41.018436	测试22	测试23	\N	\N	\N	normal				\N
1923	113	114	77	text	t	2025-11-25 18:29:40.030547	2025-11-25 18:29:42.13867	测试22	测试23	\N	\N	\N	normal				\N
1924	114	113	😃	text	f	2025-11-25 18:29:59.260148	\N	测试23	测试22	\N	\N	\N	normal				\N
1925	114	113	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764066622_scaled_5c9373f9-b2a9-4e67-b46e-d7923c55a4703584403794167940725.jpg	image	f	2025-11-25 18:30:27.794427	\N	测试23	测试22	\N	\N	\N	normal				\N
1926	114	113	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764066655_JPEG_20251125_183056_8109158235297963793.jpg	image	f	2025-11-25 18:30:58.088917	\N	测试23	测试22	\N	\N	\N	normal				\N
1927	113	114	00:02	call_ended	t	2025-11-25 18:31:20.243111	2025-11-25 18:31:21.610223	测试22	测试23	\N	\N	\N	normal				voice
1928	113	114	00:01	call_ended_video	t	2025-11-25 18:31:33.652046	2025-11-25 18:31:35.049789	测试22	测试23	\N	\N	\N	normal				video
1930	114	113	00:02	call_ended	f	2025-11-25 18:31:50.737302	\N	测试23	测试22	\N	\N	\N	normal				voice
1931	114	113	00:02	call_ended	f	2025-11-25 18:31:50.972617	\N	测试23	测试22	\N	\N	\N	normal				voice
1929	113	114	00:02	call_ended	t	2025-11-25 18:31:50.726785	2025-11-25 18:31:52.163477	测试22	测试23	\N	\N	\N	normal				voice
1932	114	113	00:05	call_ended_video	f	2025-11-25 18:32:07.740449	\N	测试23	测试22	\N	\N	\N	normal				video
1934	114	113	00:05	call_ended_video	f	2025-11-25 18:32:08.045294	\N	测试23	测试22	\N	\N	\N	normal				video
1933	113	114	00:05	call_ended_video	t	2025-11-25 18:32:07.74098	2025-11-25 18:32:09.15375	测试22	测试23	\N	\N	\N	normal				video
1935	114	113	请求添加好友【已通过】	text	f	2025-11-25 20:30:58.230263	\N	测试23	测试22	\N	\N	\N	normal				\N
1936	113	114	请求添加好友【已通过】	text	f	2025-11-25 20:30:58.239622	\N	测试22	测试23	\N	\N	\N	normal				\N
1937	113	114	111	text	f	2025-11-25 20:31:04.195182	\N	测试22	测试23	\N	\N	\N	normal				\N
1938	113	114	22	text	f	2025-11-25 20:31:11.838359	\N	测试22	测试23	\N	\N	\N	normal				\N
1939	113	114	999	text	f	2025-11-25 20:36:55.163121	\N	测试22	测试23	\N	\N	\N	normal				\N
1940	113	114	000	text	f	2025-11-25 20:37:10.688469	\N	测试22	测试23	\N	\N	\N	normal				\N
1941	113	114	999	text	t	2025-11-25 20:37:36.860868	2025-11-25 20:37:38.508453	测试22	测试23	\N	\N	\N	normal				\N
1942	113	114	111	text	f	2025-11-25 20:40:38.814614	\N	测试22	测试23	\N	\N	\N	normal				\N
1943	113	114	222	text	f	2025-11-25 20:44:24.81414	\N	测试22	测试23	\N	\N	\N	normal				\N
1944	113	114	33	text	f	2025-11-25 20:44:52.658456	\N	测试22	测试23	\N	\N	\N	normal				\N
1945	113	114	444	text	t	2025-11-25 20:45:06.030933	2025-11-25 20:45:06.122649	测试22	测试23	\N	\N	\N	normal				\N
1946	113	114	555	text	t	2025-11-25 20:45:14.593804	2025-11-25 20:45:14.73758	测试22	测试23	\N	\N	\N	normal				\N
1947	113	114	666	text	f	2025-11-25 20:48:38.570261	\N	测试22	测试23	\N	\N	\N	normal				\N
1948	113	114	888	text	f	2025-11-25 20:48:49.079406	\N	测试22	测试23	\N	\N	\N	normal				\N
1949	113	114	999	text	f	2025-11-25 20:48:58.314793	\N	测试22	测试23	\N	\N	\N	normal				\N
1950	113	114	000	text	f	2025-11-25 20:55:11.542241	\N	测试22	测试23	\N	\N	\N	normal				\N
1951	113	114	111	text	f	2025-11-25 20:55:16.572383	\N	测试22	测试23	\N	\N	\N	normal				\N
1952	113	114	222	text	f	2025-11-25 20:55:22.039835	\N	测试22	测试23	\N	\N	\N	normal				\N
1953	113	114	333	text	t	2025-11-25 20:56:30.069188	2025-11-25 20:56:30.199542	测试22	测试23	\N	\N	\N	normal				\N
1954	113	114	44	text	t	2025-11-25 20:59:30.390662	2025-11-25 20:59:30.698297	测试22	测试23	\N	\N	\N	normal				\N
1955	113	114	55	text	t	2025-11-25 21:05:10.714131	2025-11-25 21:05:11.100257	测试22	测试23	\N	\N	\N	normal				\N
1956	113	114	66	text	t	2025-11-25 21:05:14.934423	2025-11-25 21:05:15.335034	测试22	测试23	\N	\N	\N	normal				\N
1957	113	114	777	text	t	2025-11-25 21:12:42.840403	2025-11-25 21:12:42.973506	测试22	测试23	\N	\N	\N	normal				\N
1958	114	113	请求添加好友【已通过】	text	f	2025-11-25 22:34:30.28956	\N	测试23	测试22	\N	\N	\N	normal				\N
1959	113	114	请求添加好友【已通过】	text	f	2025-11-25 22:34:30.294191	\N	测试22	测试23	\N	\N	\N	normal				\N
1960	114	113	请求添加好友【已通过】	text	f	2025-11-25 22:55:50.082671	\N	测试23	测试22	\N	\N	\N	normal				\N
1961	113	114	请求添加好友【已通过】	text	f	2025-11-25 22:55:50.085073	\N	测试22	测试23	\N	\N	\N	normal				\N
1962	114	113	请求添加好友【已驳回】	text	f	2025-11-25 22:56:41.468425	\N	测试23	测试22	\N	\N	\N	normal				\N
1963	114	113	请求添加好友【已驳回】	text	f	2025-11-25 22:57:34.9493	\N	测试23	测试22	\N	\N	\N	normal				\N
1964	114	113	请求添加好友【已通过】	text	f	2025-11-25 22:59:48.978688	\N	测试23	测试22	\N	\N	\N	normal				\N
1965	113	114	请求添加好友【已通过】	text	f	2025-11-25 22:59:48.980343	\N	测试22	测试23	\N	\N	\N	normal				\N
1966	113	114	111	text	f	2025-11-25 22:59:58.260783	\N	测试22	测试23	\N	\N	\N	normal				\N
1967	113	114	222	text	f	2025-11-25 23:00:29.521927	\N	测试22	测试23	\N	\N	\N	normal				\N
1968	113	114	333	text	f	2025-11-25 23:00:53.868439	\N	测试22	测试23	\N	\N	\N	normal				\N
1969	113	114	444	text	f	2025-11-25 23:02:14.220962	\N	测试22	测试23	\N	\N	\N	normal				\N
1970	113	114	555	text	f	2025-11-25 23:03:43.272079	\N	测试22	测试23	\N	\N	\N	normal				\N
1971	113	114	66	text	f	2025-11-25 23:05:00.798408	\N	测试22	测试23	\N	\N	\N	normal				\N
1972	113	114	77	text	f	2025-11-25 23:05:09.578034	\N	测试22	测试23	\N	\N	\N	normal				\N
1973	113	114	88	text	f	2025-11-25 23:07:02.074112	\N	测试22	测试23	\N	\N	\N	normal				\N
1974	113	114	00	text	f	2025-11-25 23:11:22.713101	\N	测试22	测试23	\N	\N	\N	normal				\N
1975	113	114	111	text	f	2025-11-25 23:11:32.75305	\N	测试22	测试23	\N	\N	\N	normal				\N
1976	113	114	22	text	t	2025-11-25 23:12:04.194139	2025-11-25 23:12:04.303297	测试22	测试23	\N	\N	\N	normal				\N
1977	113	114	33	text	t	2025-11-25 23:15:03.269903	2025-11-25 23:15:03.62112	测试22	测试23	\N	\N	\N	normal				\N
1978	113	114	44	text	f	2025-11-25 23:15:35.835828	\N	测试22	测试23	\N	\N	\N	normal				\N
1979	113	114	55	text	f	2025-11-25 23:15:42.834547	\N	测试22	测试23	\N	\N	\N	normal				\N
1980	113	114	22	text	f	2025-11-26 07:38:22.966654	\N	测试22	测试23	\N	\N	\N	normal				\N
1981	114	107	请求添加好友【已通过】	text	f	2025-11-26 08:01:46.582499	\N	测试23	测试06	\N	\N	\N	normal				\N
1982	107	114	请求添加好友【已通过】	text	f	2025-11-26 08:01:46.586933	\N	测试06	测试23	\N	\N	\N	normal				\N
1983	114	107	111	text	f	2025-11-26 08:02:07.381862	\N	测试23	测试06	\N	\N	\N	normal				\N
1984	114	106	请求添加好友【已通过】	text	f	2025-11-26 08:05:12.511448	\N	测试23	测试05	\N	\N	\N	normal				\N
1985	106	114	请求添加好友【已通过】	text	f	2025-11-26 08:05:12.514915	\N	测试05	测试23	\N	\N	\N	normal				\N
1986	114	105	请求添加好友【已通过】	text	f	2025-11-26 08:05:14.452565	\N	测试23	测试04	\N	\N	\N	normal				\N
1987	105	114	请求添加好友【已通过】	text	f	2025-11-26 08:05:14.454765	\N	测试04	测试23	\N	\N	\N	normal				\N
1988	114	104	请求添加好友【已通过】	text	f	2025-11-26 08:05:16.169219	\N	测试23	测试03	\N	\N	\N	normal				\N
1989	104	114	请求添加好友【已通过】	text	f	2025-11-26 08:05:16.17211	\N	测试03	测试23	\N	\N	\N	normal				\N
1990	114	103	请求添加好友【已通过】	text	f	2025-11-26 08:05:17.69953	\N	测试23	测试2	\N	\N	\N	normal				\N
1991	103	114	请求添加好友【已通过】	text	f	2025-11-26 08:05:17.700701	\N	测试2	测试23	\N	\N	\N	normal				\N
1992	109	114	请求添加好友【已驳回】	text	f	2025-11-26 08:17:56.284543	\N	测试08	测试23	\N	\N	\N	normal				\N
1993	109	114	请求添加好友【已通过】	text	f	2025-11-26 08:18:47.101008	\N	测试08	测试23	\N	\N	\N	normal				\N
1994	114	109	请求添加好友【已通过】	text	f	2025-11-26 08:18:47.103144	\N	测试23	测试08	\N	\N	\N	normal				\N
1995	113	114	22	text	f	2025-11-26 10:19:07.773563	\N	测试22	测试23	\N	\N	\N	normal				\N
1996	113	114	44	text	f	2025-11-26 10:19:19.71841	\N	测试22	测试23	\N	\N	\N	normal				\N
1997	113	114	555	text	f	2025-11-26 10:21:01.306717	\N	测试22	测试23	\N	\N	\N	normal				\N
1998	114	113	6666	text	f	2025-11-26 10:21:23.919344	\N	测试23	测试22	\N	\N	\N	normal				\N
1999	114	113	7777	text	f	2025-11-26 10:32:44.468963	\N	测试23	测试22	\N	\N	\N	normal				\N
2000	113	103	请求添加好友【已通过】	text	f	2025-11-26 10:37:08.008365	\N	测试22	测试2	\N	\N	\N	normal				\N
2001	103	113	请求添加好友【已通过】	text	f	2025-11-26 10:37:08.010234	\N	测试2	测试22	\N	\N	\N	normal				\N
2002	113	103	11	text	f	2025-11-26 10:37:28.837142	\N	测试22	测试2	\N	\N	\N	normal				\N
2003	104	113	请求添加好友【已通过】	text	f	2025-11-26 10:52:25.568023	\N	测试03	测试22	\N	\N	\N	normal				\N
2004	113	104	请求添加好友【已通过】	text	f	2025-11-26 10:52:25.570089	\N	测试22	测试03	\N	\N	\N	normal				\N
2005	113	104	111	text	f	2025-11-26 10:52:42.725239	\N	测试22	测试03	\N	\N	\N	normal				\N
2006	103	113	444	text	f	2025-11-26 10:59:24.549707	\N	测试2	测试22	\N	\N	\N	normal				\N
2007	103	113	5555	text	f	2025-11-26 11:00:33.272851	\N	测试2	测试22	\N	\N	\N	normal				\N
2008	103	113	www	text	f	2025-11-26 11:02:28.895357	\N	测试2	测试22	\N	\N	\N	normal				\N
2009	103	113	aaaa	text	f	2025-11-26 11:02:37.720391	\N	测试2	测试22	\N	\N	\N	normal				\N
2010	113	103	11	text	f	2025-11-26 11:03:42.224729	\N	测试22	测试2	\N	\N	\N	normal				\N
2011	113	103	22	text	f	2025-11-26 11:03:51.40169	\N	测试22	测试2	\N	\N	\N	normal				\N
2012	113	103	33	text	f	2025-11-26 11:05:01.870463	\N	测试22	测试2	\N	\N	\N	normal				\N
2013	113	103	444	text	f	2025-11-26 11:05:24.33803	\N	测试22	测试2	\N	\N	\N	normal				\N
2014	113	103	22	text	f	2025-11-26 11:10:58.008582	\N	测试22	测试2	\N	\N	\N	normal				\N
2015	113	103	333	text	f	2025-11-26 11:11:03.554296	\N	测试22	测试2	\N	\N	\N	normal				\N
2016	113	103	444	text	f	2025-11-26 11:11:04.946804	\N	测试22	测试2	\N	\N	\N	normal				\N
2017	113	103	55	text	f	2025-11-26 11:11:05.86365	\N	测试22	测试2	\N	\N	\N	normal				\N
2018	113	103	666	text	f	2025-11-26 11:11:26.055705	\N	测试22	测试2	\N	\N	\N	normal				\N
2019	113	103	77	text	f	2025-11-26 11:13:38.098835	\N	测试22	测试2	\N	\N	\N	normal				\N
2020	113	103	88	text	t	2025-11-26 11:13:49.536993	2025-11-26 11:13:49.648458	测试22	测试2	\N	\N	\N	normal				\N
2022	113	103	00	text	f	2025-11-26 11:14:00.713159	\N	测试22	测试2	\N	\N	\N	normal				\N
2021	113	103	99	text	t	2025-11-26 11:13:50.596686	2025-11-26 11:13:50.761916	测试22	测试2	\N	\N	\N	normal				\N
2023	113	103	11	text	f	2025-11-26 11:14:33.472011	\N	测试22	测试2	\N	\N	\N	normal				\N
2024	113	103	222	text	f	2025-11-26 11:14:49.42206	\N	测试22	测试2	\N	\N	\N	normal				\N
2026	113	103	444	text	f	2025-11-26 11:20:01.903223	\N	测试22	测试2	\N	\N	\N	normal				\N
2025	113	103	333	text	f	2025-11-26 11:15:08.610481	\N	测试22	测试2	\N	\N	\N	normal				\N
2027	113	103	555	text	f	2025-11-26 11:31:11.090144	\N	测试22	测试2	\N	\N	\N	normal				\N
2028	113	103	666	text	f	2025-11-26 11:31:19.479582	\N	测试22	测试2	\N	\N	\N	normal				\N
2029	113	114	11	text	f	2025-11-26 11:57:33.582197	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129384_JPEG_20251126_115624_1671823011779936550.jpg		\N
2030	113	114	123	text	f	2025-11-26 12:02:29.405953	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2031	113	114	34346	text	f	2025-11-26 12:02:31.35331	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2032	114	113	tygg	text	f	2025-11-26 12:02:38.645398	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2033	114	113	festival	text	f	2025-11-26 12:02:40.985446	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2034	114	113	sad	text	f	2025-11-26 12:08:51.230361	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2035	114	113	sad	text	f	2025-11-26 12:08:51.671237	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2036	114	113	dd	text	f	2025-11-26 12:08:52.655296	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2037	114	113	ssddddffddeed	text	f	2025-11-26 12:09:19.932927	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2038	113	114	333	text	t	2025-11-26 12:11:09.047954	2025-11-26 12:11:09.17067	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2039	114	113	tgdd	text	f	2025-11-26 12:11:25.500475	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2040	114	113	shhd	text	f	2025-11-26 12:11:37.368328	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2041	114	113	shhdddd	text	f	2025-11-26 12:11:38.296014	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2042	114	113	sd	text	f	2025-11-26 12:11:39.433408	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2043	114	113	sdsdd	text	f	2025-11-26 12:11:40.280287	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2044	113	114	1112	text	f	2025-11-26 12:17:05.8188	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2045	113	114	333	text	f	2025-11-26 12:17:13.974809	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2046	114	113	dude	text	f	2025-11-26 12:17:31.997895	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2047	114	113	sss	text	f	2025-11-26 12:17:34.650743	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2048	114	113	ddxx	text	f	2025-11-26 12:17:36.585184	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2049	114	113	ddfc	text	f	2025-11-26 12:17:38.729108	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2050	113	114	123	text	t	2025-11-26 12:17:54.949594	2025-11-26 12:17:55.006089	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2051	113	114	123	text	t	2025-11-26 12:17:56.072729	2025-11-26 12:17:56.243414	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2052	113	114	312	text	t	2025-11-26 12:17:57.444656	2025-11-26 12:17:57.674886	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2053	113	114	123	text	t	2025-11-26 12:17:58.761001	2025-11-26 12:17:59.029411	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2055	113	114	2222	text	f	2025-11-26 12:32:39.963274	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2054	113	114	asd	text	t	2025-11-26 12:18:33.948495	2025-11-26 12:18:33.99656	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2056	113	114	333	text	f	2025-11-26 12:32:41.675497	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2057	113	114	44	text	f	2025-11-26 12:33:35.695892	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2058	113	114	5	text	f	2025-11-26 12:37:35.438006	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2059	113	114	55	text	f	2025-11-26 12:37:37.634144	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2060	113	114	77	text	f	2025-11-26 12:42:18.766272	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2061	113	114	88	text	f	2025-11-26 12:42:22.016746	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2062	113	103	77	text	f	2025-11-26 12:42:25.245639	\N	测试22	测试2	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129327_JPEG_20251126_115527_5144140681260080541.jpg	\N
2063	113	103	88	text	f	2025-11-26 12:42:27.080559	\N	测试22	测试2	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129327_JPEG_20251126_115527_5144140681260080541.jpg	\N
2064	113	104	11	text	f	2025-11-26 12:42:29.613855	\N	测试22	测试03	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png		\N
2065	113	104	22	text	f	2025-11-26 12:42:31.791924	\N	测试22	测试03	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png		\N
2066	113	114	[emotion:1_Smile.png]	text	f	2025-11-26 12:43:06.073171	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2067	113	114	55	text	f	2025-11-26 12:43:57.599686	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2068	113	114	66	text	f	2025-11-26 12:44:20.58074	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2069	114	113	ffdd	text	f	2025-11-26 12:49:22.234261	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2070	114	113	hgff	text	f	2025-11-26 12:49:31.634436	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2071	113	114	11	text	f	2025-11-26 13:08:17.745956	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2072	113	114	33	text	f	2025-11-26 13:11:32.492014	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2073	113	114	333	text	f	2025-11-26 13:17:13.662404	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2074	113	114	钱钱钱	text	f	2025-11-26 13:23:55.474149	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2075	113	114	1	text	f	2025-11-26 13:23:57.667056	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2076	113	114	2222	text	f	2025-11-26 13:24:00.067869	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2077	113	114	333	text	f	2025-11-26 13:24:01.057895	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2078	114	113	444	text	f	2025-11-26 13:24:13.362623	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2079	114	113	555	text	f	2025-11-26 13:24:16.282265	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2080	113	114	666	text	f	2025-11-26 13:28:31.043972	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2081	113	114	777	text	f	2025-11-26 13:28:36.135703	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2082	113	114	88	text	f	2025-11-26 13:29:50.325813	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2083	113	114	999	text	f	2025-11-26 13:31:40.203752	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2084	113	114	00	text	f	2025-11-26 13:32:11.921133	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2085	113	114	111	text	f	2025-11-26 13:32:50.243124	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2086	113	114	222	text	f	2025-11-26 13:32:56.957358	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2087	113	114	33	text	f	2025-11-26 13:33:04.379139	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2090	114	113	666	text	f	2025-11-26 13:33:45.795866	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2092	114	113	hhgg	text	f	2025-11-26 13:42:44.177772	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2093	114	113	6767)	text	f	2025-11-26 13:42:54.344521	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2094	114	113	566	text	f	2025-11-26 13:42:58.0289	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2095	114	113	7766	text	f	2025-11-26 13:43:01.112829	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2088	113	114	44	text	f	2025-11-26 13:33:27.066923	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2089	114	113	5555	text	f	2025-11-26 13:33:40.561138	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2091	114	113	hhgg	text	f	2025-11-26 13:42:43.056196	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2096	113	114	00	text	f	2025-11-26 13:48:35.630699	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2097	113	114	11	text	t	2025-11-26 13:48:42.211779	2025-11-26 13:48:42.269561	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2098	113	114	22	text	t	2025-11-26 13:48:43.565998	2025-11-26 13:48:43.721742	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2099	113	114	33	text	t	2025-11-26 13:48:45.066302	2025-11-26 13:48:45.158014	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2100	113	114	44	text	t	2025-11-26 13:48:46.491504	2025-11-26 13:48:46.576137	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2101	113	114	55	text	t	2025-11-26 13:48:47.725571	2025-11-26 13:48:47.81653	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2102	113	114	66	text	t	2025-11-26 13:48:49.326687	2025-11-26 13:48:49.457572	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2103	113	114	77	text	t	2025-11-26 13:48:50.701975	2025-11-26 13:48:50.786104	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2104	113	114	88	text	t	2025-11-26 13:48:52.06733	2025-11-26 13:48:52.221898	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2105	113	114	99	text	t	2025-11-26 13:48:53.466157	2025-11-26 13:48:53.514493	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2106	113	114	00	text	t	2025-11-26 13:48:54.911368	2025-11-26 13:48:54.978488	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2107	113	114	11	text	t	2025-11-26 13:48:56.394392	2025-11-26 13:48:56.523224	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2108	113	114	22	text	t	2025-11-26 13:48:57.783716	2025-11-26 13:48:57.846414	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2109	113	114	33	text	t	2025-11-26 13:48:59.205524	2025-11-26 13:48:59.282603	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2110	113	114	44	text	t	2025-11-26 13:49:00.563982	2025-11-26 13:49:00.722997	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2111	113	114	55	text	t	2025-11-26 13:49:02.100919	2025-11-26 13:49:02.259779	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2112	113	114	66	text	t	2025-11-26 13:49:03.48287	2025-11-26 13:49:03.590811	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2113	113	114	77	text	t	2025-11-26 13:49:04.770714	2025-11-26 13:49:04.918977	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2114	113	114	88	text	t	2025-11-26 13:49:06.05123	2025-11-26 13:49:06.150949	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2115	113	114	99	text	t	2025-11-26 13:49:07.43417	2025-11-26 13:49:07.586438	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2116	113	114	00	text	t	2025-11-26 13:49:08.822913	2025-11-26 13:49:08.908534	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2117	113	114	11	text	t	2025-11-26 13:49:10.150306	2025-11-26 13:49:10.244224	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2118	113	114	22	text	t	2025-11-26 13:49:11.439107	2025-11-26 13:49:11.57056	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2119	113	114	33	text	t	2025-11-26 13:49:12.694618	2025-11-26 13:49:12.795306	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2120	113	114	44	text	t	2025-11-26 13:49:14.02286	2025-11-26 13:49:14.143384	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2121	113	114	55	text	t	2025-11-26 13:49:15.405753	2025-11-26 13:49:15.560621	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2122	113	114	66	text	t	2025-11-26 13:49:16.744301	2025-11-26 13:49:16.89366	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2123	113	114	77	text	t	2025-11-26 13:49:18.103732	2025-11-26 13:49:18.237082	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2124	113	114	88	text	t	2025-11-26 13:49:19.567801	2025-11-26 13:49:19.664636	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2125	113	114	99	text	t	2025-11-26 13:49:20.882722	2025-11-26 13:49:20.993921	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2126	113	114	00	text	t	2025-11-26 13:49:22.210617	2025-11-26 13:49:22.325941	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2127	114	113	11	text	f	2025-11-26 13:49:31.027987	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2128	114	113	22	text	f	2025-11-26 13:49:32.583428	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2129	114	113	33	text	f	2025-11-26 13:49:34.037897	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2130	114	113	44	text	f	2025-11-26 13:49:35.368024	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2131	114	113	55	text	f	2025-11-26 13:49:36.686834	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2132	114	113	66	text	f	2025-11-26 13:49:38.504308	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2133	114	113	77	text	f	2025-11-26 13:49:40.613466	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2134	114	113	88	text	f	2025-11-26 13:49:42.015401	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2135	114	113	99	text	f	2025-11-26 13:49:43.419393	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2136	114	113	00	text	f	2025-11-26 13:49:45.048781	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2137	114	113	11	text	f	2025-11-26 13:49:46.982381	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2138	114	113	22	text	f	2025-11-26 13:49:48.413129	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2139	114	113	33	text	f	2025-11-26 13:49:50.378631	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2140	114	113	44	text	f	2025-11-26 13:49:51.776059	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2141	114	113	55	text	f	2025-11-26 13:49:53.21882	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2142	114	113	66	text	f	2025-11-26 13:49:57.426747	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2143	114	113	77	text	f	2025-11-26 13:50:00.597366	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2144	114	113	88	text	f	2025-11-26 13:50:02.114093	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2145	114	113	99	text	f	2025-11-26 13:50:04.184238	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2146	114	113	00	text	f	2025-11-26 13:50:06.187312	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2147	114	113	11	text	f	2025-11-26 13:50:07.594532	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2148	114	113	22	text	f	2025-11-26 13:50:09.440824	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2149	114	113	33	text	f	2025-11-26 13:50:10.93258	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2150	114	113	44	text	f	2025-11-26 13:50:12.576008	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2151	114	113	55	text	f	2025-11-26 13:50:13.988357	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2152	114	113	66	text	f	2025-11-26 13:50:15.321763	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2153	114	113	77	text	f	2025-11-26 13:50:16.50511	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2154	114	113	88	text	f	2025-11-26 13:50:17.822916	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2155	114	113	99	text	f	2025-11-26 13:50:19.07915	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2156	114	113	00	text	f	2025-11-26 13:50:20.229835	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2157	114	113	11	text	f	2025-11-26 13:50:21.544745	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2158	114	113	22	text	f	2025-11-26 13:50:22.473258	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2159	114	113	22	text	f	2025-11-26 13:50:22.666793	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2160	114	113	44	text	f	2025-11-26 13:50:24.324923	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2161	114	113	55	text	f	2025-11-26 13:50:25.493088	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2162	114	113	66	text	f	2025-11-26 13:50:26.557144	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2163	114	113	7788	text	f	2025-11-26 13:50:30.185479	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2164	114	113	99	text	f	2025-11-26 13:50:33.317841	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2165	114	113	00	text	f	2025-11-26 13:50:34.744745	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2166	114	113	11	text	f	2025-11-26 13:50:35.921087	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2167	114	113	22	text	f	2025-11-26 13:50:37.03959	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2168	114	113	aa	text	f	2025-11-26 13:55:49.02796	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2169	114	113	qq	text	f	2025-11-26 13:55:52.49383	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2170	114	113	ww	text	f	2025-11-26 13:56:13.039468	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2171	113	114	111	text	f	2025-11-26 14:18:31.605209	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2172	113	114	22	text	f	2025-11-26 14:18:33.697774	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2173	113	114	33	text	f	2025-11-26 14:18:34.952541	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2174	114	113	444	text	f	2025-11-26 14:18:41.854331	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2175	114	113	555	text	f	2025-11-26 14:18:44.293792	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2176	114	113	666	text	f	2025-11-26 14:18:47.092192	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2177	114	113	777	text	f	2025-11-26 14:18:49.605545	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2178	113	114	11	text	f	2025-11-26 14:19:14.568415	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2179	114	113	😃	text	f	2025-11-26 14:19:35.384441	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2180	114	113	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764137985_JPEG_20251126_141946_7857814876190130443.jpg	image	f	2025-11-26 14:19:48.41228	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2181	113	114	[emotion:42_NosePick.png]	text	t	2025-11-26 14:20:21.80073	2025-11-26 14:20:21.944664	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2182	113	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764138031_ic_launcher.png	image	t	2025-11-26 14:20:33.825406	2025-11-26 14:20:33.886823	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2183	113	114	322	text	t	2025-11-26 14:20:33.973379	2025-11-26 14:20:34.205845	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2184	113	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1764138046_2637-161442811_tiny.mp4	video	t	2025-11-26 14:20:52.710133	2025-11-26 14:20:52.836029	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2185	113	114	444	text	t	2025-11-26 14:20:52.874186	2025-11-26 14:20:53.113163	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2186	113	114	55	text	f	2025-11-26 14:30:22.069686	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2187	113	114	66	text	f	2025-11-26 14:30:23.426573	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2188	114	113	11	text	f	2025-11-26 14:30:51.059213	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2189	114	113	33	text	f	2025-11-26 14:30:54.200699	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2190	113	114	00:12	call_ended_video	t	2025-11-26 14:32:29.968865	2025-11-26 14:32:30.110749	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	video
2191	114	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764140667_JPEG_20251126_150428_1878458380162378301.jpg	image	f	2025-11-26 15:04:30.360006	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2192	114	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764140691_scaled_4704a5e0-6434-4e7b-af3c-c0ea29afff4d5426499907645439188.jpg	image	f	2025-11-26 15:04:55.661859	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2193	114	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764140981_JPEG_20251126_150941_8789028214721261209.jpg	image	f	2025-11-26 15:09:44.106995	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2194	114	114	44333	text	f	2025-11-26 15:10:54.353877	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2195	114	114	zxff	text	f	2025-11-26 15:14:22.031984	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2196	114	114	zxff	text	f	2025-11-26 15:14:22.697154	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2197	114	114	hgxf	text	f	2025-11-26 15:14:26.578792	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2198	114	114	5555	text	f	2025-11-26 15:15:00.256163	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2199	114	114	666	text	f	2025-11-26 15:15:17.270003	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2200	114	114	7777	text	f	2025-11-26 15:17:54.204155	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2201	114	114	hhg	text	f	2025-11-26 15:18:05.238051	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2202	114	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764141493_JPEG_20251126_151813_4656255887350295458.jpg	image	f	2025-11-26 15:18:15.796709	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2203	113	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764141610_ic_launcher.png	image	f	2025-11-26 15:20:12.413807	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2204	113	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1764141620_2637-161442811_tiny.mp4	video	f	2025-11-26 15:20:27.200615	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2205	113	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/files/1764141639_test_voice_py	file	f	2025-11-26 15:20:41.473234	\N	测试22	测试23	test_voice_py	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2206	114	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764141705_JPEG_20251126_152145_3615330885970552040.jpg	image	f	2025-11-26 15:21:47.333719	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2207	114	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764141765_JPEG_20251126_152245_8946593931332298050.jpg	image	f	2025-11-26 15:22:47.279398	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2208	114	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1764141780_1764141620_2637-161442811_tiny.mp4	video	f	2025-11-26 15:23:05.872133	\N	测试23	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2209	114	114	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/files/1764141793_1764141639_test_voice_py	file	f	2025-11-26 15:23:15.601086	\N	测试23	测试23	1764141639_test_voice_py	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2210	114	113	111	text	f	2025-11-26 15:24:04.4462	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2211	113	114	22	text	t	2025-11-26 15:24:33.883983	2025-11-26 15:24:33.984988	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2212	114	113	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/images/1764141891_JPEG_20251126_152451_3707027135882267997.jpg	image	f	2025-11-26 15:24:54.006747	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2213	113	114	123	text	f	2025-11-26 15:50:57.649146	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2214	113	114	111	text	f	2025-11-26 16:07:26.591638	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2215	113	114	22	text	f	2025-11-26 16:07:28.755541	\N	测试22	测试23	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	\N
2216	114	113	yytf	text	f	2025-11-26 16:07:39.196197	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
2217	114	113	rcc	text	f	2025-11-26 16:07:42.19285	\N	测试23	测试22	\N	\N	\N	normal		https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	\N
\.


--
-- Data for Name: server_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.server_settings (id, key, value, description, updated_at) FROM stdin;
\.


--
-- Data for Name: user_relations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_relations (id, user_id, friend_id, created_at, approval_status, is_blocked, is_deleted) FROM stdin;
122	113	114	2025-11-25 22:59:25.980513	approved	f	f
127	107	114	2025-11-26 07:57:48.987097	approved	f	f
126	106	114	2025-11-26 07:50:43.137135	approved	f	f
125	105	114	2025-11-26 07:50:11.61794	approved	f	f
124	104	114	2025-11-26 07:46:28.257045	approved	f	f
123	103	114	2025-11-26 07:39:06.583251	approved	f	f
128	114	108	2025-11-26 08:05:40.624679	pending	f	f
129	114	109	2025-11-26 08:18:32.491231	approved	f	f
130	103	113	2025-11-26 10:37:02.805426	approved	f	f
131	113	104	2025-11-26 10:52:16.870739	approved	f	f
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, password, phone, email, avatar, created_at, updated_at, auth_code, full_name, gender, work_signature, status, landline, short_number, department, "position", region) FROM stdin;
112	test21	$2a$10$Eaj1zQhgPJEqdQWaLa8P6.NIUf4Drc38eChifjExQSKJsWdDvlYxa	\N	\N		2025-11-25 13:19:49.620411	2025-11-25 17:54:52.789925	\N	测试21	\N	\N	offline	\N	\N	\N	\N	\N
104	test03	$2a$10$kByMCMm.Y47JpqWpOV9NG.WE0fuSLy2b5focqkbqSdcnF0lW9zGe.	\N	\N		2025-11-24 17:36:14.534498	2025-11-26 10:58:30.786422	\N	测试03	\N	\N	offline	\N	\N	\N	\N	\N
103	test02	$2a$10$PrenWrXII9B6hC6nqFy9vuOytj6uwOMQr1wmSHG3buVhIKsJ7x8me			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129327_JPEG_20251126_115527_5144140681260080541.jpg	2025-11-24 15:17:23.407595	2025-11-26 11:56:04.065012	\N	测试2	male	\N	offline	\N	\N			
105	test04	$2a$10$Fm3Q5vPVgXwYZwVI4iqG7.QUSXtXQ2FxUlehsmypbh6NzvtP3dEiO	\N	\N		2025-11-24 22:21:53.621795	2025-11-26 07:50:33.060977	\N	测试04	\N	\N	offline	\N	\N	\N	\N	\N
109	test08	$2a$10$F2bLFd0ymS2Z49VUu4ORnuPhwYYD6F557ux1Armlug.RgE0D5g/l6	\N	\N		2025-11-25 12:47:11.273864	2025-11-26 08:36:07.345361	\N	测试08	\N	\N	offline	\N	\N	\N	\N	\N
114	test23	$2a$10$GpkCQkQ4ra.Pv73rwAiYTuB/sz6Q5b2Vl34GBseFrAj1/jnQg2r4u			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129472_JPEG_20251126_115752_2461943808010734271.jpg	2025-11-25 17:56:40.890524	2025-11-26 16:04:23.737315	\N	测试23	male	\N	online	\N	\N			
106	test05	$2a$10$kn7TCvq3qQTaf8RaURSgauc6k9QRCE6.JWPwmPMw.1JiPa1ZrAcLm	\N	\N		2025-11-25 09:22:55.250863	2025-11-26 09:35:43.822158	\N	测试05	\N	\N	offline	\N	\N	\N	\N	\N
102	test01	$2a$10$y.M5Avb0FHVgydjPs.8jL.rWFpTQpnm71kLBzHn37o8sB..HFtLf.	\N	\N		2025-11-24 15:13:50.435812	2025-11-26 09:45:51.184503	\N	测试01	\N	\N	offline	\N	\N	\N	\N	\N
110	test09	$2a$10$1rrVDyQSoXiISY1ElZOQRO5dRCPPzFDiwtwp6ra0xI2UYzrd0zHMK	\N	\N		2025-11-25 13:02:50.353647	2025-11-25 13:19:28.412389	\N	测试09	\N	\N	offline	\N	\N	\N	\N	\N
113	test22	$2a$10$ATfNIdUDVtWLhSeF6dMvL.m3EQEUFaFDgVb/GK7yNlQFY8.b4XORa			https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/avatars/1764129559_ic_launcher.png	2025-11-25 17:55:13.217482	2025-11-26 16:08:46.662483	\N	测试22	male	errt	offline					
107	test06	$2a$10$.KpWdHmmFNCIj/pMEH5BwuxShNCcz6TjXiEUiO8Eja1g/X23elPCu	\N	\N		2025-11-25 11:58:13.736898	2025-11-26 08:05:32.561569	\N	测试06	\N	\N	offline	\N	\N	\N	\N	\N
111	test20	$2a$10$.G9/nBcXlJcoNIM6m61Ohu5BRWvvX0zZsH5vr4og9zVJDLM46OwNG	\N	\N		2025-11-25 13:19:01.898295	2025-11-25 13:37:12.280903	\N	测试20	\N	\N	offline	\N	\N	\N	\N	\N
108	test07	$2a$10$yJCg/1THxS0reCHZuSmw0u4I15gQbBSrf50uTxeukvUWkUE2N4KIK	\N	\N		2025-11-25 12:33:05.712664	2025-11-26 08:10:41.957336	\N	测试07	\N	\N	offline	\N	\N	\N	\N	\N
\.


--
-- Data for Name: verification_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.verification_codes (id, account, code, type, expires_at, created_at) FROM stdin;
\.


--
-- Name: device_registrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.device_registrations_id_seq', 166, true);


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

SELECT pg_catalog.setval('public.favorites_id_seq', 75, true);


--
-- Name: file_assistant_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.file_assistant_messages_id_seq', 11, true);


--
-- Name: group_members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_members_id_seq', 130, true);


--
-- Name: group_message_reads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_message_reads_id_seq', 2851, true);


--
-- Name: group_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_messages_id_seq', 857, true);


--
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.groups_id_seq', 26, true);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 2217, true);


--
-- Name: server_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.server_settings_id_seq', 5, true);


--
-- Name: user_relations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_relations_id_seq', 131, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 114, true);


--
-- Name: verification_codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.verification_codes_id_seq', 3, true);


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
-- Name: file_assistant_messages file_assistant_messages_quoted_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assistant_messages
    ADD CONSTRAINT file_assistant_messages_quoted_message_id_fkey FOREIGN KEY (quoted_message_id) REFERENCES public.file_assistant_messages(id);


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
-- Name: group_messages group_messages_quoted_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_quoted_message_id_fkey FOREIGN KEY (quoted_message_id) REFERENCES public.group_messages(id);


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

\unrestrict Rzzm7wYZLAhzxwfT6ENlmdRQ6PGVeaNxPRa4ld1EidNA83AbaXXAUUrHSxma3Ed

