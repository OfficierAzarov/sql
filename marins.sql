-- On souhaite trouver tous les marins >= 16 ans, aptes, avec dates valides et les 4 modules.

-- Requête initiale :

SELECT DISTINCT aah.ID_ADM_ADMINISTRE
FROM ADM_ADMINISTRE_HISTORIQUE aah
JOIN ESC_EPISODE_SANTE ees
    ON aah.ID_ADM_ADMINISTRE = ees.ID_ADM_ADMINISTRE
JOIN ESC_APTITUDE ea
    ON ees.ID_ESC_EPISODE_SANTE = ea.ID_ESC_EPISODE_SANTE
JOIN (
    SELECT amf_c.ID_ADM_ADMINISTRE
    FROM AMF_CANDIDAT amf_c
    JOIN AMF_ACQUISITION amf_a
        ON amf_c.ID_AMF_CANDIDAT = amf_a.ID_AMF_CANDIDAT
    WHERE amf_c.ID_AMF_CANDIDAT IN (
        SELECT amf_a2.ID_AMF_CANDIDAT
        FROM AMF_ACQUISITION amf_a2
        WHERE amf_a2.ID_AMF_MODULE_UV IN ('500014', '500015', '500016', '500016')
        GROUP BY amf_a2.ID_AMF_CANDIDAT
        HAVING COUNT(DISTINCT amf_a2.ID_AMF_MODULE_UV) = 4
    )
) candidates
    ON ees.ID_ADM_ADMINISTRE = candidates.ID_ADM_ADMINISTRE
WHERE aah.DATE_NAISSANCE <= {{age_date}}
  AND ea.DATE_FIN_VALIDITE >= {{aptitude_date}}
  AND ea.IDC_DECISION_MEDICALE = 1
ORDER BY aah.ID_ADM_ADMINISTRE;

-- Procédure stockée :

CREATE OR REPLACE FUNCTION get_eligible_marins(age_date DATE, aptitude_date DATE)
RETURNS TABLE (id_adm_administre INT) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT aah.id_adm_administre
    FROM adm_administre_historique aah
    JOIN esc_episode_sante ees
        ON aah.id_adm_administre = ees.id_adm_administre
    JOIN esc_aptitude ea
        ON ees.id_esc_episode_sante = ea.id_esc_episode_sante
    JOIN (
        SELECT amf_c.id_adm_administre
        FROM amf_candidat amf_c
        JOIN amf_acquisition amf_a
            ON amf_c.id_amf_candidat = amf_a.id_amf_candidat
        WHERE amf_c.id_amf_candidat IN (
            SELECT amf_a2.id_amf_candidat
            FROM amf_acquisition amf_a2
            WHERE amf_a2.id_amf_module_uv IN ('500014', '500015', '500016', '500016')
            GROUP BY amf_a2.id_amf_candidat
            HAVING COUNT(DISTINCT amf_a2.id_amf_module_uv) = 4
        )
    ) candidates
        ON ees.id_adm_administre = candidates.id_adm_administre
    WHERE aah.date_naissance <= age_date
      AND ea.date_fin_validite >= aptitude_date
      AND ea.idc_decision_medicale = 1
    ORDER BY aah.id_adm_administre;
END;
$$ LANGUAGE plpgsql;

-- Exécution de la procédure stockée :
SELECT * FROM get_eligible_marins('2008-07-25', '2024-07-25');

