CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_profiles (user_id, full_name, role, created_at, updated_at)
    VALUES (
        NEW.id,
        'Usuário ' || NEW.id::TEXT,
        'aluno'::user_role,
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_user_profile
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION create_user_profile();

CREATE OR REPLACE FUNCTION update_user_profile_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_profile_timestamp
BEFORE UPDATE ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION update_user_profile_timestamp();

CREATE OR REPLACE FUNCTION update_school_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_school_timestamp
BEFORE UPDATE ON schools
FOR EACH ROW
EXECUTE FUNCTION update_school_timestamp();

CREATE OR REPLACE FUNCTION update_question_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_question_timestamp
BEFORE UPDATE ON questions
FOR EACH ROW
EXECUTE FUNCTION update_question_timestamp();

CREATE OR REPLACE FUNCTION update_exam_session_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_exam_session_timestamp
BEFORE UPDATE ON exam_sessions
FOR EACH ROW
EXECUTE FUNCTION update_exam_session_timestamp();

CREATE OR REPLACE FUNCTION update_session_stats_on_answer_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE exam_sessions
    SET
        total_questions = total_questions + 1,
        correct_answers = correct_answers + (CASE WHEN NEW.is_correct THEN 1 ELSE 0 END),
        updated_at = NOW()
    WHERE id = NEW.session_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_session_stats_on_answer_insert
AFTER INSERT ON answers
FOR EACH ROW
EXECUTE FUNCTION update_session_stats_on_answer_insert();

CREATE OR REPLACE FUNCTION update_session_stats_on_answer_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.is_correct != NEW.is_correct THEN
        UPDATE exam_sessions
        SET
            correct_answers = correct_answers + (CASE
                WHEN NEW.is_correct THEN 1
                ELSE -1
            END),
            updated_at = NOW()
        WHERE id = NEW.session_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_session_stats_on_answer_update
AFTER UPDATE ON answers
FOR EACH ROW
EXECUTE FUNCTION update_session_stats_on_answer_update();

CREATE OR REPLACE FUNCTION update_session_stats_on_answer_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE exam_sessions
    SET
        total_questions = total_questions - 1,
        correct_answers = correct_answers - (CASE WHEN OLD.is_correct THEN 1 ELSE 0 END),
        updated_at = NOW()
    WHERE id = OLD.session_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_session_stats_on_answer_delete
AFTER DELETE ON answers
FOR EACH ROW
EXECUTE FUNCTION update_session_stats_on_answer_delete();
