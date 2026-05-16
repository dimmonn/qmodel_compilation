SELECT
    i.id AS issue_id,
    i.created_at,
    i.closed_at,
    TIMESTAMPDIFF(MINUTE, i.created_at, i.closed_at) AS issue_resolution_time,
    pil.labels
FROM
    project_issue i
        JOIN
    project_issue_labels pil ON i.id = pil.project_issue_id;
