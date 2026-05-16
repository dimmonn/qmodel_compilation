SELECT
    pr.id AS pull_request_id,
    pr.created_at,
    pr.merged_at,
    TIMESTAMPDIFF(MINUTE, pr.created_at, pr.merged_at) AS pr_resolution_time,
    prl.labels
FROM
    project_pull pr
        JOIN
    project_pull_labels prl
    ON pr.id = prl.project_pull_id