-- Create/link users for CSV names present in core_people (9010) but absent in core_users (9020)
-- Idempotent: reuses existing auth.users by email (case-insensitive) and ensures core_users link.

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('alcione.goncalves@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '37be4054-a4bd-413e-9cc9-d63ea67737c5';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'alcione.goncalves@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '70faa139-4d5e-458b-a1ce-e67166464757');
  ELSIF v_existing_person <> '70faa139-4d5e-458b-a1ce-e67166464757' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '70faa139-4d5e-458b-a1ce-e67166464757';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('alexandre.murer@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '60742aad-d47b-44f0-9169-fd76308de859';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'alexandre.murer@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '0c45d85f-ae9b-47b3-afc6-5b067f720990');
  ELSIF v_existing_person <> '0c45d85f-ae9b-47b3-afc6-5b067f720990' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '0c45d85f-ae9b-47b3-afc6-5b067f720990';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('alice.cabral@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '1e488c96-7f18-4eb1-a051-b581d9376cb5';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'alice.cabral@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'd13b9762-3bb1-49b7-ad4c-ffdf2fa8bc6c');
  ELSIF v_existing_person <> 'd13b9762-3bb1-49b7-ad4c-ffdf2fa8bc6c' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'd13b9762-3bb1-49b7-ad4c-ffdf2fa8bc6c';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('amanda.pinto@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '37ed098a-000e-4e4d-98c1-33cd8e185d1f';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'amanda.pinto@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '14cfc55e-23d2-4601-b76c-9898750b08a0');
  ELSIF v_existing_person <> '14cfc55e-23d2-4601-b76c-9898750b08a0' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '14cfc55e-23d2-4601-b76c-9898750b08a0';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('ana.santos@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '88a3e5f5-7798-4117-81f8-b6f4ac6c86db';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'ana.santos@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'cbb071b3-c66f-425d-af55-04e26ed3ffac');
  ELSIF v_existing_person <> 'cbb071b3-c66f-425d-af55-04e26ed3ffac' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'cbb071b3-c66f-425d-af55-04e26ed3ffac';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('ana.ribeiro@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'a73aeacf-9daf-4d79-8f15-0225a7885e8b';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'ana.ribeiro@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '37a817a8-207f-48f5-8980-62ca04f6ae27');
  ELSIF v_existing_person <> '37a817a8-207f-48f5-8980-62ca04f6ae27' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '37a817a8-207f-48f5-8980-62ca04f6ae27';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('ana.ribeiro@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '67043f37-d150-4347-9d3e-9700c95893fb';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'ana.ribeiro@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'bb47defd-9b42-4bb1-b3bc-1e211dea7ec6');
  ELSIF v_existing_person <> 'bb47defd-9b42-4bb1-b3bc-1e211dea7ec6' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'bb47defd-9b42-4bb1-b3bc-1e211dea7ec6';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('andrea.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '9e31218a-8ae8-435c-ae61-3ff7edbe35d9';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'andrea.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'a631e151-94f7-4618-a311-3da356fe55fe');
  ELSIF v_existing_person <> 'a631e151-94f7-4618-a311-3da356fe55fe' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'a631e151-94f7-4618-a311-3da356fe55fe';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('angelica.oliveira@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'fcb23678-1103-48bf-a5b2-d195767b3eae';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'angelica.oliveira@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'e9aaee03-e2f7-46b6-89e3-5c6d04a1bd67');
  ELSIF v_existing_person <> 'e9aaee03-e2f7-46b6-89e3-5c6d04a1bd67' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'e9aaee03-e2f7-46b6-89e3-5c6d04a1bd67';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('arcucio.paula@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'c4901770-d25b-4643-8610-7110d591ddab';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'arcucio.paula@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'd7dc2726-ed9d-4643-b23d-17ee8475045d');
  ELSIF v_existing_person <> 'd7dc2726-ed9d-4643-b23d-17ee8475045d' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'd7dc2726-ed9d-4643-b23d-17ee8475045d';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('ayeska.lima@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '78bb0527-7a80-4747-813d-02c3916698ad';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'ayeska.lima@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '69ace977-b19d-40e2-889d-fb63a0729e46');
  ELSIF v_existing_person <> '69ace977-b19d-40e2-889d-fb63a0729e46' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '69ace977-b19d-40e2-889d-fb63a0729e46';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('bruno.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'e290dbd9-1303-4a65-bea5-08dc7b7ca8ed';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'bruno.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '16a08e45-38e6-4afa-9469-df32d00c6269');
  ELSIF v_existing_person <> '16a08e45-38e6-4afa-9469-df32d00c6269' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '16a08e45-38e6-4afa-9469-df32d00c6269';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('bruno.damasio@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '7aa05a56-79f7-4975-9711-524f8a181a22';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'bruno.damasio@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '60a88ca1-d923-47de-aedb-afacfe6fda24');
  ELSIF v_existing_person <> '60a88ca1-d923-47de-aedb-afacfe6fda24' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '60a88ca1-d923-47de-aedb-afacfe6fda24';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('caroline.romao@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '3c114109-ff42-46aa-9332-c1ea461b129e';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'caroline.romao@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '7740c2d7-361e-484a-8f7f-b772b0a173e1');
  ELSIF v_existing_person <> '7740c2d7-361e-484a-8f7f-b772b0a173e1' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '7740c2d7-361e-484a-8f7f-b772b0a173e1';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('chaya.souza@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '928ff8d6-9178-4d99-8df5-1082db443322';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'chaya.souza@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '70e374dd-c21e-4da4-abc5-dd9f6af08e72');
  ELSIF v_existing_person <> '70e374dd-c21e-4da4-abc5-dd9f6af08e72' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '70e374dd-c21e-4da4-abc5-dd9f6af08e72';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('claudia.moreira@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '55488a8a-06ff-44ab-9a7a-5ae0a38f5dd9';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'claudia.moreira@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '871b0103-21ca-48d9-847b-76614e991c47');
  ELSIF v_existing_person <> '871b0103-21ca-48d9-847b-76614e991c47' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '871b0103-21ca-48d9-847b-76614e991c47';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('claudinei.oliveira@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '6d344404-e187-43a7-8c2d-78fb220d7981';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'claudinei.oliveira@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'eba21622-038e-4f91-bdf5-43641fef29c8');
  ELSIF v_existing_person <> 'eba21622-038e-4f91-bdf5-43641fef29c8' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'eba21622-038e-4f91-bdf5-43641fef29c8';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('claudio.oliveira@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '90392b29-b3b9-4f6e-a511-d85d0be31f75';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'claudio.oliveira@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '653d384d-2364-481f-8f93-8888b271a810');
  ELSIF v_existing_person <> '653d384d-2364-481f-8f93-8888b271a810' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '653d384d-2364-481f-8f93-8888b271a810';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('cristiane.cruz@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '4eb87bb3-3e62-4040-a814-d2d1e4cad790';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'cristiane.cruz@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'b7d6f452-861b-49f6-a818-3d46c8444148');
  ELSIF v_existing_person <> 'b7d6f452-861b-49f6-a818-3d46c8444148' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'b7d6f452-861b-49f6-a818-3d46c8444148';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('cristiane.paula@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'ff5a67a1-967e-41bf-ba46-d337e17a60ae';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'cristiane.paula@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '9e9f8c1f-d008-44e0-84ec-c17ebe055476');
  ELSIF v_existing_person <> '9e9f8c1f-d008-44e0-84ec-c17ebe055476' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '9e9f8c1f-d008-44e0-84ec-c17ebe055476';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('cristiane.mesquita@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '5792e976-3395-41b9-ad8a-cdc004a3a488';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'cristiane.mesquita@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'ed37430e-8819-4ce0-ba71-93e2fd8c4c99');
  ELSIF v_existing_person <> 'ed37430e-8819-4ce0-ba71-93e2fd8c4c99' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'ed37430e-8819-4ce0-ba71-93e2fd8c4c99';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('danielle.lima@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '0563a9f5-8166-4d55-86a2-e1edfea04947';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'danielle.lima@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '32640567-9811-482c-82a9-761d83099b9e');
  ELSIF v_existing_person <> '32640567-9811-482c-82a9-761d83099b9e' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '32640567-9811-482c-82a9-761d83099b9e';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('deborah.leal@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '6db4039a-63f5-40a0-a1c6-61593805d7c8';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'deborah.leal@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'f3b65cfa-6dd6-4c8e-a425-67e019b53b25');
  ELSIF v_existing_person <> 'f3b65cfa-6dd6-4c8e-a425-67e019b53b25' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'f3b65cfa-6dd6-4c8e-a425-67e019b53b25';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('diego.martins@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '659944cb-5334-46cc-ae0e-d27a00865fa3';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'diego.martins@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'fb67fb59-fe39-44f2-b040-0f2111a764b0');
  ELSIF v_existing_person <> 'fb67fb59-fe39-44f2-b040-0f2111a764b0' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'fb67fb59-fe39-44f2-b040-0f2111a764b0';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('dircineia.mendes@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'e10ee00b-8750-40d6-8ffc-00a4549c1445';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'dircineia.mendes@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '13d54b7b-e299-4229-805e-00ccf45bceef');
  ELSIF v_existing_person <> '13d54b7b-e299-4229-805e-00ccf45bceef' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '13d54b7b-e299-4229-805e-00ccf45bceef';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('eduardo.damasceno@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '9c8883d9-e88f-4440-978a-5d90958d080f';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'eduardo.damasceno@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'd5ce3b9c-5331-491f-bd27-d059c3a34670');
  ELSIF v_existing_person <> 'd5ce3b9c-5331-491f-bd27-d059c3a34670' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'd5ce3b9c-5331-491f-bd27-d059c3a34670';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('elaine.santos@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '49f151df-d33b-47bf-94f7-8214f44d951e';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'elaine.santos@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '7dc133db-8fd9-4a89-9987-860da5ee452d');
  ELSIF v_existing_person <> '7dc133db-8fd9-4a89-9987-860da5ee452d' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '7dc133db-8fd9-4a89-9987-860da5ee452d';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('elane.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'c635ee18-c87f-46d1-873a-4630d089f5da';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'elane.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '8e252863-8fe7-46a7-8c81-635e0d03c4dc');
  ELSIF v_existing_person <> '8e252863-8fe7-46a7-8c81-635e0d03c4dc' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '8e252863-8fe7-46a7-8c81-635e0d03c4dc';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('clinicaodontologica@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '0f909b3b-9a8e-4601-bf2e-cb18294277a2';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'clinicaodontologica@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '825078d6-5444-4ae5-9df7-9bfd33aa593a');
  ELSIF v_existing_person <> '825078d6-5444-4ae5-9df7-9bfd33aa593a' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '825078d6-5444-4ae5-9df7-9bfd33aa593a';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('elisabete.loureiro@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'efa83dfa-4728-4aaa-b1b9-aad338dab63a';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'elisabete.loureiro@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'bad7c858-bc77-4471-b2ee-0cb3532297e2');
  ELSIF v_existing_person <> 'bad7c858-bc77-4471-b2ee-0cb3532297e2' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'bad7c858-bc77-4471-b2ee-0cb3532297e2';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('erica.santos@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'a68a248b-4ee0-4412-9701-d4dea0b054fa';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'erica.santos@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'ef736211-71ea-4c5a-9612-c9aa88d2db26');
  ELSIF v_existing_person <> 'ef736211-71ea-4c5a-9612-c9aa88d2db26' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'ef736211-71ea-4c5a-9612-c9aa88d2db26';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('erick.souza@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '71a7c4b4-e102-4660-b8fe-c8432dff6174';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'erick.souza@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '90aa30bd-0c9f-4d7f-b0dc-7feac7f36f01');
  ELSIF v_existing_person <> '90aa30bd-0c9f-4d7f-b0dc-7feac7f36f01' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '90aa30bd-0c9f-4d7f-b0dc-7feac7f36f01';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('fabiana.nunes@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'd224ec28-7856-4e4c-9966-e646127178c8';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'fabiana.nunes@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'fb8fff8a-e794-4148-b6c4-966a9c05a18e');
  ELSIF v_existing_person <> 'fb8fff8a-e794-4148-b6c4-966a9c05a18e' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'fb8fff8a-e794-4148-b6c4-966a9c05a18e';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('fabricio.rodrigues@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '4340f237-39ea-476e-9e06-62c6c6b1d705';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'fabricio.rodrigues@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'caffafab-8bd5-4d8e-ae39-5d60736e4a03');
  ELSIF v_existing_person <> 'caffafab-8bd5-4d8e-ae39-5d60736e4a03' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'caffafab-8bd5-4d8e-ae39-5d60736e4a03';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('gabriella.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'de41e74a-21e8-4aef-8031-a50b123e9bea';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'gabriella.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '2d6891f6-e58e-4f73-8cba-2003b65afb60');
  ELSIF v_existing_person <> '2d6891f6-e58e-4f73-8cba-2003b65afb60' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '2d6891f6-e58e-4f73-8cba-2003b65afb60';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('geraldo.avelar@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'd82f2680-ec6a-4f1b-a6de-202b900e07ff';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'geraldo.avelar@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'a670dd9d-864b-4f12-b899-a3da8b7efebc');
  ELSIF v_existing_person <> 'a670dd9d-864b-4f12-b899-a3da8b7efebc' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'a670dd9d-864b-4f12-b899-a3da8b7efebc';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('giovanni.souza@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'eb86188c-9802-49be-bb6b-f76845952f7b';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'giovanni.souza@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '78135595-c10f-4238-811b-6a6333c60044');
  ELSIF v_existing_person <> '78135595-c10f-4238-811b-6a6333c60044' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '78135595-c10f-4238-811b-6a6333c60044';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('giseli.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'fda8353b-770d-447a-b58e-ef76e3f8e5a8';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'giseli.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '59394164-3d10-4abc-8a90-6071607b5160');
  ELSIF v_existing_person <> '59394164-3d10-4abc-8a90-6071607b5160' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '59394164-3d10-4abc-8a90-6071607b5160';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('giselle.cruz@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'e7817f3f-6f46-4002-9f4e-2d518e22ff95';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'giselle.cruz@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '5b6bee59-1c70-4067-a736-10e6dbcb7910');
  ELSIF v_existing_person <> '5b6bee59-1c70-4067-a736-10e6dbcb7910' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '5b6bee59-1c70-4067-a736-10e6dbcb7910';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('guilherme.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '61a4a50b-3449-4bb6-b99e-7d98828e6f87';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'guilherme.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'b732aed4-32b7-45f0-8021-f14b39d8a893');
  ELSIF v_existing_person <> 'b732aed4-32b7-45f0-8021-f14b39d8a893' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'b732aed4-32b7-45f0-8021-f14b39d8a893';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('higienizacao.meioambiente@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '0d8c62ec-8897-4385-be4e-f7bb5387b0f9';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'higienizacao.meioambiente@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'c66b8063-e8d9-4e41-a1f8-55c59b54124d');
  ELSIF v_existing_person <> 'c66b8063-e8d9-4e41-a1f8-55c59b54124d' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'c66b8063-e8d9-4e41-a1f8-55c59b54124d';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('jackson.costa@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '57d24ff2-a8f1-4426-be9c-b2f8f3b63238';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'jackson.costa@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '868e9ac6-53a1-42a0-b622-59b189658812');
  ELSIF v_existing_person <> '868e9ac6-53a1-42a0-b622-59b189658812' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '868e9ac6-53a1-42a0-b622-59b189658812';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('janete.dias@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '69ef59d7-4daf-4eaa-812d-bfc25e954f28';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'janete.dias@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '8637b0a0-8b53-4aa9-be10-b74954958b34');
  ELSIF v_existing_person <> '8637b0a0-8b53-4aa9-be10-b74954958b34' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '8637b0a0-8b53-4aa9-be10-b74954958b34';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('jessica.rocha@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'ad9ff25f-95af-4cd9-a428-a3b6ccb6785f';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'jessica.rocha@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'b9c3d1d8-8c70-40c5-b6cc-417d2c2e2e17');
  ELSIF v_existing_person <> 'b9c3d1d8-8c70-40c5-b6cc-417d2c2e2e17' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'b9c3d1d8-8c70-40c5-b6cc-417d2c2e2e17';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('jose.souto@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'd09aea31-c2f9-4b2c-976f-2655fdf9fff8';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'jose.souto@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '0a1e3ece-5f0d-44dd-be36-27d337fa3ad9');
  ELSIF v_existing_person <> '0a1e3ece-5f0d-44dd-be36-27d337fa3ad9' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '0a1e3ece-5f0d-44dd-be36-27d337fa3ad9';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('josiane.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '9d360490-24cd-4d4e-a982-b9fbb90e97fe';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'josiane.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '059fca60-b240-42a3-a5e5-b0737fed6fde');
  ELSIF v_existing_person <> '059fca60-b240-42a3-a5e5-b0737fed6fde' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '059fca60-b240-42a3-a5e5-b0737fed6fde';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('josue.joviano@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'b6763719-b508-4225-972f-392ddd9683d4';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'josue.joviano@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '29eebd51-3552-491d-84dd-98ec1485b651');
  ELSIF v_existing_person <> '29eebd51-3552-491d-84dd-98ec1485b651' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '29eebd51-3552-491d-84dd-98ec1485b651';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('juliane.soares@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '3c98bdaa-fe06-4960-b332-f4d387bcee4c';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'juliane.soares@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '51b14614-ad51-447d-a8c0-16a2b1255c57');
  ELSIF v_existing_person <> '51b14614-ad51-447d-a8c0-16a2b1255c57' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '51b14614-ad51-447d-a8c0-16a2b1255c57';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('karina.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '607c2744-42dd-4c6c-a5d1-c19cfe81586a';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'karina.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '9d508c69-3538-4465-98cd-e954a8ba113a');
  ELSIF v_existing_person <> '9d508c69-3538-4465-98cd-e954a8ba113a' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '9d508c69-3538-4465-98cd-e954a8ba113a';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('kathrina.santos@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'ac5a321b-489c-4cd9-925a-be42858bb4f1';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'kathrina.santos@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '5baec57d-c2f2-4b5e-a8fa-8682dbcc9b69');
  ELSIF v_existing_person <> '5baec57d-c2f2-4b5e-a8fa-8682dbcc9b69' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '5baec57d-c2f2-4b5e-a8fa-8682dbcc9b69';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('keetlen.fiuza@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'c06267ea-eaf8-4116-92e9-e5193c633933';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'keetlen.fiuza@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '988b0082-f547-4228-95bc-c0720b77adaa');
  ELSIF v_existing_person <> '988b0082-f547-4228-95bc-c0720b77adaa' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '988b0082-f547-4228-95bc-c0720b77adaa';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('keilla.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '74341452-e857-4302-af9c-5ce9538931af';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'keilla.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '9ae56b4a-8717-4a84-94ae-bdd21f81c9a2');
  ELSIF v_existing_person <> '9ae56b4a-8717-4a84-94ae-bdd21f81c9a2' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '9ae56b4a-8717-4a84-94ae-bdd21f81c9a2';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('leandro.delmondes@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'c801fa3f-2642-479b-b076-044f26d0aa9a';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'leandro.delmondes@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '88a4aad8-2ddc-45d4-91e1-10235fe27e20');
  ELSIF v_existing_person <> '88a4aad8-2ddc-45d4-91e1-10235fe27e20' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '88a4aad8-2ddc-45d4-91e1-10235fe27e20';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('leidimar.castro@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '44be331b-02f4-4b8a-8d7a-8423cfa941a4';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'leidimar.castro@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'a5d55ff6-136a-43cf-b8a3-e3b7a3732759');
  ELSIF v_existing_person <> 'a5d55ff6-136a-43cf-b8a3-e3b7a3732759' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'a5d55ff6-136a-43cf-b8a3-e3b7a3732759';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('lidia.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '6006d120-aae9-4d7b-b7b3-d7561eaf5109';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'lidia.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '563b177b-4250-4413-bdb4-4544362f9a26');
  ELSIF v_existing_person <> '563b177b-4250-4413-bdb4-4544362f9a26' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '563b177b-4250-4413-bdb4-4544362f9a26';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('luciane.cornelio@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '75836ded-d572-4f35-80f0-03116a6cb181';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'luciane.cornelio@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'bf65d272-ccd5-41b0-a0a1-cc639dffc4cd');
  ELSIF v_existing_person <> 'bf65d272-ccd5-41b0-a0a1-cc639dffc4cd' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'bf65d272-ccd5-41b0-a0a1-cc639dffc4cd';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('luciano.pinto@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'd06aa87b-98df-4d1c-a8b8-3e8de5de4376';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'luciano.pinto@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '4685fe23-85ba-4f74-add9-aa3fc00f1271');
  ELSIF v_existing_person <> '4685fe23-85ba-4f74-add9-aa3fc00f1271' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '4685fe23-85ba-4f74-add9-aa3fc00f1271';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('luciene.santos@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '4b8716b9-90fe-417e-9535-ec791adc8513';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'luciene.santos@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '8dde01d7-c1ce-416e-998e-4b32f9ee1841');
  ELSIF v_existing_person <> '8dde01d7-c1ce-416e-998e-4b32f9ee1841' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '8dde01d7-c1ce-416e-998e-4b32f9ee1841';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('marcelo.reis@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'd96ad60b-2a74-4576-a517-3536f1000a81';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'marcelo.reis@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '01934797-7180-40c6-9043-8305aa390192');
  ELSIF v_existing_person <> '01934797-7180-40c6-9043-8305aa390192' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '01934797-7180-40c6-9043-8305aa390192';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('marcia.sapori@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'c6cd4b6e-95e4-4d1c-aa21-8a5b31844ff5';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'marcia.sapori@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '41bb4a06-b6fc-4a39-aebf-22a4bb6b4f18');
  ELSIF v_existing_person <> '41bb4a06-b6fc-4a39-aebf-22a4bb6b4f18' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '41bb4a06-b6fc-4a39-aebf-22a4bb6b4f18';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('marcos.andrade@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'b11a02c5-f5ae-4b17-8af4-8907ff136c97';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'marcos.andrade@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'd954641e-e1c0-478d-9149-cccba2c29e5d');
  ELSIF v_existing_person <> 'd954641e-e1c0-478d-9149-cccba2c29e5d' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'd954641e-e1c0-478d-9149-cccba2c29e5d';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('maria.rocha@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'adee29ba-b689-4726-a020-e62deaf27ef2';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'maria.rocha@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '803da5b3-a340-40c6-a851-4f2bfb11b44f');
  ELSIF v_existing_person <> '803da5b3-a340-40c6-a851-4f2bfb11b44f' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '803da5b3-a340-40c6-a851-4f2bfb11b44f';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('maria.gomes@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'afbb288c-a0ae-4b7b-9040-96b8dfc0e227';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'maria.gomes@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '93dfcca3-c854-4f5a-87b4-ae6acfb4db36');
  ELSIF v_existing_person <> '93dfcca3-c854-4f5a-87b4-ae6acfb4db36' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '93dfcca3-c854-4f5a-87b4-ae6acfb4db36';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('maria.ferreira@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '4659ecee-c20e-434a-97f1-6cbbe7189ec9';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'maria.ferreira@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '575b9f90-7691-4560-84d4-3d5d3405c890');
  ELSIF v_existing_person <> '575b9f90-7691-4560-84d4-3d5d3405c890' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '575b9f90-7691-4560-84d4-3d5d3405c890';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('maria.lima@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '67adf7f3-59f7-4a1a-9c7c-8680b3d727a3';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'maria.lima@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '4834c25d-7a6d-4bff-b16e-778ff8e4b4f8');
  ELSIF v_existing_person <> '4834c25d-7a6d-4bff-b16e-778ff8e4b4f8' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '4834c25d-7a6d-4bff-b16e-778ff8e4b4f8';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('nutricaosnd@caminhosparajesus.org.br') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'be4a0628-28f1-475f-ab81-a5124d5387ae';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'nutricaosnd@caminhosparajesus.org.br', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '095ca9f4-0c45-4c2e-bd8f-fb3d81ff2dbe');
  ELSIF v_existing_person <> '095ca9f4-0c45-4c2e-bd8f-fb3d81ff2dbe' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '095ca9f4-0c45-4c2e-bd8f-fb3d81ff2dbe';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('maruza.gomes@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'a4949ef5-3c3f-469b-bbb5-265b1ae4489f';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'maruza.gomes@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '76776ef7-3cd8-47cd-93be-d4dd945c8efd');
  ELSIF v_existing_person <> '76776ef7-3cd8-47cd-93be-d4dd945c8efd' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '76776ef7-3cd8-47cd-93be-d4dd945c8efd';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('paloma.pessoa@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '26d117bd-af8e-48ae-91ee-ee2fe6df29e0';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'paloma.pessoa@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '6f1cd275-354d-4c12-9f46-cd7cea450650');
  ELSIF v_existing_person <> '6f1cd275-354d-4c12-9f46-cd7cea450650' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '6f1cd275-354d-4c12-9f46-cd7cea450650';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('pamela.moraes@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '57b6d375-5902-4c10-8259-6d25ad256698';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'pamela.moraes@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '3dd2b53d-2919-4cbf-9235-e9fe2392bbef');
  ELSIF v_existing_person <> '3dd2b53d-2919-4cbf-9235-e9fe2392bbef' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '3dd2b53d-2919-4cbf-9235-e9fe2392bbef';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('poliane.oliveira@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '8e2de40c-10b1-4f4b-b063-1a45b1a4ab13';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'poliane.oliveira@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '431251f9-53e6-4ced-b2fb-8cd15b61e9b2');
  ELSIF v_existing_person <> '431251f9-53e6-4ced-b2fb-8cd15b61e9b2' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '431251f9-53e6-4ced-b2fb-8cd15b61e9b2';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('priscila.rodrigues@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'cfd0081f-e403-437f-88db-042ad9284766';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'priscila.rodrigues@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '2d86c66c-b35a-4545-996d-cf7dd23b2b2c');
  ELSIF v_existing_person <> '2d86c66c-b35a-4545-996d-cf7dd23b2b2c' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '2d86c66c-b35a-4545-996d-cf7dd23b2b2c';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('rafael.braga@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '116851ae-cb73-4794-ba9d-adb6b3b5f24a';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'rafael.braga@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'c48b783c-307d-4aef-a38a-f96d3b6d00a9');
  ELSIF v_existing_person <> 'c48b783c-307d-4aef-a38a-f96d3b6d00a9' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'c48b783c-307d-4aef-a38a-f96d3b6d00a9';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('regina.mendes@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '979c7dd0-72f7-41ea-9894-733a6803e598';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'regina.mendes@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '34d6a3ef-873c-403f-bed2-eb2bc8d9f9aa');
  ELSIF v_existing_person <> '34d6a3ef-873c-403f-bed2-eb2bc8d9f9aa' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '34d6a3ef-873c-403f-bed2-eb2bc8d9f9aa';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('reginaldo.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'b0891f2e-1a23-4fe0-b54c-bcdd2cf4f610';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'reginaldo.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'ee67f6d3-b8bb-4f3e-ba3d-d184d37c8339');
  ELSIF v_existing_person <> 'ee67f6d3-b8bb-4f3e-ba3d-d184d37c8339' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'ee67f6d3-b8bb-4f3e-ba3d-d184d37c8339';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('sara.santos@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '0034a321-0d40-4456-b913-5183732ad2e3';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'sara.santos@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '61f0a876-db25-46c6-a095-c083fd0f5b3e');
  ELSIF v_existing_person <> '61f0a876-db25-46c6-a095-c083fd0f5b3e' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '61f0a876-db25-46c6-a095-c083fd0f5b3e';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('simone.martins@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'e6945b94-dd19-4791-8695-7f2064705051';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'simone.martins@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '55dc4878-fc6c-46de-9dd5-7c26197eca86');
  ELSIF v_existing_person <> '55dc4878-fc6c-46de-9dd5-7c26197eca86' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '55dc4878-fc6c-46de-9dd5-7c26197eca86';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('sylvia.miranda@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'fd455e85-ae5d-4213-8a02-cbd0cb7e4872';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'sylvia.miranda@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '18c8fa81-0b10-40a1-9428-246ca98f4d2c');
  ELSIF v_existing_person <> '18c8fa81-0b10-40a1-9428-246ca98f4d2c' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '18c8fa81-0b10-40a1-9428-246ca98f4d2c';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('tarcio.barbosa@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '70e7c747-eb9a-40d2-95d0-565212402233';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'tarcio.barbosa@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '848f1723-faa1-4879-a07c-62a23e538fc7');
  ELSIF v_existing_person <> '848f1723-faa1-4879-a07c-62a23e538fc7' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '848f1723-faa1-4879-a07c-62a23e538fc7';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('tatiana.cruz@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '5652b4f6-9137-4c88-9dc4-89790ff521ca';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'tatiana.cruz@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '6463bb00-4551-467e-9e3c-12e83bcf7486');
  ELSIF v_existing_person <> '6463bb00-4551-467e-9e3c-12e83bcf7486' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '6463bb00-4551-467e-9e3c-12e83bcf7486';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('thamyres.santos@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '57c8f194-1c2d-4b80-ab9f-7b875b91942f';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'thamyres.santos@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '58a79b9e-ca6d-43e8-b2fa-0aca81a91121');
  ELSIF v_existing_person <> '58a79b9e-ca6d-43e8-b2fa-0aca81a91121' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '58a79b9e-ca6d-43e8-b2fa-0aca81a91121';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('vanessa.nogueira@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '202f1276-8361-4d6f-b835-651ab919fe89';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'vanessa.nogueira@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '1f876efe-5191-4639-bfa8-9f8eff06547c');
  ELSIF v_existing_person <> '1f876efe-5191-4639-bfa8-9f8eff06547c' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '1f876efe-5191-4639-bfa8-9f8eff06547c';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('vanizete.figueiredo@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'cc38f376-9e16-42ae-9a9f-73c7ec2de8d5';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'vanizete.figueiredo@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '34479819-dead-4c24-8b2f-6e5759a0dd02');
  ELSIF v_existing_person <> '34479819-dead-4c24-8b2f-6e5759a0dd02' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '34479819-dead-4c24-8b2f-6e5759a0dd02';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('vinicius.guimaraes@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'fedea660-56b5-47d5-a857-201beb1d7f22';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'vinicius.guimaraes@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '355cd541-9335-4e29-88db-b641d889611d');
  ELSIF v_existing_person <> '355cd541-9335-4e29-88db-b641d889611d' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '355cd541-9335-4e29-88db-b641d889611d';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('viviane.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '5308d51f-59a0-4917-9842-c3c3622df117';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'viviane.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '670d06a7-5312-40e0-a66d-70830e1774e7');
  ELSIF v_existing_person <> '670d06a7-5312-40e0-a66d-70830e1774e7' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '670d06a7-5312-40e0-a66d-70830e1774e7';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('vivianni.abreu@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '7ca51f8f-0714-44ec-a977-9f1ecc15269c';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'vivianni.abreu@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '51f3f00a-5646-41d2-84e7-48f1a41b974c');
  ELSIF v_existing_person <> '51f3f00a-5646-41d2-84e7-48f1a41b974c' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '51f3f00a-5646-41d2-84e7-48f1a41b974c';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('wiliam.silva@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := '54d38d70-f796-4871-a69e-5464e1728205';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'wiliam.silva@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'bdcd9155-5a5a-4ebb-8706-bffd896ad559');
  ELSIF v_existing_person <> 'bdcd9155-5a5a-4ebb-8706-bffd896ad559' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'bdcd9155-5a5a-4ebb-8706-bffd896ad559';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('wladimir.fernandes@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'b6e4892e-2a80-456a-ad8c-215aa9209fe5';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'wladimir.fernandes@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '684896aa-9348-4cac-b440-c12b7d644101');
  ELSIF v_existing_person <> '684896aa-9348-4cac-b440-c12b7d644101' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '684896aa-9348-4cac-b440-c12b7d644101';
  END IF;
END$$;

DO $$
DECLARE
  v_user_id uuid;
  v_existing_person uuid;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('ygor.santos@caminhosparajesus.onmicrosoft.com') LIMIT 1;
  IF v_user_id IS NULL THEN
    v_user_id := 'd3909ab0-5af9-4112-9d57-6cb167891245';
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) VALUES (v_user_id, 'authenticated', 'authenticated', 'ygor.santos@caminhosparajesus.onmicrosoft.com', crypt('Mudar@1234', gen_salt('bf')), NOW(), NULL, NULL, '{ "provider":"email", "providers":["email"] }', '{}', NOW(), NOW());
  END IF;
  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;
  IF v_existing_person IS NULL THEN
    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, 'c9deff61-57db-4301-8033-58bd61926fc7');
  ELSIF v_existing_person <> 'c9deff61-57db-4301-8033-58bd61926fc7' THEN
    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, 'c9deff61-57db-4301-8033-58bd61926fc7';
  END IF;
END$$;

-- End
