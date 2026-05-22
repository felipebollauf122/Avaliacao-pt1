CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE user_role AS ENUM ('aluno', 'admin_escolar', 'admin_global');
CREATE TYPE session_status AS ENUM ('em_andamento', 'concluida');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'aluno',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT fk_user_profiles_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    cnpj VARCHAR(14) UNIQUE NOT NULL,
    admin_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT fk_schools_admin
        FOREIGN KEY (admin_id) REFERENCES user_profiles(id) ON DELETE RESTRICT,
    CONSTRAINT chk_admin_is_school_admin
        CHECK (EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = admin_id AND role = 'admin_escolar'
        ))
);

CREATE TABLE enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL,
    school_id UUID NOT NULL,
    enrollment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (student_id) REFERENCES user_profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_enrollments_school
        FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    CONSTRAINT uq_student_school
        UNIQUE (student_id, school_id)
);

CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_number INT NOT NULL UNIQUE,
    statement JSONB NOT NULL,
    alternatives JSONB NOT NULL,
    correct_answer INT NOT NULL CHECK (correct_answer >= 1 AND correct_answer <= 5),
    subject VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE exam_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMP WITH TIME ZONE,
    status session_status NOT NULL DEFAULT 'em_andamento',
    total_questions INT NOT NULL DEFAULT 0,
    correct_answers INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT fk_exam_sessions_student
        FOREIGN KEY (student_id) REFERENCES user_profiles(id) ON DELETE CASCADE,
    CONSTRAINT chk_finished_after_started
        CHECK (finished_at IS NULL OR finished_at >= started_at),
    CONSTRAINT chk_session_status
        CHECK (status IN ('em_andamento', 'concluida')),
    CONSTRAINT chk_correct_not_exceed_total
        CHECK (correct_answers <= total_questions)
);

CREATE TABLE answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL,
    question_id UUID NOT NULL,
    chosen_alternative INT NOT NULL CHECK (chosen_alternative >= 1 AND chosen_alternative <= 5),
    is_correct BOOLEAN NOT NULL,
    answered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_answers_session
        FOREIGN KEY (session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_answers_question
        FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    CONSTRAINT uq_session_question
        UNIQUE (session_id, question_id)
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_profiles_role ON user_profiles(role);
CREATE INDEX idx_schools_admin_id ON schools(admin_id);
CREATE INDEX idx_schools_cnpj ON schools(cnpj);
CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_enrollments_school_id ON enrollments(school_id);
CREATE INDEX idx_questions_subject ON questions(subject);
CREATE INDEX idx_exam_sessions_student_id ON exam_sessions(student_id);
CREATE INDEX idx_exam_sessions_status ON exam_sessions(status);
CREATE INDEX idx_answers_session_id ON answers(session_id);
CREATE INDEX idx_answers_question_id ON answers(question_id);
