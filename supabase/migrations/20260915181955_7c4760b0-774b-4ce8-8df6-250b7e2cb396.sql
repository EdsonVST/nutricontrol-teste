CREATE TYPE public.goal_type AS ENUM ('emagrecimento', 'manutencao', 'ganho_massa');
CREATE TYPE public.meal_type AS ENUM ('cafe_da_manha', 'almoco', 'lanche', 'jantar', 'outro');

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT,
  peso NUMERIC(5,2),
  altura NUMERIC(5,2),
  idade INTEGER,
  objetivo public.goal_type DEFAULT 'manutencao',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own profile select" ON public.profiles FOR SELECT TO authenticated USING (auth.uid() = id);
CREATE POLICY "own profile insert" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "own profile update" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.nutrition_goals (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  calorias NUMERIC(7,2) NOT NULL DEFAULT 2000,
  proteinas NUMERIC(6,2) NOT NULL DEFAULT 120,
  carboidratos NUMERIC(6,2) NOT NULL DEFAULT 250,
  gorduras NUMERIC(6,2) NOT NULL DEFAULT 65,
  fibras NUMERIC(6,2) NOT NULL DEFAULT 25,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.nutrition_goals TO authenticated;
GRANT ALL ON public.nutrition_goals TO service_role;
ALTER TABLE public.nutrition_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own goals all" ON public.nutrition_goals FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER nutrition_goals_updated_at BEFORE UPDATE ON public.nutrition_goals FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  categoria TEXT,
  unidade_base TEXT NOT NULL DEFAULT 'g',
  energia_kcal NUMERIC(7,2) NOT NULL DEFAULT 0,
  proteina NUMERIC(7,2) NOT NULL DEFAULT 0,
  carboidrato NUMERIC(7,2) NOT NULL DEFAULT 0,
  gordura NUMERIC(7,2) NOT NULL DEFAULT 0,
  fibra NUMERIC(7,2) NOT NULL DEFAULT 0,
  sodio NUMERIC(7,2) NOT NULL DEFAULT 0,
  minerais JSONB DEFAULT '{}'::jsonb,
  vitaminas JSONB DEFAULT '{}'::jsonb,
  fonte TEXT NOT NULL DEFAULT 'taco',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX foods_nome_idx ON public.foods USING gin (to_tsvector('portuguese', nome));
CREATE INDEX foods_nome_trgm_idx ON public.foods (lower(nome));
CREATE INDEX foods_user_idx ON public.foods (user_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.foods TO authenticated;
GRANT ALL ON public.foods TO service_role;
ALTER TABLE public.foods ENABLE ROW LEVEL SECURITY;
CREATE POLICY "foods read" ON public.foods FOR SELECT TO authenticated USING (user_id IS NULL OR user_id = auth.uid());
CREATE POLICY "foods insert own" ON public.foods FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "foods update own" ON public.foods FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "foods delete own" ON public.foods FOR DELETE TO authenticated USING (user_id = auth.uid());
CREATE TRIGGER foods_updated_at BEFORE UPDATE ON public.foods FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.meals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL DEFAULT CURRENT_DATE,
  horario TIME,
  tipo public.meal_type NOT NULL,
  observacao TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX meals_user_data_idx ON public.meals (user_id, data);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.meals TO authenticated;
GRANT ALL ON public.meals TO service_role;
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "meals own all" ON public.meals FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER meals_updated_at BEFORE UPDATE ON public.meals FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.meal_foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meal_id UUID NOT NULL REFERENCES public.meals(id) ON DELETE CASCADE,
  food_id UUID NOT NULL REFERENCES public.foods(id) ON DELETE RESTRICT,
  quantidade NUMERIC(8,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX meal_foods_meal_idx ON public.meal_foods (meal_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.meal_foods TO authenticated;
GRANT ALL ON public.meal_foods TO service_role;
ALTER TABLE public.meal_foods ENABLE ROW LEVEL SECURITY;
CREATE POLICY "meal_foods read own" ON public.meal_foods FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.meals m WHERE m.id = meal_id AND m.user_id = auth.uid()));
CREATE POLICY "meal_foods insert own" ON public.meal_foods FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.meals m WHERE m.id = meal_id AND m.user_id = auth.uid()));
CREATE POLICY "meal_foods update own" ON public.meal_foods FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.meals m WHERE m.id = meal_id AND m.user_id = auth.uid()));
CREATE POLICY "meal_foods delete own" ON public.meal_foods FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.meals m WHERE m.id = meal_id AND m.user_id = auth.uid()));

ALTER TABLE public.foods
  ADD COLUMN IF NOT EXISTS vit_a numeric,
  ADD COLUMN IF NOT EXISTS vit_b1 numeric,
  ADD COLUMN IF NOT EXISTS vit_b2 numeric,
  ADD COLUMN IF NOT EXISTS vit_b3 numeric,
  ADD COLUMN IF NOT EXISTS vit_b5 numeric,
  ADD COLUMN IF NOT EXISTS vit_b6 numeric,
  ADD COLUMN IF NOT EXISTS vit_b7 numeric,
  ADD COLUMN IF NOT EXISTS vit_b9 numeric,
  ADD COLUMN IF NOT EXISTS vit_b12 numeric,
  ADD COLUMN IF NOT EXISTS vit_c numeric,
  ADD COLUMN IF NOT EXISTS vit_d numeric,
  ADD COLUMN IF NOT EXISTS vit_e numeric,
  ADD COLUMN IF NOT EXISTS vit_k numeric,
  ADD COLUMN IF NOT EXISTS calcio numeric,
  ADD COLUMN IF NOT EXISTS ferro numeric,
  ADD COLUMN IF NOT EXISTS magnesio numeric,
  ADD COLUMN IF NOT EXISTS fosforo numeric,
  ADD COLUMN IF NOT EXISTS potassio numeric,
  ADD COLUMN IF NOT EXISTS zinco numeric,
  ADD COLUMN IF NOT EXISTS selenio numeric;

CREATE TABLE IF NOT EXISTS public.exercise_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL UNIQUE,
  descricao text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.exercise_categories TO authenticated;
GRANT ALL ON public.exercise_categories TO service_role;
ALTER TABLE public.exercise_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories readable by authenticated"
  ON public.exercise_categories FOR SELECT TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS public.exercises (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  categoria_id uuid REFERENCES public.exercise_categories(id) ON DELETE SET NULL,
  grupo_muscular text,
  descricao text,
  equipamento text,
  ativo boolean NOT NULL DEFAULT true,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  fonte text NOT NULL DEFAULT 'sistema',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.exercises TO authenticated;
GRANT ALL ON public.exercises TO service_role;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Exercises visible to authenticated" ON public.exercises
  FOR SELECT TO authenticated USING (user_id IS NULL OR user_id = auth.uid());
CREATE POLICY "Users insert own exercises" ON public.exercises
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "Authenticated can update exercises" ON public.exercises FOR UPDATE TO authenticated
  USING (true) WITH CHECK (true);
CREATE POLICY "Users can delete own exercises" ON public.exercises FOR DELETE TO authenticated
  USING (user_id = auth.uid());
CREATE TRIGGER update_exercises_updated_at BEFORE UPDATE ON public.exercises
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE IF NOT EXISTS public.workouts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data date NOT NULL DEFAULT CURRENT_DATE,
  horario time,
  duracao_min integer,
  observacoes text,
  finalizado_em timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workouts TO authenticated;
GRANT ALL ON public.workouts TO service_role;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own workouts" ON public.workouts
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE TRIGGER update_workouts_updated_at BEFORE UPDATE ON public.workouts
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE IF NOT EXISTS public.workout_exercises (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_id uuid NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
  exercise_id uuid NOT NULL REFERENCES public.exercises(id) ON DELETE RESTRICT,
  peso numeric,
  series integer,
  repeticoes integer,
  observacoes text,
  ordem integer NOT NULL DEFAULT 0,
  concluido boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_exercises TO authenticated;
GRANT ALL ON public.workout_exercises TO service_role;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own workout exercises" ON public.workout_exercises
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.workouts w WHERE w.id = workout_id AND w.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.workouts w WHERE w.id = workout_id AND w.user_id = auth.uid()));

CREATE TABLE public.workout_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  descricao TEXT,
  objetivo TEXT,
  ativo BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_templates TO authenticated;
GRANT ALL ON public.workout_templates TO service_role;
ALTER TABLE public.workout_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own templates" ON public.workout_templates FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER trg_workout_templates_updated BEFORE UPDATE ON public.workout_templates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.template_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES public.workout_templates(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  ordem INT NOT NULL DEFAULT 0,
  series INT NOT NULL DEFAULT 3,
  repeticoes TEXT NOT NULL DEFAULT '10',
  descanso_segundos INT NOT NULL DEFAULT 60,
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.template_exercises TO authenticated;
GRANT ALL ON public.template_exercises TO service_role;
ALTER TABLE public.template_exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own template exercises" ON public.template_exercises FOR ALL
  USING (EXISTS (SELECT 1 FROM public.workout_templates t WHERE t.id = template_id AND t.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.workout_templates t WHERE t.id = template_id AND t.user_id = auth.uid()));

CREATE TABLE public.weekly_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.weekly_plans TO authenticated;
GRANT ALL ON public.weekly_plans TO service_role;
ALTER TABLE public.weekly_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own plans" ON public.weekly_plans FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER trg_weekly_plans_updated BEFORE UPDATE ON public.weekly_plans FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.weekly_plan_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES public.weekly_plans(id) ON DELETE CASCADE,
  dia_semana INT NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
  template_id UUID REFERENCES public.workout_templates(id) ON DELETE SET NULL,
  rotulo TEXT,
  UNIQUE(plan_id, dia_semana)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.weekly_plan_days TO authenticated;
GRANT ALL ON public.weekly_plan_days TO service_role;
ALTER TABLE public.weekly_plan_days ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own plan days" ON public.weekly_plan_days FOR ALL
  USING (EXISTS (SELECT 1 FROM public.weekly_plans p WHERE p.id = plan_id AND p.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.weekly_plans p WHERE p.id = plan_id AND p.user_id = auth.uid()));

CREATE TABLE public.water_goals (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  meta_ml INT NOT NULL DEFAULT 3000,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.water_goals TO authenticated;
GRANT ALL ON public.water_goals TO service_role;
ALTER TABLE public.water_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own water goal" ON public.water_goals FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER trg_water_goals_updated BEFORE UPDATE ON public.water_goals FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.water_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL DEFAULT CURRENT_DATE,
  quantidade_ml INT NOT NULL CHECK (quantidade_ml > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_water_logs_user_date ON public.water_logs(user_id, data);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.water_logs TO authenticated;
GRANT ALL ON public.water_logs TO service_role;
ALTER TABLE public.water_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own water logs" ON public.water_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.water_reminders (
  user_id uuid PRIMARY KEY,
  ativo boolean NOT NULL DEFAULT true,
  horarios text[] NOT NULL DEFAULT ARRAY['08:00','10:00','12:00','14:00','16:00','18:00','20:00'],
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.water_reminders TO authenticated;
GRANT ALL ON public.water_reminders TO service_role;
ALTER TABLE public.water_reminders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own water reminders" ON public.water_reminders
  FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER update_water_reminders_updated_at
  BEFORE UPDATE ON public.water_reminders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.progress_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL DEFAULT CURRENT_DATE,
  categoria TEXT NOT NULL CHECK (categoria IN ('frente','lado','costas')),
  storage_path TEXT NOT NULL,
  peso_kg NUMERIC(5,2),
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_progress_photos_user_date ON public.progress_photos(user_id, data DESC);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.progress_photos TO authenticated;
GRANT ALL ON public.progress_photos TO service_role;
ALTER TABLE public.progress_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own progress photos" ON public.progress_photos FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS peso_meta numeric;
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS ativo boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS bloqueado_em timestamptz,
  ADD COLUMN IF NOT EXISTS desativado_em timestamptz;

CREATE POLICY "users read own progress photos" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'progress-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "users upload own progress photos" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'progress-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "users update own progress photos" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'progress-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "users delete own progress photos" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'progress-photos' AND (storage.foldername(name))[1] = auth.uid()::text);