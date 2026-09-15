CREATE TYPE public.app_role AS ENUM ('master', 'user');

CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role
  )
$$;
REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM anon;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO service_role;

CREATE POLICY "users read own roles" ON public.user_roles
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'master'));

CREATE TABLE public.admin_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  admin_email text,
  target_user_id uuid,
  target_email text,
  acao text NOT NULL,
  detalhes jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.admin_audit_logs TO authenticated;
GRANT ALL ON public.admin_audit_logs TO service_role;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "masters read audit logs" ON public.admin_audit_logs
  FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'master'));
CREATE INDEX idx_admin_audit_logs_created_at ON public.admin_audit_logs (created_at DESC);

CREATE POLICY "Master pode ver todos os perfis leitura" ON public.profiles FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver metas" ON public.nutrition_goals FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver refeicoes" ON public.meals FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver itens de refeicao" ON public.meal_foods FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver alimentos" ON public.foods FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver exercicios" ON public.exercises FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver treinos" ON public.workouts FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver exercicios do treino" ON public.workout_exercises FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver modelos" ON public.workout_templates FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver exercicios do modelo" ON public.template_exercises FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver planos semanais" ON public.weekly_plans FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver dias do plano" ON public.weekly_plan_days FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver metas de agua" ON public.water_goals FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver registros de agua" ON public.water_logs FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver lembretes de agua" ON public.water_reminders FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master pode ver fotos de progresso" ON public.progress_photos FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'master'));
CREATE POLICY "Master le fotos de progresso" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'progress-photos' AND public.has_role(auth.uid(), 'master'));

INSERT INTO public.exercise_categories (nome, descricao) VALUES
  ('Peito', 'Exercícios para peitoral'),
  ('Costas', 'Exercícios para dorsais'),
  ('Pernas', 'Exercícios para membros inferiores'),
  ('Cardio', 'Exercícios cardiovasculares'),
  ('Ombros','Deltoides e trapézio'),
  ('Bíceps','Flexores do braço'),
  ('Tríceps','Extensores do braço'),
  ('Abdômen','Core e abdominais')
ON CONFLICT (nome) DO NOTHING;

WITH lib(nome, categoria, grupo, equipamento, descricao) AS (VALUES
('Supino reto','Peito','Peitoral','Barra',NULL),
('Supino inclinado','Peito','Peitoral superior','Barra',NULL),
('Crucifixo','Peito','Peitoral','Halteres',NULL),
('Puxada frontal','Costas','Latíssimo','Polia',NULL),
('Remada baixa','Costas','Dorsais','Polia',NULL),
('Remada curvada','Costas','Dorsais','Barra',NULL),
('Agachamento','Pernas','Quadríceps','Barra',NULL),
('Leg Press','Pernas','Quadríceps','Máquina',NULL),
('Mesa flexora','Pernas','Posterior','Máquina',NULL),
('Esteira','Cardio','Cardio','Esteira',NULL),
('Bicicleta','Cardio','Cardio','Bicicleta',NULL),
('Elíptico','Cardio','Cardio','Elíptico',NULL),
('Supino reto barra','Peito','Peitoral','Barra','Deitado no banco reto, desça a barra até o peito e empurre até estender os cotovelos.'),
('Supino reto halteres','Peito','Peitoral','Halteres','No banco reto, desça os halteres ao lado do peito e empurre para cima unindo levemente.'),
('Supino inclinado barra','Peito','Peitoral superior','Barra','Banco inclinado 30-45°, desça a barra na linha da clavícula e empurre.'),
('Supino inclinado halteres','Peito','Peitoral superior','Halteres','Banco inclinado, desça os halteres controladamente e empurre até quase estender.'),
('Supino declinado','Peito','Peitoral inferior','Barra','Banco declinado, desça a barra na parte baixa do peito e empurre.'),
('Crucifixo reto','Peito','Peitoral','Halteres','Banco reto, abra os braços semi-flexionados e volte contraindo o peito.'),
('Crucifixo inclinado','Peito','Peitoral superior','Halteres','Banco inclinado, abertura ampla dos braços com cotovelos levemente flexionados.'),
('Crucifixo máquina','Peito','Peitoral','Máquina','Sentado na máquina, junte os braços à frente contraindo o peitoral.'),
('Peck Deck','Peito','Peitoral','Máquina','Antebraços apoiados nas almofadas, aproxime os cotovelos à frente do peito.'),
('Crossover alto','Peito','Peitoral inferior','Cabo','Polias altas, cruze os cabos para baixo à frente do corpo.'),
('Crossover médio','Peito','Peitoral','Cabo','Polias na altura do ombro, junte as mãos à frente do peito.'),
('Crossover baixo','Peito','Peitoral superior','Cabo','Polias baixas, eleve os cabos até a altura do peito.'),
('Flexão de braço','Peito','Peitoral','Peso corporal','Corpo alinhado, desça o peito até próximo ao chão e empurre.'),
('Flexão inclinada','Peito','Peitoral inferior','Peso corporal','Mãos apoiadas em banco, execute a flexão com menor carga.'),
('Flexão declinada','Peito','Peitoral superior','Peso corporal','Pés elevados em banco, execute a flexão aumentando a exigência.'),
('Paralelas para peito','Peito','Peitoral inferior','Peso corporal','Tronco inclinado à frente nas barras paralelas, desça e suba.'),
('Puxada frente aberta','Costas','Latíssimo','Máquina','Pegada aberta pronada, puxe a barra até a parte alta do peito.'),
('Puxada frente fechada','Costas','Dorsais','Máquina','Pegada fechada neutra, puxe o triângulo até o peito.'),
('Puxada supinada','Costas','Dorsais','Máquina','Pegada supinada na largura dos ombros, puxe até o peito.'),
('Barra fixa','Costas','Latíssimo','Peso corporal','Pegada pronada, puxe o corpo até o queixo passar a barra.'),
('Barra fixa supinada','Costas','Dorsais','Peso corporal','Pegada supinada, puxe o corpo enfatizando dorsais e bíceps.'),
('Remada curvada barra','Costas','Dorsais','Barra','Tronco inclinado, puxe a barra até o abdômen com coluna neutra.'),
('Remada unilateral halter','Costas','Dorsais','Halteres','Apoiado no banco, puxe o halter até o quadril.'),
('Remada cavalinho','Costas','Dorsais','Barra','Barra em T, puxe até o tronco mantendo as costas retas.'),
('Pullover','Costas','Latíssimo','Halteres','Deitado, leve o halter atrás da cabeça e retorne contraindo as costas.'),
('Remada máquina','Costas','Dorsais','Máquina','Peito apoiado, puxe as alavancas até a linha do tronco.'),
('Pulldown','Costas','Latíssimo','Cabo','Braços estendidos, empurre a barra para baixo até as coxas.'),
('Desenvolvimento barra','Ombros','Deltoide anterior','Barra','Sentado ou em pé, empurre a barra acima da cabeça.'),
('Desenvolvimento halteres','Ombros','Deltoide anterior','Halteres','Empurre os halteres acima da cabeça sem travar os cotovelos.'),
('Desenvolvimento máquina','Ombros','Deltoide anterior','Máquina','Sentado, empurre as alavancas acima da cabeça.'),
('Elevação lateral','Ombros','Deltoide medial','Halteres','Eleve os braços lateralmente até a altura dos ombros.'),
('Elevação frontal','Ombros','Deltoide anterior','Halteres','Eleve os braços à frente até a altura dos ombros.'),
('Crucifixo inverso','Ombros','Deltoide posterior','Halteres','Tronco inclinado, abra os braços para trás contraindo o posterior.'),
('Face Pull','Ombros','Deltoide posterior','Cabo','Puxe a corda em direção ao rosto abrindo os cotovelos.'),
('Arnold Press','Ombros','Deltoide anterior','Halteres','Rotacione os halteres da posição supinada para pronada ao empurrar.'),
('Remada alta','Ombros','Trapézio','Barra','Puxe a barra próxima ao corpo até a altura do peito.'),
('Rosca direta barra','Bíceps','Bíceps','Barra','Cotovelos junto ao corpo, flexione a barra até a altura do peito.'),
('Rosca direta W','Bíceps','Bíceps','Barra W','Mesma execução da rosca direta com barra W para menor estresse no punho.'),
('Rosca alternada','Bíceps','Bíceps','Halteres','Flexione um braço por vez com leve supinação.'),
('Rosca martelo','Bíceps','Braquial','Halteres','Pegada neutra, flexione mantendo os polegares para cima.'),
('Rosca concentrada','Bíceps','Bíceps','Halteres','Sentado, cotovelo apoiado na coxa, flexione até contrair.'),
('Rosca Scott','Bíceps','Bíceps','Barra W','Braços apoiados no banco Scott, flexione controladamente.'),
('Rosca banco inclinado','Bíceps','Bíceps','Halteres','Deitado em banco inclinado, flexione com os braços pendendo.'),
('Rosca cabo','Bíceps','Bíceps','Cabo','Na polia baixa, flexione mantendo tensão constante.'),
('Tríceps pulley','Tríceps','Tríceps','Cabo','Cotovelos fixos, estenda a barra para baixo.'),
('Tríceps corda','Tríceps','Tríceps','Cabo','Estenda a corda para baixo abrindo as pontas no final.'),
('Tríceps francês','Tríceps','Tríceps','Halteres','Halter acima da cabeça, flexione e estenda os cotovelos.'),
('Tríceps testa','Tríceps','Tríceps','Barra W','Deitado, desça a barra até a testa e estenda os cotovelos.'),
('Tríceps banco','Tríceps','Tríceps','Peso corporal','Mãos no banco atrás do corpo, desça e suba o quadril.'),
('Tríceps coice','Tríceps','Tríceps','Halteres','Tronco inclinado, estenda o cotovelo para trás.'),
('Mergulho nas paralelas','Tríceps','Tríceps','Peso corporal','Tronco ereto nas paralelas, desça e empurre estendendo os cotovelos.'),
('Agachamento livre','Pernas','Quadríceps','Barra','Barra nas costas, desça até a coxa paralela e suba.'),
('Agachamento frontal','Pernas','Quadríceps','Barra','Barra à frente dos ombros, agache mantendo o tronco ereto.'),
('Leg Press 45°','Pernas','Quadríceps','Máquina','Empurre a plataforma sem travar os joelhos.'),
('Leg Press horizontal','Pernas','Quadríceps','Máquina','Sentado, empurre a plataforma controlando a descida.'),
('Hack Machine','Pernas','Quadríceps','Máquina','Costas apoiadas, agache na máquina hack e retorne.'),
('Cadeira extensora','Pernas','Quadríceps','Máquina','Estenda os joelhos contraindo o quadríceps no topo.'),
('Afundo','Pernas','Quadríceps','Halteres','Passo à frente, desça o joelho de trás e retorne.'),
('Passada','Pernas','Quadríceps','Halteres','Caminhe alternando passadas longas com descida controlada.'),
('Bulgarian Split Squat','Pernas','Quadríceps','Halteres','Pé traseiro no banco, agache com a perna da frente.'),
('Mesa flexora deitada','Pernas','Posterior','Máquina','Deitado, flexione os joelhos trazendo o rolo aos glúteos.'),
('Cadeira flexora','Pernas','Posterior','Máquina','Sentado, flexione os joelhos contra a resistência.'),
('Stiff','Pernas','Posterior','Barra','Joelhos semi-flexionados, desça a barra rente às pernas.'),
('Levantamento terra romeno','Pernas','Posterior','Barra','Quadril para trás, desça a barra até o meio da canela.'),
('Good Morning','Pernas','Posterior','Barra','Barra nas costas, incline o tronco à frente com coluna neutra.'),
('Elevação pélvica','Pernas','Glúteos','Barra','Costas no banco, eleve o quadril contraindo os glúteos.'),
('Glúteo máquina','Pernas','Glúteos','Máquina','Empurre a plataforma para trás com a perna estendendo o quadril.'),
('Coice no cabo','Pernas','Glúteos','Cabo','Tornozeleira na polia baixa, estenda a perna para trás.'),
('Abdução máquina','Pernas','Glúteos','Máquina','Sentado, afaste os joelhos contra a resistência.'),
('Panturrilha em pé','Pernas','Panturrilha','Máquina','Eleve os calcanhares ao máximo e desça alongando.'),
('Panturrilha sentado','Pernas','Panturrilha','Máquina','Sentado, eleve os calcanhares enfatizando o sóleo.'),
('Panturrilha Leg Press','Pernas','Panturrilha','Máquina','Na plataforma do leg press, empurre com a ponta dos pés.'),
('Abdominal reto','Abdômen','Abdômen','Peso corporal','Deitado, eleve o tronco contraindo o abdômen.'),
('Abdominal infra','Abdômen','Abdômen inferior','Peso corporal','Eleve o quadril trazendo os joelhos ao peito.'),
('Abdominal oblíquo','Abdômen','Oblíquos','Peso corporal','Eleve o tronco em rotação levando o cotovelo ao joelho oposto.'),
('Prancha','Abdômen','Core','Peso corporal','Apoio nos antebraços, mantenha o corpo alinhado e isométrico.'),
('Prancha lateral','Abdômen','Oblíquos','Peso corporal','Apoio lateral em um antebraço, quadril elevado e alinhado.'),
('Elevação de pernas','Abdômen','Abdômen inferior','Peso corporal','Pendurado ou deitado, eleve as pernas estendidas.'),
('Abdominal máquina','Abdômen','Abdômen','Máquina','Sentado, flexione o tronco contra a resistência.'),
('Crunch cabo','Abdômen','Abdômen','Cabo','Ajoelhado na polia alta, flexione o tronco puxando a corda.'),
('Caminhada','Cardio','Cardio','Esteira','Caminhada em ritmo constante, com ou sem inclinação.'),
('Corrida','Cardio','Cardio','Esteira','Corrida contínua ou intervalada em ritmo controlado.'),
('Escada','Cardio','Cardio','Máquina','Subida contínua no simulador de escada.'),
('Remo','Cardio','Cardio','Remo ergômetro','Puxada coordenada de pernas, tronco e braços.'),
('Pular corda','Cardio','Cardio','Corda','Saltos contínuos com corda em ritmo constante.')
)
INSERT INTO public.exercises (nome, categoria_id, grupo_muscular, equipamento, descricao, fonte, user_id, ativo)
SELECT lib.nome, c.id, lib.grupo, lib.equipamento, lib.descricao, 'sistema', NULL, true
FROM lib
JOIN public.exercise_categories c ON c.nome = lib.categoria
WHERE NOT EXISTS (
  SELECT 1 FROM public.exercises e WHERE lower(e.nome) = lower(lib.nome) AND e.user_id IS NULL
);

CREATE OR REPLACE FUNCTION public.seed_default_workout_templates(_user_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing integer;
  v_tpl uuid;
  v_created integer := 0;
  v_specs jsonb := '[
    {"nome":"Peito","objetivo":"Hipertrofia","descricao":"Modelo padrão de peito para iniciantes e intermediários.","exs":["Supino reto barra","Supino inclinado halteres","Crucifixo máquina","Crossover médio","Flexão de braço"]},
    {"nome":"Costas","objetivo":"Hipertrofia","descricao":"Modelo padrão de costas com puxadas e remadas.","exs":["Puxada frontal","Remada curvada barra","Remada baixa","Remada unilateral halter","Pullover"]},
    {"nome":"Perna","objetivo":"Hipertrofia","descricao":"Modelo padrão de pernas cobrindo quadríceps, posterior e panturrilha.","exs":["Agachamento livre","Leg Press 45°","Cadeira extensora","Mesa flexora","Panturrilha em pé"]}
  ]'::jsonb;
  v_spec jsonb;
  v_ex text;
  v_ex_id uuid;
  v_ordem integer;
BEGIN
  SELECT count(*) INTO v_existing FROM public.workout_templates WHERE user_id = _user_id;
  IF v_existing > 0 THEN RETURN 0; END IF;

  FOR v_spec IN SELECT * FROM jsonb_array_elements(v_specs) LOOP
    INSERT INTO public.workout_templates (user_id, nome, descricao, objetivo, ativo)
    VALUES (_user_id, v_spec->>'nome', v_spec->>'descricao', v_spec->>'objetivo', true)
    RETURNING id INTO v_tpl;
    v_created := v_created + 1;
    v_ordem := 0;
    FOR v_ex IN SELECT jsonb_array_elements_text(v_spec->'exs') LOOP
      SELECT id INTO v_ex_id FROM public.exercises
        WHERE nome = v_ex AND user_id IS NULL AND ativo = true
        ORDER BY created_at LIMIT 1;
      IF v_ex_id IS NOT NULL THEN
        INSERT INTO public.template_exercises (template_id, exercise_id, ordem, series, repeticoes, descanso_segundos)
        VALUES (v_tpl, v_ex_id, v_ordem, 4, '10', 60);
        v_ordem := v_ordem + 1;
      END IF;
    END LOOP;
  END LOOP;

  RETURN v_created;
END;
$$;
REVOKE ALL ON FUNCTION public.seed_default_workout_templates(uuid) FROM PUBLIC, anon;

CREATE OR REPLACE FUNCTION public.seed_my_default_workout_templates()
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.seed_default_workout_templates(auth.uid());
$$;
REVOKE ALL ON FUNCTION public.seed_my_default_workout_templates() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.seed_my_default_workout_templates() TO authenticated;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.profiles (id, nome) VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'nome', split_part(NEW.email, '@', 1)));
  INSERT INTO public.nutrition_goals (user_id) VALUES (NEW.id);
  PERFORM public.seed_default_workout_templates(NEW.id);
  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.update_updated_at_column() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();