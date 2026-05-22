ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS user_role AS $$
DECLARE
    current_role user_role;
BEGIN
    SELECT role INTO current_role
    FROM user_profiles
    WHERE user_id = auth.uid();

    RETURN COALESCE(current_role, 'aluno'::user_role);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_admin_global()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT role = 'admin_global' FROM user_profiles WHERE user_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_current_profile_id()
RETURNS UUID AS $$
BEGIN
    RETURN (SELECT id FROM user_profiles WHERE user_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_admin_school_id()
RETURNS UUID AS $$
BEGIN
    RETURN (SELECT id FROM schools WHERE admin_id = get_current_profile_id());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE POLICY aluno_view_own_profile ON user_profiles
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR get_current_user_role() = 'admin_global'::user_role
    );

CREATE POLICY aluno_update_own_profile ON user_profiles
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY admin_global_update_all_profiles ON user_profiles
    FOR UPDATE
    USING (get_current_user_role() = 'admin_global'::user_role)
    WITH CHECK (get_current_user_role() = 'admin_global'::user_role);

CREATE POLICY admin_escolar_view_own_school ON schools
    FOR SELECT
    USING (
        admin_id = get_current_profile_id()
        OR get_current_user_role() = 'admin_global'::user_role
    );

CREATE POLICY admin_escolar_update_own_school ON schools
    FOR UPDATE
    USING (admin_id = get_current_profile_id())
    WITH CHECK (admin_id = get_current_profile_id());

CREATE POLICY admin_global_update_all_schools ON schools
    FOR UPDATE
    USING (get_current_user_role() = 'admin_global'::user_role)
    WITH CHECK (get_current_user_role() = 'admin_global'::user_role);

CREATE POLICY aluno_view_own_enrollments ON enrollments
    FOR SELECT
    USING (
        student_id = get_current_profile_id()
        OR (get_current_user_role() = 'admin_escolar'::user_role
            AND school_id = get_admin_school_id())
        OR get_current_user_role() = 'admin_global'::user_role
    );

CREATE POLICY admin_escolar_manage_enrollments ON enrollments
    FOR ALL
    USING (
        (get_current_user_role() = 'admin_escolar'::user_role
         AND school_id = get_admin_school_id())
        OR get_current_user_role() = 'admin_global'::user_role
    )
    WITH CHECK (
        (get_current_user_role() = 'admin_escolar'::user_role
         AND school_id = get_admin_school_id())
        OR get_current_user_role() = 'admin_global'::user_role
    );

CREATE POLICY authenticated_read_questions ON questions
    FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY admin_global_manage_questions ON questions
    FOR ALL
    USING (get_current_user_role() = 'admin_global'::user_role)
    WITH CHECK (get_current_user_role() = 'admin_global'::user_role);

CREATE POLICY aluno_view_own_sessions ON exam_sessions
    FOR SELECT
    USING (
        student_id = get_current_profile_id()
        OR (get_current_user_role() = 'admin_escolar'::user_role
            AND EXISTS (
                SELECT 1 FROM enrollments
                WHERE student_id = exam_sessions.student_id
                AND school_id = get_admin_school_id()
            ))
        OR get_current_user_role() = 'admin_global'::user_role
    );

CREATE POLICY aluno_manage_own_sessions ON exam_sessions
    FOR ALL
    USING (
        (student_id = get_current_profile_id())
        OR get_current_user_role() = 'admin_global'::user_role
    )
    WITH CHECK (
        (student_id = get_current_profile_id())
        OR get_current_user_role() = 'admin_global'::user_role
    );

CREATE POLICY admin_escolar_audit_sessions ON exam_sessions
    FOR SELECT
    USING (
        get_current_user_role() = 'admin_escolar'::user_role
        AND EXISTS (
            SELECT 1 FROM enrollments
            WHERE student_id = exam_sessions.student_id
            AND school_id = get_admin_school_id()
        )
    );

CREATE POLICY aluno_view_own_answers ON answers
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM exam_sessions
            WHERE exam_sessions.id = answers.session_id
            AND exam_sessions.student_id = get_current_profile_id()
        )
        OR (get_current_user_role() = 'admin_escolar'::user_role
            AND EXISTS (
                SELECT 1 FROM exam_sessions
                INNER JOIN enrollments ON exam_sessions.student_id = enrollments.student_id
                WHERE exam_sessions.id = answers.session_id
                AND enrollments.school_id = get_admin_school_id()
            ))
        OR get_current_user_role() = 'admin_global'::user_role
    );

CREATE POLICY aluno_manage_own_answers ON answers
    FOR ALL
    USING (
        (EXISTS (
            SELECT 1 FROM exam_sessions
            WHERE exam_sessions.id = answers.session_id
            AND exam_sessions.student_id = get_current_profile_id()
        ))
        OR get_current_user_role() = 'admin_global'::user_role
    )
    WITH CHECK (
        (EXISTS (
            SELECT 1 FROM exam_sessions
            WHERE exam_sessions.id = answers.session_id
            AND exam_sessions.student_id = get_current_profile_id()
        ))
        OR get_current_user_role() = 'admin_global'::user_role
    );

CREATE POLICY admin_escolar_audit_answers ON answers
    FOR SELECT
    USING (
        get_current_user_role() = 'admin_escolar'::user_role
        AND EXISTS (
            SELECT 1 FROM exam_sessions
            INNER JOIN enrollments ON exam_sessions.student_id = enrollments.student_id
            WHERE exam_sessions.id = answers.session_id
            AND enrollments.school_id = get_admin_school_id()
        )
    );
