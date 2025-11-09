--
-- PostgreSQL database dump
--

\restrict ZfvwMn3WrE9bGMDFISFiUXhEGZLzkOnIOFWMUjUqWLlp5rFYMUWtmaymSkhMp5h

-- Dumped from database version 16.10 (Debian 16.10-1.pgdg13+1)
-- Dumped by pg_dump version 16.10 (Debian 16.10-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: casbin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.casbin (
    id integer NOT NULL,
    ptype text NOT NULL,
    rule jsonb NOT NULL
);


ALTER TABLE public.casbin OWNER TO postgres;

--
-- Name: casbin_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.casbin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.casbin_id_seq OWNER TO postgres;

--
-- Name: casbin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.casbin_id_seq OWNED BY public.casbin.id;


--
-- Name: casbin_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.casbin_migrations (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    run_on timestamp without time zone NOT NULL
);


ALTER TABLE public.casbin_migrations OWNER TO postgres;

--
-- Name: casbin_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.casbin_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.casbin_migrations_id_seq OWNER TO postgres;

--
-- Name: casbin_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.casbin_migrations_id_seq OWNED BY public.casbin_migrations.id;


--
-- Name: casbin_rule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.casbin_rule (
    ptype text,
    v0 text,
    v1 text,
    v2 text,
    v3 text,
    v4 text,
    v5 text
);


ALTER TABLE public.casbin_rule OWNER TO postgres;

--
-- Name: domains; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.domains (
    domain_id text NOT NULL,
    domain_name text NOT NULL,
    domain_type text NOT NULL
);


ALTER TABLE public.domains OWNER TO postgres;

--
-- Name: patients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patients (
    patient_id uuid DEFAULT gen_random_uuid() NOT NULL,
    clinic_domain_id text,
    owner_user_id text,
    name text NOT NULL,
    species text NOT NULL,
    breed text,
    dob date,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.patients OWNER TO postgres;

--
-- Name: pet_owner_clinic_links; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pet_owner_clinic_links (
    link_id uuid DEFAULT gen_random_uuid() NOT NULL,
    pet_owner_domain_id text,
    clinic_domain_id text,
    status text DEFAULT 'PENDING'::text NOT NULL
);


ALTER TABLE public.pet_owner_clinic_links OWNER TO postgres;

--
-- Name: product_ledger; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_ledger (
    ledger_id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_lot_id text NOT NULL,
    status text NOT NULL,
    actor_domain_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.product_ledger OWNER TO postgres;

--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    product_id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_name text NOT NULL,
    traceability_level text NOT NULL
);


ALTER TABLE public.products OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    full_name text
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: casbin id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casbin ALTER COLUMN id SET DEFAULT nextval('public.casbin_id_seq'::regclass);


--
-- Name: casbin_migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casbin_migrations ALTER COLUMN id SET DEFAULT nextval('public.casbin_migrations_id_seq'::regclass);


--
-- Data for Name: casbin; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.casbin (id, ptype, rule) FROM stdin;
1	p	["clinic_doctor", "clinic-abc", "patient_data", "read"]
2	g	["user-jane", "clinic_doctor", "clinic-abc"]
\.


--
-- Data for Name: casbin_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.casbin_migrations (id, name, run_on) FROM stdin;
1	1587132340023_initial	2025-11-09 06:40:21.483992
2	1591572942519_pkey-and-uniq	2025-11-09 06:40:21.488999
\.


--
-- Data for Name: casbin_rule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.casbin_rule (ptype, v0, v1, v2, v3, v4, v5) FROM stdin;
g	user-jane	clinic_doctor	clinic-abc	\N	\N	\N
g	user-joe	clinic_manager	clinic-abc	\N	\N	\N
g	user-sara	clinic_doctor	clinic-xyz	\N	\N	\N
g	user-root	vv_admin	vina_root	\N	\N	\N
p	clinic_doctor	clinic-abc	patient_data	read	\N	\N
p	clinic_manager	clinic-abc	patient_data	read	\N	\N
p	clinic_manager	clinic-abc	patient_data	write	\N	\N
p	clinic_doctor	clinic-xyz	patient_data	read	\N	\N
\.


--
-- Data for Name: domains; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.domains (domain_id, domain_name, domain_type) FROM stdin;
vina_root	vina_root	VINA_ROOT
clinic-abc	clinic-abc	CLINIC
clinic-xyz	clinic-xyz	CLINIC
\.


--
-- Data for Name: patients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patients (patient_id, clinic_domain_id, owner_user_id, name, species, breed, dob, created_at) FROM stdin;
371b5aa3-dbe7-4b64-b696-e1c08f1dc302	clinic-abc	user-jane	Buddy	Dog	Beagle	2020-04-20	2025-11-09 06:48:00.320393+00
\.


--
-- Data for Name: pet_owner_clinic_links; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pet_owner_clinic_links (link_id, pet_owner_domain_id, clinic_domain_id, status) FROM stdin;
\.


--
-- Data for Name: product_ledger; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_ledger (ledger_id, product_lot_id, status, actor_domain_id, created_at) FROM stdin;
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (product_id, product_name, traceability_level) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, email, password_hash, full_name) FROM stdin;
user-jane	jane@clinic.com	$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W	Dr. Jane
user-joe	joe@clinic.com	$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W	Manager Joe
user-sara	sara@other.com	$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W	Dr. Sara
user-root	root@vinaveritas.com	$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W	VinaVeritas Admin
\.


--
-- Name: casbin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.casbin_id_seq', 2, true);


--
-- Name: casbin_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.casbin_migrations_id_seq', 2, true);


--
-- Name: casbin_migrations casbin_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casbin_migrations
    ADD CONSTRAINT casbin_migrations_pkey PRIMARY KEY (id);


--
-- Name: casbin casbin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casbin
    ADD CONSTRAINT casbin_pkey PRIMARY KEY (id);


--
-- Name: casbin casbin_uniq_rule; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casbin
    ADD CONSTRAINT casbin_uniq_rule UNIQUE (rule);


--
-- Name: domains domains_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (domain_id);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (patient_id);


--
-- Name: pet_owner_clinic_links pet_owner_clinic_links_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pet_owner_clinic_links
    ADD CONSTRAINT pet_owner_clinic_links_pkey PRIMARY KEY (link_id);


--
-- Name: product_ledger product_ledger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_ledger
    ADD CONSTRAINT product_ledger_pkey PRIMARY KEY (ledger_id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: casbin_rule_ptype_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX casbin_rule_ptype_idx ON public.casbin_rule USING btree (ptype);


--
-- Name: casbin_rule_unique_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX casbin_rule_unique_idx ON public.casbin_rule USING btree (ptype, v0, v1, v2, v3, v4, v5);


--
-- Name: casbin_rule_v0_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX casbin_rule_v0_idx ON public.casbin_rule USING btree (v0);


--
-- Name: casbin_rule_v1_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX casbin_rule_v1_idx ON public.casbin_rule USING btree (v1);


--
-- Name: casbin_rule_v2_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX casbin_rule_v2_idx ON public.casbin_rule USING btree (v2);


--
-- Name: casbin_rule_v3_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX casbin_rule_v3_idx ON public.casbin_rule USING btree (v3);


--
-- Name: idx_casbin_ptype; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_casbin_ptype ON public.casbin USING btree (ptype);


--
-- Name: idx_casbin_rule_v0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_casbin_rule_v0 ON public.casbin USING btree (((rule ->> 0)));


--
-- Name: idx_casbin_rule_v1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_casbin_rule_v1 ON public.casbin USING btree (((rule ->> 1)));


--
-- Name: idx_casbin_rule_v2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_casbin_rule_v2 ON public.casbin USING btree (((rule ->> 2)));


--
-- Name: idx_casbin_rule_v3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_casbin_rule_v3 ON public.casbin USING btree (((rule ->> 3)));


--
-- Name: idx_casbin_rule_v4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_casbin_rule_v4 ON public.casbin USING btree (((rule ->> 4)));


--
-- Name: idx_casbin_rule_v5; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_casbin_rule_v5 ON public.casbin USING btree (((rule ->> 5)));


--
-- Name: patients_by_clinic_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX patients_by_clinic_idx ON public.patients USING btree (clinic_domain_id, created_at DESC);


--
-- Name: patients patients_clinic_domain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_clinic_domain_id_fkey FOREIGN KEY (clinic_domain_id) REFERENCES public.domains(domain_id) ON DELETE SET NULL;


--
-- Name: patients patients_owner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: pet_owner_clinic_links pet_owner_clinic_links_clinic_domain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pet_owner_clinic_links
    ADD CONSTRAINT pet_owner_clinic_links_clinic_domain_id_fkey FOREIGN KEY (clinic_domain_id) REFERENCES public.domains(domain_id);


--
-- Name: pet_owner_clinic_links pet_owner_clinic_links_pet_owner_domain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pet_owner_clinic_links
    ADD CONSTRAINT pet_owner_clinic_links_pet_owner_domain_id_fkey FOREIGN KEY (pet_owner_domain_id) REFERENCES public.domains(domain_id);


--
-- Name: product_ledger product_ledger_actor_domain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_ledger
    ADD CONSTRAINT product_ledger_actor_domain_id_fkey FOREIGN KEY (actor_domain_id) REFERENCES public.domains(domain_id);


--
-- PostgreSQL database dump complete
--

\unrestrict ZfvwMn3WrE9bGMDFISFiUXhEGZLzkOnIOFWMUjUqWLlp5rFYMUWtmaymSkhMp5h

